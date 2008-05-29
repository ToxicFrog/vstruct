-- floating point module
-- Copyright © 2008 Peter "Corsix" Cawley; see COPYING

local fp = {}

local function reader(uint, size_exp, size_fraction)
	local mask, fraction, exponent, sign

	-- Split the unsigned integer into the 3 IEEE fields
	mask = 2 ^ size_fraction
	fraction = uint % mask
	uint = math.floor(uint / mask)
	mask = 2 ^ size_exp
	exponent = uint % mask
	uint = math.floor(uint / mask)
	sign = uint

	-- when fraction and exponent == 0, then this bit can be skipped
	if fraction ~= 0 or exponent ~= 0 then
		-- Add the most significant bit back onto the fraction
		fraction = fraction + (2 ^ size_fraction)
		-- Decrease the size of the exponent rather than make the fraction (0.5, 1]
		exponent = exponent - size_fraction
	end

	-- remove the exponent bias
	exponent = exponent - 2 ^ (size_exp - 1) + 1

	return (sign == 0 and 1 or -1) * math.ldexp(fraction, exponent)
end

local function writer(value, size_exp, size_fraction)
	local fraction, exponent, sign
	fraction, exponent = math.frexp(value)

	-- handle the simple case
	if fraction == 0 then
		return 0
	end

	-- ensure a positive fraction
	if fraction < 0 then
		fraction = -fraction
		sign = 1
	else
		sign = 0
	end

	-- remove the most significant bit from the fraction and adjust exponent
	fraction = fraction - 0.5
	exponent = exponent - 1

	-- convert fraction into a binary integer  
	local frac_uint, frac_mask, frac_part = 0, 2 ^ (size_fraction - 1), 0.25
	for bit = 1, size_fraction do
		if fraction >= frac_part then
			frac_uint = frac_uint + frac_mask
			fraction = fraction - frac_part
		end
		frac_mask = frac_mask * 0.5
		frac_part = frac_part * 0.5
	end

	-- add the exponent bias
	exponent = exponent + 2 ^ (size_exp - 1) - 1

	return frac_uint + math.ldexp(exponent, size_fraction) + math.ldexp(sign, size_exp + size_fraction)
end

-- Create readers and writers for the IEEE sizes
fp.sizes = {
	[4] = {1,  8, 23},
	[8] = {1, 11, 52},
}

fp.r = {}
fp.w = {}
for width, sizes in pairs(fp.sizes) do
	fp.r[width] = function(uint) return reader(uint, sizes[2], sizes[3]) end
	fp.w[width] = function(valu) return writer(valu, sizes[2], sizes[3]) end
end

return fp
