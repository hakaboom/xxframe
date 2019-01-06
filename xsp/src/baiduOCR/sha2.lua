local print_debug_messages = false  -- set to true to view some messages about your system's abilities and implementation branch chosen for your system

local unpack, table_concat, byte, char, string_rep, sub, gsub, string_format, floor, ceil, tonumber =
   table.unpack or unpack, table.concat, string.byte, string.char, string.rep, string.sub, string.gsub, string.format, math.floor, math.ceil, tonumber

local function get_precision(one)
   -- "one" must be either float 1.0 or integer 1
   -- returns bits_precision, is_integer
   -- This function works correctly with all floating point datatypes (including non-IEEE-754)
   local k, n, m, prev_n = 0, one, one
   while true do
      k, prev_n, n, m = k + 1, n, n + n + 1, m + m + k % 2
      if k > 256 or n - (n - 1) ~= 1 or m - (m - 1) ~= 1 or n == m then
         return k, false   -- floating point datatype
      elseif n == prev_n then
         return k, true    -- integer datatype
      end
   end
end

-- Make sure Lua has "double" numbers
local x = 2/3
local Lua_has_double = x * 5 > 3 and x * 4 < 3 and get_precision(1.0) >= 53
assert(Lua_has_double, "at least 53-bit floating point numbers are required")

local int_prec, Lua_has_integers = get_precision(1)
local Lua_has_int64 = Lua_has_integers and int_prec == 64
local Lua_has_int32 = Lua_has_integers and int_prec == 32
assert(Lua_has_int64 or Lua_has_int32 or not Lua_has_integers, "Lua integers must be either 32-bit or 64-bit")

local is_LuaJIT = ({false, [1] = true})[1] and (type(jit) ~= "table" or jit.version_num >= 20000)  -- LuaJIT 1.x.x is treated as vanilla Lua 5.1
local is_LuaJIT_21  -- LuaJIT 2.1+
local LuaJIT_arch
local ffi           -- LuaJIT FFI library (as a table)
local b             -- 32-bit bitwise library (as a table)
local library_name

if is_LuaJIT then
   -- Assuming "bit" library is always available on LuaJIT
   b = require"bit"
   library_name = "bit"
   -- "ffi" is intentionally disabled on some systems for safety reason
   local LuaJIT_has_FFI, result = pcall(require, "ffi")
   if LuaJIT_has_FFI then
      ffi = result
   end
   is_LuaJIT_21 = not not loadstring"b=0b0"
   LuaJIT_arch = type(jit) == "table" and jit.arch or ffi and ffi.arch or nil
else
   -- For vanilla Lua, "bit"/"bit32" libraries are searched in global namespace only.  No attempt is made to load a library if it's not loaded yet.
   if type(bit) == "table" and bit.bxor then
      b = bit
      library_name = "bit"
   elseif type(bit32) == "table" and bit32.bxor then
      b = bit32
      library_name = "bit32"
   end
end

if print_debug_messages then
   -- Printing list of abilities of your system
   print("Abilities:")
   print("   Lua version:               "..(is_LuaJIT and "LuaJIT "..(is_LuaJIT_21 and "2.1 " or "2.0 ")..(LuaJIT_arch or "")..(ffi and " with FFI" or " without FFI") or _VERSION))
   print("   Integer bitwise operators: "..(Lua_has_int64 and "int64" or Lua_has_int32 and "int32" or "no"))
   print("   32-bit bitwise library:    "..(library_name or "not found"))
end

-- Selecting the most suitable implementation for given set of abilities
local method, branch
if is_LuaJIT and ffi then
   method = "Using 'ffi' library of LuaJIT"
   branch = "FFI"
elseif is_LuaJIT then
   method = "Using special code for FFI-less LuaJIT"
   branch = "LJ"
elseif Lua_has_int64 then
   method = "Using native int64 bitwise operators"
   branch = "INT64"
elseif Lua_has_int32 then
   method = "Using native int32 bitwise operators"
   branch = "INT32"
elseif library_name then   -- when bitwise library is available (Lua 5.2 with native library "bit32" or Lua 5.1 with external library "bit")
   method = "Using '"..library_name.."' library"
   branch = "LIB32"
