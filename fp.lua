-- floating point module
-- Copyright © 2008 Peter "Corsix" Cawley; see COPYING
-- modified by Ben "ToxicFrog" Kelly

local fp = {}
local name = (...):gsub('%.[^%.]+$', '')
local struct = require (name)
local common = require (name..".common")

local function reader(data, size_exp, size_fraction)
	local fraction, exponent, sign
	local endian = common.is_bigendian and ">" or "<"
	
	-- Split the unsigned integer into the 3 IEEE fields
	local bits = struct.unpack(endian.."m"..#data, data)[1]
	local fraction = struct.implode{unpack(bits, 1, size_fraction)}
	local exponent = struct.implode{unpack(bits, size_fraction+1, size_fraction+size_exp)}
	local sign = bits[#bits] and -1 or 1

	-- special case: exponent is all 1s
	if exponent == 2^size_exp-1 then
		-- significand is 0? +- infinity
		if fraction == 0 then
			return sign * math.huge
		
		-- otherwise it's NaN
		else
			return 0/0
		end
	end
			
	-- restore the MSB of the significand
	if exponent ~= 0 then
		fraction = fraction + (2 ^ size_fraction)
	end
	
	-- remove the exponent bias
	exponent = exponent - 2 ^ (size_exp - 1) + 1

	-- Decrease the size of the exponent rather than make the fraction (0.5, 1]
	exponent = exponent - size_fraction

	return sign * math.ldexp(fraction, exponent)
end

local function writer(value, size_exp, size_fraction)
	local fraction, exponent, sign
	local width = (size_exp + size_fraction + 1)/8
	local endian = common.is_bigendian and ">" or "<"
	
	if value < 0 then
		sign = true
		value = -value
	else
		sign = false
	end

	-- special case: value is infinite
	if value == math.huge then
		exponent = 2^size_exp -1
		fraction = 0
	
	-- special case: value is NaN
	elseif value ~= value then
		exponent = 2^size_exp -1
		fraction = 2^(size_fraction-1)

	else
		fraction,exponent = math.frexp(value)
		-- handle the simple case
		if fraction == 0 then
			return struct.pack(endian.."m"..width, {{}})
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
		fraction = frac_uint
	end
	
	local bits = struct.explode(fraction)
	local bits_exp = struct.explode(exponent)
	for i=1,size_exp do
		bits[size_fraction+i] = bits_exp[i]
	end
	bits[size_fraction+size_exp+1] = sign

	return struct.pack(endian.."m"..width, {bits})
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