else
   method = "Emulating bitwise operators using look-up table"
   branch = "EMUL"
end
if print_debug_messages then
   -- Printing the implementation selected to be used on your system
   print("Implementation selected:")
   print("   "..method)
end


local AND, OR, XOR, SHL, SHR, ROL, ROR, NOT, NORM, HEX, XOR_BYTE

if branch == "FFI" or branch == "LJ" or branch == "LIB32" then

   -- Your system has 32-bit bitwise library (either "bit" or "bit32")
   AND  = b.band                -- 2 arguments
   OR   = b.bor                 -- 2 arguments
   XOR  = b.bxor                -- 2..4 arguments
   SHL  = b.lshift              -- second argument is integer 0..31
   SHR  = b.rshift              -- second argument is integer 0..31
   ROL  = b.rol or b.lrotate    -- second argument is integer 0..31
   ROR  = b.ror or b.rrotate    -- second argument is integer 0..31
   NOT  = b.bnot                -- only for LuaJIT
   NORM = b.tobit               -- only for LuaJIT
   HEX  = b.tohex               -- returns string of 8 lowercase hexadecimal digits
   assert(AND and OR and XOR and SHL and SHR and ROL and ROR and NOT, "Library '"..library_name.."' is incomplete")
   XOR_BYTE = XOR               -- XOR of two bytes (only for HMAC), inputs and output are 0..255

elseif branch == "EMUL" then

   -- Emulating 32-bit bitwise operation using 53-bit floating point arithmetic.

   function SHL(x, n)
      return (x * 2^n) % 2^32
   end

   function SHR(x, n)
      x = x % 2^32 / 2^n
      return x - x % 1
   end

   function ROL(x, n)
      x = x % 2^32 * 2^n
      local r = x % 2^32
      return r + (x - r) / 2^32
   end

   function ROR(x, n)
      x = x % 2^32 / 2^n
      local r = x % 1
      return r * 2^32 + (x - r)
   end

   local AND_of_two_bytes = {[0] = 0}  -- look-up table (256*256 entries)
   local idx = 0
   for y = 0, 127 * 256, 256 do
      for x = y, y + 127 do
         x = AND_of_two_bytes[x] * 2
         AND_of_two_bytes[idx] = x
         AND_of_two_bytes[idx + 1] = x
         AND_of_two_bytes[idx + 256] = x
         AND_of_two_bytes[idx + 257] = x + 1
         idx = idx + 2
      end
      idx = idx + 256
   end

   local function and_or_xor(x, y, operation)
      -- operation: nil = AND, 1 = OR, 2 = XOR
      local x0 = x % 2^32
      local y0 = y % 2^32
      local rx = x0 % 256
      local ry = y0 % 256
      local res = AND_of_two_bytes[rx + ry * 256]
      x = x0 - rx
      y = (y0 - ry) / 256
      rx = x % 65536
      ry = y % 256
      res = res + AND_of_two_bytes[rx + ry] * 256
      x = (x - rx) / 256
      y = (y - ry) / 256
      rx = x % 65536 + y % 256
      res = res + AND_of_two_bytes[rx] * 65536
      res = res + AND_of_two_bytes[(x + y - rx) / 256] * 16777216
      if operation then
         res = x0 + y0 - operation * res
      end
      return res
   end

   function AND(x, y)
      return and_or_xor(x, y)
   end

   function OR(x, y)
      return and_or_xor(x, y, 1)
   end

   function XOR(x, y, z, t)          -- 2..4 arguments
      if z then
         if t then
            z = and_or_xor(z, t, 2)
         end
         y = and_or_xor(y, z, 2)
      end
      return and_or_xor(x, y, 2)
   end

   function XOR_BYTE(x, y)
      return x + y - 2 * AND_of_two_bytes[x + y * 256]
   end

end

HEX = HEX or
   function (x) -- returns string of 8 lowercase hexadecimal digits
      return string_format("%08x", x % 4294967296)
   end

local function XOR32A5(x)
   return XOR(x, 0xA5A5A5A5) % 4294967296
end



local sha256_feed_64, sha512_feed_128, md5_feed_64, sha1_feed_64


local sha2_K_lo, sha2_K_hi, sha2_H_lo, sha2_H_hi = {}, {}, {}, {}
local sha2_H_ext256 = {[224] = {}, [256] = sha2_H_hi}
local sha2_H_ext512_lo, sha2_H_ext512_hi = {[384] = {}, [512] = sha2_H_lo}, {[384] = {}, [512] = sha2_H_hi}
local md5_K, md5_sha1_H = {}, {0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0}
local md5_next_shift = {0, 0, 0, 0, 0, 0, 0, 0, 28, 25, 26, 27, 0, 0, 10, 9, 11, 12, 0, 15, 16, 17, 18, 0, 20, 22, 23, 21}

local HEX64, XOR64A5  
local common_W = {}  
local K_lo_modulo, hi_factor = 4294967296, 0

if branch == "INT64" then	--Lua 5.3/5.4

   -- implementation for Lua 5.3/5.4
   hi_factor = 4294967296
		local _init64_=function (md5_next_shift) 
		  local string_format, string_unpack = string.format, string.unpack
		  local function HEX64(x)
			 return string_format("%016x", x)
		  end
		  local function XOR64A5(x)
			 return x ~ 0xa5a5a5a5a5a5a5a5
		  end
		  local function XOR_BYTE(x, y)
			 return x ~ y
		  end
		  local common_W = {}
		  local function sha256_feed_64(H, K, str, offs, size)
			 -- offs >= 0, size >= 0, size is multiple of 64
			 local W = common_W
			 local h1, h2, h3, h4, h5, h6, h7, h8 = H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]
			 for pos = offs + 1, offs + size, 64 do
				W[1], W[2], W[3], W[4], W[5], W[6], W[7], W[8], W[9], W[10], W[11], W[12], W[13], W[14], W[15], W[16] =
				   string_unpack(">I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4", str, pos)
				for j = 17, 64 do
				   local a = W[j-15]
				   a = a<<32 | a
				   local b = W[j-2]
				   b = b<<32 | b
				   W[j] = (a>>7 ~ a>>18 ~ a>>35) + (b>>17 ~ b>>19 ~ b>>42) + W[j-7] + W[j-16] & (1<<32)-1
				end
				local a, b, c, d, e, f, g, h = h1, h2, h3, h4, h5, h6, h7, h8
				for j = 1, 64 do
				   e = e<<32 | e & (1<<32)-1
				   local z = (e>>6 ~ e>>11 ~ e>>25) + (g ~ e & (f ~ g)) + h + K[j] + W[j]
				   h = g
				   g = f
				   f = e
				   e = z + d
				   d = c
				   c = b
				   b = a
				   a = a<<32 | a & (1<<32)-1
				   a = z + ((a ~ c) & d ~ a & c) + (a>>2 ~ a>>13 ~ a>>22)
				end
				h1 = a + h1
				h2 = b + h2
				h3 = c + h3
				h4 = d + h4
				h5 = e + h5
				h6 = f + h6
				h7 = g + h7
				h8 = h + h8
			 end
			 H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8] = h1, h2, h3, h4, h5, h6, h7, h8
		  end
		  local function sha512_feed_128(H, _, K, _, str, offs, size)
			 -- offs >= 0, size >= 0, size is multiple of 128
			 local W = common_W
			 local h1, h2, h3, h4, h5, h6, h7, h8 = H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]
			 for pos = offs + 1, offs + size, 128 do
				W[1], W[2], W[3], W[4], W[5], W[6], W[7], W[8], W[9], W[10], W[11], W[12], W[13], W[14], W[15], W[16] =
				   string_unpack(">i8i8i8i8i8i8i8i8i8i8i8i8i8i8i8i8", str, pos)
				for j = 17, 80 do
				   local a = W[j-15]
				   local b = W[j-2]
				   W[j] = (a >> 1 ~ a >> 7 ~ a >> 8 ~ a << 56 ~ a << 63) + (b >> 6 ~ b >> 19 ~ b >> 61 ~ b << 3 ~ b << 45) + W[j-7] + W[j-16]
				end
				local a, b, c, d, e, f, g, h = h1, h2, h3, h4, h5, h6, h7, h8
				for j = 1, 80 do
				   local z = (e >> 14 ~ e >> 18 ~ e >> 41 ~ e << 23 ~ e << 46 ~ e << 50) + (g ~ e & (f ~ g)) + h + K[j] + W[j]
				   h = g
				   g = f
				   f = e
				   e = z + d
				   d = c
				   c = b
				   b = a
				   a = z + ((a ~ c) & d ~ a & c) + (a >> 28 ~ a >> 34 ~ a >> 39 ~ a << 25 ~ a << 30 ~ a << 36)
				end
				h1 = a + h1
				h2 = b + h2
				h3 = c + h3
				h4 = d + h4
				h5 = e + h5
				h6 = f + h6
				h7 = g + h7
				h8 = h + h8
			 end
			 H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8] = h1, h2, h3, h4, h5, h6, h7, h8
		  end
		  local function md5_feed_64(H, K, str, offs, size)
			 -- offs >= 0, size >= 0, size is multiple of 64
			 local W, md5_next_shift = common_W, md5_next_shift
			 local h1, h2, h3, h4 = H[1], H[2], H[3], H[4]
			 for pos = offs + 1, offs + size, 64 do
				W[1], W[2], W[3], W[4], W[5], W[6], W[7], W[8], W[9], W[10], W[11], W[12], W[13], W[14], W[15], W[16] =
				   string_unpack("<I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4", str, pos)
				local a, b, c, d = h1, h2, h3, h4
				local s = 32-7
				for j = 1, 16 do
				   local F = (d ~ b & (c ~ d)) + a + K[j] + W[j]
				   a = d
				   d = c
				   c = b
				   b = ((F<<32 | F & (1<<32)-1) >> s) + b
				   s = md5_next_shift[s]
				end
				s = 32-5
				for j = 17, 32 do
				   local F = (c ~ d & (b ~ c)) + a + K[j] + W[(5*j-4 & 15) + 1]
				   a = d
				   d = c
				   c = b
				   b = ((F<<32 | F & (1<<32)-1) >> s) + b
				   s = md5_next_shift[s]
				end
				s = 32-4
				for j = 33, 48 do
				   local F = (b ~ c ~ d) + a + K[j] + W[(3*j+2 & 15) + 1]
				   a = d
				   d = c
				   c = b
				   b = ((F<<32 | F & (1<<32)-1) >> s) + b
				   s = md5_next_shift[s]
				end
				s = 32-6
				for j = 49, 64 do
				   local F = (c ~ (b | ~d)) + a + K[j] + W[(j*7-7 & 15) + 1]
				   a = d
				   d = c
				   c = b
				   b = ((F<<32 | F & (1<<32)-1) >> s) + b
				   s = md5_next_shift[s]
				end
				h1 = a + h1
				h2 = b + h2
				h3 = c + h3
				h4 = d + h4
			 end
			 H[1], H[2], H[3], H[4] = h1, h2, h3, h4
		  end
		  local function sha1_feed_64(H, str, offs, size)
			 -- offs >= 0, size >= 0, size is multiple of 64
			 local W = common_W
			 local h1, h2, h3, h4, h5 = H[1], H[2], H[3], H[4], H[5]
			 for pos = offs + 1, offs + size, 64 do
				W[1], W[2], W[3], W[4], W[5], W[6], W[7], W[8], W[9], W[10], W[11], W[12], W[13], W[14], W[15], W[16] =
				   string_unpack(">I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4I4", str, pos)
				for j = 17, 80 do
				   local a = W[j-3] ~ W[j-8] ~ W[j-14] ~ W[j-16]
				   W[j] = (a<<32 | a) << 1 >> 32
				end
				local a, b, c, d, e = h1, h2, h3, h4, h5
				for j = 1, 20 do
				   local z = ((a<<32 | a & (1<<32)-1) >> 27) + (d ~ b & (c ~ d)) + 0x5A827999 + W[j] + e      -- constant = floor(2^30 * sqrt(2))
				   e = d
				   d = c
				   c = (b<<32 | b & (1<<32)-1) >> 2
				   b = a
				   a = z
				end
				for j = 21, 40 do
				   local z = ((a<<32 | a & (1<<32)-1) >> 27) + (b ~ c ~ d) + 0x6ED9EBA1 + W[j] + e            -- 2^30 * sqrt(3)
				   e = d
				   d = c
				   c = (b<<32 | b & (1<<32)-1) >> 2
				   b = a
				   a = z
				end
				for j = 41, 60 do
				   local z = ((a<<32 | a & (1<<32)-1) >> 27) + ((b ~ c) & d ~ b & c) + 0x8F1BBCDC + W[j] + e  -- 2^30 * sqrt(5)
				   e = d
				   d = c
				   c = (b<<32 | b & (1<<32)-1) >> 2
				   b = a
				   a = z
				end
				for j = 61, 80 do
				   local z = ((a<<32 | a & (1<<32)-1) >> 27) + (b ~ c ~ d) + 0xCA62C1D6 + W[j] + e            -- 2^30 * sqrt(10)
				   e = d
				   d = c
				   c = (b<<32 | b & (1<<32)-1) >> 2
				   b = a
				   a = z
				end
				h1 = a + h1
				h2 = b + h2
				h3 = c + h3
				h4 = d + h4
				h5 = e + h5
			 end
			 H[1], H[2], H[3], H[4], H[5] = h1, h2, h3, h4, h5
		  end
		  
		  return HEX64, XOR64A5, XOR_BYTE, sha256_feed_64, sha512_feed_128, md5_feed_64, sha1_feed_64
		end
   HEX64, XOR64A5, XOR_BYTE, sha256_feed_64, sha512_feed_128, md5_feed_64, sha1_feed_64 = _init64_(md5_next_shift)

end

do
   local function mul(src1, src2, factor, result_length)
      -- src1, src2 - long integers (arrays of digits in base 2^24)
      -- factor - small integer
      -- returns long integer result (src1 * src2 * factor) and its floating point approximation
      local result, carry, value, weight = {}, 0.0, 0.0, 1.0
      for j = 1, result_length do
         for k = math.max(1, j + 1 - #src2), math.min(j, #src1) do
            carry = carry + factor * src1[k] * src2[j + 1 - k]  -- "int32" is not enough for multiplication result, that's why "factor" must be of type "double"
         end
         local digit = carry % 2^24
         result[j] = floor(digit)
         carry = (carry - digit) / 2^24
         value = value + digit * weight
         weight = weight * 2^24
      end
      return result, value
   end

   local idx, step, p, one, sqrt_hi, sqrt_lo = 0, {4, 1, 2, -2, 2}, 4, {1}, sha2_H_hi, sha2_H_lo
   repeat
      p = p + step[p % 6]
      local d = 1
      repeat
         d = d + step[d % 6]
         if d*d > p then -- next prime number is found
            local root = p^(1/3)
            local R = root * 2^40
            R = mul({R - R % 1}, one, 1.0, 2)
            local _, delta = mul(R, mul(R, R, 1.0, 4), -1.0, 4)
            local hi = R[2] % 65536 * 65536 + floor(R[1] / 256)
            local lo = R[1] % 256 * 16777216 + floor(delta * (2^-56 / 3) * root / p)
            if idx < 16 then
               root = p^(1/2)
               R = root * 2^40
               R = mul({R - R % 1}, one, 1.0, 2)
               _, delta = mul(R, R, -1.0, 2)
               local hi = R[2] % 65536 * 65536 + floor(R[1] / 256)
               local lo = R[1] % 256 * 16777216 + floor(delta * 2^-17 / root)
               local idx = idx % 8 + 1
               sha2_H_ext256[224][idx] = lo
               sqrt_hi[idx], sqrt_lo[idx] = hi, lo + hi * hi_factor
               if idx > 7 then
                  sqrt_hi, sqrt_lo = sha2_H_ext512_hi[384], sha2_H_ext512_lo[384]
               end
            end
            idx = idx + 1
            sha2_K_hi[idx], sha2_K_lo[idx] = hi, lo % K_lo_modulo + hi * hi_factor
            break
         end
      until p % d == 0
   until idx > 79
end

-- Calculating IVs for SHA512/224 and SHA512/256
for width = 224, 256, 32 do
   local H_lo, H_hi = {}
   if XOR64A5 then
      for j = 1, 8 do
         H_lo[j] = XOR64A5(sha2_H_lo[j])
      end
   else
      H_hi = {}
      for j = 1, 8 do
         H_lo[j] = XOR32A5(sha2_H_lo[j])
         H_hi[j] = XOR32A5(sha2_H_hi[j])
      end
   end
   sha512_feed_128(H_lo, H_hi, sha2_K_lo, sha2_K_hi, "SHA-512/"..tonumber(width).."\128"..string_rep("\0", 115).."\88", 0, 128)
   sha2_H_ext512_lo[width] = H_lo
   sha2_H_ext512_hi[width] = H_hi
end

-- Constants for MD5
do
   local sin, abs, modf = math.sin, math.abs, math.modf
   for idx = 1, 64 do
      -- we can't use formula floor(abs(sin(idx))*2^32) because its result may be not an integer on Lua built with 32-bit integers
      local hi, lo = modf(abs(sin(idx)) * 2^16)
      md5_K[idx] = hi * 65536 + floor(lo * 2^16)
   end
end

--------------------------------------------------------------------------------
-- MAIN FUNCTIONS
--------------------------------------------------------------------------------

local function sha256ext(width, text)

   -- Create an instance (private objects for current calculation)
   local H, length, tail = {unpack(sha2_H_ext256[width])}, 0.0, ""

   local function partial(text_part)
      if text_part then
         if tail then
            length = length + #text_part
            local offs = 0
            if tail ~= "" and #tail + #text_part >= 64 then
               offs = 64 - #tail
               sha256_feed_64(H, sha2_K_hi, tail..sub(text_part, 1, offs), 0, 64)
               tail = ""
            end
            local size = #text_part - offs
            local size_tail = size % 64
            sha256_feed_64(H, sha2_K_hi, text_part, offs, size - size_tail)
            tail = tail..sub(text_part, #text_part + 1 - size_tail)
            return partial
         else
            error("Adding more chunks is not allowed after receiving the result", 2)
         end
      else
         if tail then
            local final_blocks = {tail, "\128", string_rep("\0", (-9 - length) % 64 + 1)}
            tail = nil
            -- Assuming user data length is shorter than (2^53)-9 bytes
            -- Anyway, it looks very unrealistic that someone would spend more than a year of calculations to process 2^53 bytes of data by using this Lua script :-)
            -- 2^53 bytes = 2^56 bits, so "bit-counter" fits in 7 bytes
            length = length * (8 / 256^7)  -- convert "byte-counter" to "bit-counter" and move decimal point to the left
            for j = 4, 10 do
               length = length % 1 * 256
               final_blocks[j] = char(floor(length))
            end
            final_blocks = table_concat(final_blocks)
            sha256_feed_64(H, sha2_K_hi, final_blocks, 0, #final_blocks)
            local max_reg = width / 32
            for j = 1, max_reg do
               H[j] = HEX(H[j])
            end
            H = table_concat(H, "", 1, max_reg)
         end
         return H
      end
   end

   if text then
      -- Actually perform calculations and return the SHA256 digest of a message
      return partial(text)()
   else
      -- Return function for chunk-by-chunk loading
      -- User should feed every chunk of input data as single argument to this function and finally get SHA256 digest by invoking this function without an argument
      return partial
   end

end


local function sha512ext(width, text)

   -- Create an instance (private objects for current calculation)
   local length, tail, H_lo, H_hi = 0.0, "", { unpack(sha2_H_ext512_lo[width]) }, not HEX64 and { unpack(sha2_H_ext512_hi[width]) }

   local function partial(text_part)
      if text_part then
         if tail then
            length = length + #text_part
            local offs = 0
            if tail ~= "" and #tail + #text_part >= 128 then
               offs = 128 - #tail
               sha512_feed_128(H_lo, H_hi, sha2_K_lo, sha2_K_hi, tail..sub(text_part, 1, offs), 0, 128)
               tail = ""
            end
            local size = #text_part - offs
            local size_tail = size % 128
            sha512_feed_128(H_lo, H_hi, sha2_K_lo, sha2_K_hi, text_part, offs, size - size_tail)
            tail = tail..sub(text_part, #text_part + 1 - size_tail)
            return partial
         else
            error("Adding more chunks is not allowed after receiving the result", 2)
         end
      else
         if tail then
            local final_blocks = {tail, "\128", string_rep("\0", (-17-length) % 128 + 9)}
            tail = nil
            -- Assuming user data length is shorter than (2^53)-17 bytes
            -- 2^53 bytes = 2^56 bits, so "bit-counter" fits in 7 bytes
            length = length * (8 / 256^7)  -- convert "byte-counter" to "bit-counter" and move floating point to the left
            for j = 4, 10 do
               length = length % 1 * 256
               final_blocks[j] = char(floor(length))
            end
            final_blocks = table_concat(final_blocks)
            sha512_feed_128(H_lo, H_hi, sha2_K_lo, sha2_K_hi, final_blocks, 0, #final_blocks)
            local max_reg = ceil(width / 64)
            if HEX64 then
               for j = 1, max_reg do
                  H_lo[j] = HEX64(H_lo[j])
               end
            else
               for j = 1, max_reg do
                  H_lo[j] = HEX(H_hi[j])..HEX(H_lo[j])
               end
               H_hi = nil
            end
            H_lo = sub(table_concat(H_lo, "", 1, max_reg), 1, width / 4)
         end
         return H_lo
      end
   end

   if text then
      -- Actually perform calculations and return the SHA512 digest of a message
      return partial(text)()
   else
      -- Return function for chunk-by-chunk loading
      -- User should feed every chunk of input data as single argument to this function and finally get SHA512 digest by invoking this function without an argument
      return partial
   end

end


local function md5(text)

   -- Create an instance (private objects for current calculation)
   local H, length, tail = {unpack(md5_sha1_H, 1, 4)}, 0.0, ""

   local function partial(text_part)
      if text_part then
         if tail then
            length = length + #text_part
            local offs = 0
            if tail ~= "" and #tail + #text_part >= 64 then
               offs = 64 - #tail
               md5_feed_64(H, md5_K, tail..sub(text_part, 1, offs), 0, 64)
               tail = ""
            end
            local size = #text_part - offs
            local size_tail = size % 64
            md5_feed_64(H, md5_K, text_part, offs, size - size_tail)
            tail = tail..sub(text_part, #text_part + 1 - size_tail)
            return partial
         else
            error("Adding more chunks is not allowed after receiving the result", 2)
         end
      else
         if tail then
            local final_blocks = {tail, "\128", string_rep("\0", (-9 - length) % 64)}
            tail = nil
            length = length * 8  -- convert "byte-counter" to "bit-counter"
            for j = 4, 11 do
               local low_byte = length % 256
               final_blocks[j] = char(low_byte)
               length = (length - low_byte) / 256
            end
            final_blocks = table_concat(final_blocks)
            md5_feed_64(H, md5_K, final_blocks, 0, #final_blocks)
            for j = 1, 4 do
               H[j] = HEX(H[j])
            end
            H = gsub(table_concat(H), "(..)(..)(..)(..)", "%4%3%2%1")
         end
         return H
      end
   end

   if text then
      -- Actually perform calculations and return the MD5 digest of a message
      return partial(text)()
   else
      -- Return function for chunk-by-chunk loading
      -- User should feed every chunk of input data as single argument to this function and finally get MD5 digest by invoking this function without an argument
      return partial
   end

end


local function sha1(text)

   -- Create an instance (private objects for current calculation)
   local H, length, tail = {unpack(md5_sha1_H)}, 0.0, ""

   local function partial(text_part)
      if text_part then
         if tail then
            length = length + #text_part
            local offs = 0
            if tail ~= "" and #tail + #text_part >= 64 then
               offs = 64 - #tail
               sha1_feed_64(H, tail..sub(text_part, 1, offs), 0, 64)
               tail = ""
            end
            local size = #text_part - offs
            local size_tail = size % 64
            sha1_feed_64(H, text_part, offs, size - size_tail)
            tail = tail..sub(text_part, #text_part + 1 - size_tail)
            return partial
         else
            error("Adding more chunks is not allowed after receiving the result", 2)
         end
      else
         if tail then
            local final_blocks = {tail, "\128", string_rep("\0", (-9 - length) % 64 + 1)}
            tail = nil
            -- Assuming user data length is shorter than (2^53)-9 bytes
            -- 2^53 bytes = 2^56 bits, so "bit-counter" fits in 7 bytes
            length = length * (8 / 256^7)  -- convert "byte-counter" to "bit-counter" and move decimal point to the left
            for j = 4, 10 do
               length = length % 1 * 256
               final_blocks[j] = char(floor(length))
            end
            final_blocks = table_concat(final_blocks)
            sha1_feed_64(H, final_blocks, 0, #final_blocks)
            for j = 1, 5 do
               H[j] = HEX(H[j])
            end
            H = table_concat(H)
         end
         return H
      end
   end

   if text then
      -- Actually perform calculations and return the SHA-1 digest of a message
      return partial(text)()
   else
      -- Return function for chunk-by-chunk loading
      -- User should feed every chunk of input data as single argument to this function and finally get SHA-1 digest by invoking this function without an argument
      return partial
   end

end


local function hex2bin(hex_string)
   return (gsub(hex_string, "%x%x",
      function (hh)
         return char(tonumber(hh, 16))
      end
   ))
end


local block_size_for_HMAC  -- a table, will be defined at the end of the module

local function pad_and_xor(str, result_length, byte_for_xor)
   return gsub(str, ".",
      function(c)
         return char(XOR_BYTE(byte(c), byte_for_xor))
      end
   )..string_rep(char(byte_for_xor), result_length - #str)
end

local function hmac(hash_func, key, message)

   -- Create an instance (private objects for current calculation)
   local block_size = block_size_for_HMAC[hash_func]
   if not block_size then
      error("Unknown hash function", 2)
   end
   if #key > block_size then
      key = hex2bin(hash_func(key))
   end
   local append = hash_func()(pad_and_xor(key, block_size, 0x36))
   local result

   local function partial(message_part)
      if not message_part then
         result = result or hash_func(pad_and_xor(key, block_size, 0x5C)..hex2bin(append()))
         return result
      elseif result then
         error("Adding more chunks is not allowed after receiving the result", 2)
      else
         append(message_part)
         return partial
      end
   end

   if message then
      -- Actually perform calculations and return the HMAC of a message
      return partial(message)()
   else
      -- Return function for chunk-by-chunk loading of a message
      -- User should feed every chunk of the message as single argument to this function and finally get HMAC by invoking this function without an argument
      return partial
   end

end


local sha2 = {
   -- SHA2 hash functions:
   sha256     = function (text) return sha256ext(256, text) end,  -- SHA-256
   sha224     = function (text) return sha256ext(224, text) end,  -- SHA-224
   sha512     = function (text) return sha512ext(512, text) end,  -- SHA-512
   sha384     = function (text) return sha512ext(384, text) end,  -- SHA-384
   sha512_224 = function (text) return sha512ext(224, text) end,  -- SHA-512/224
   sha512_256 = function (text) return sha512ext(256, text) end,  -- SHA-512/256
   -- other hash functions:
   md5        = md5,                                              -- MD5
   sha1       = sha1,                                             -- SHA-1
   -- misc utilities:
   hmac       = hmac,                                             -- HMAC (applicable to any hash function from this module)
   hex2bin    = hex2bin,                                          -- converts hexadecimal representation to binary string
}

block_size_for_HMAC = {
   [sha2.sha256]     = 64,  -- SHA-256
   [sha2.sha224]     = 64,  -- SHA-224
   [sha2.sha512]     = 128, -- SHA-512
   [sha2.sha384]     = 128, -- SHA-384
   [sha2.sha512_224] = 128, -- SHA-512/224
   [sha2.sha512_256] = 128, -- SHA-512/256
   [sha2.md5]        = 64,  -- MD5
   [sha2.sha1]       = 64,  -- SHA-1
}

return sha2
