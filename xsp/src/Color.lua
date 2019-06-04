local colorApi={
	['Color3B']=Color3B,['Color3F']=Color3F,
}
local transformStr={
	RGB={
		Color3B='Color3B',Color3F='Color3F',ColorHSV='rgbToHSV',ColorHSL='rgbToHSL',
	},
	Tag={
		Color3B='toC3B',Color3F='toC3F',ColorHSV='toHSV',ColorHSL='toHSL',
	},
}
local base={}
local floor=math.floor
local function round(num,i)
    local mult = 10^(i or 0)
    local mult10 = mult * 10
    return math.floor((num * mult10 + 5)/10)/ mult
end

local function rgbToHSL(r,g,b) --Color3F {h,s,l}
	local r,g,b = r,g,b
    local min = math.min(r, g, b)
    local max = math.max(r, g, b)
    local delta = max - min

    local H, S, L = 0, 0, ((min+max)/2)

    if L > 0 and L < 0.2 then S = delta/(2*L) end
    if L >= 0.5 and L < 100 then S = delta/(2-(2*L)) end
	if L==1 then S = 1 end
	
    if delta > 0 then
       	if max == r and max ~= g then H = H + (g-b)/delta end
       	if max == g and max ~= b then H = H + 2 + (b-r)/delta end
       	if max == b and max ~= r then H = H + 4 + (r-g)/delta end
       	H = H / 6
	elseif delta ==0 then
		H = 1
    end

    if H < 0 then H = H + 1 end
    if H > 1 then H = H - 1 end
    S=round(S,2)*100
    L=round(L,2)*100
    return {h=H*360,s=S,l=L} --H[0~360] S[0~100] V[0~100]
end
local function rgbToHSV(r,g,b) --Color3B {h,s,v}
	local r,g,b = r,g,b
	local h,s,v = 0,0,0
	local max=math.max(r,g,b)
	local min=math.min(r,g,b)
	if r == max and r~=255 then h = (g-b)/(max-min) end
	if g == max and g~=255 then h = 2 + (b-r)/(max-min) end
	if b == max and g~=255 then h = 4 + (r-g)/(max-min) end
	h = round((h*60),0)
	if h < 0 then h = h + 360 end
	v=round(max/255,2)*100
	s=round(((max-min)/max),2)*100
	return {h=h,s=s,v=v} --H[0~360] S[0~100] V[0~100]
end
local function HSLToHSV()

end
local function HSVToHSL()

end
colorApi.rgbToHSL=rgbToHSL
colorApi.rgbToHSV=rgbToHSV

ColorHSV={}
ColorHSVfun={__tag='ColorHSV'}
local ColorHSVMeta={
	__tostring=function(self)
		return string.format('HSV<%d, %d, %d>',self.h,self.s,self.v)
	end,
	__index=function(self,k)
		return ColorHSVfun[k]
	end
}
setmetatable(ColorHSV,{
	__index = function(self,k)
		return ColorHSVfun[k]
	end,
	__call = function (self,...)
		local arg = {...}
		local h,s,v
		if #arg==0 then
			h,s,v=0,0,0
		elseif #arg==1 then
			if type(arg[1])=='table' or type(arg[1])=='userdata' and arg[1].__tag then
				local c = arg[1]:toHSV()
				h,s,v = c.h,c.s,c.v
			elseif type(arg[1]=='number') and arg[1]>=0 and arg[1]<=0xffffff then
				local r,g,b=floor(arg[1]/0x10000),floor(arg[1]/0x100)%0x100,arg[1]%0x100
				local c = colorApi.rgbToHSV(r,g,b)
				h,s,v = c.h,c.s,c.v
			end
		elseif #arg==3 and type(arg[1])=='number' and type(arg[2])=='number' and type(arg[3])=='number' then
				h,s,v=...
				if h<0 or h>360 or s<0 or s>100 or v<0 or v>100 then error()
			end
		else
			error()
		end
		return setmetatable({h=h,s=s,v=v},ColorHSVMeta)
	end
})

ColorHSL={}
ColorHSLfun={__tag='ColorHSL'}
local ColorHSLMeta={
	__tostring=function(self)
		return string.format('HSL<%d, %d, %d>',self.h,self.s,self.l)
	end,
	__index=function(self,k)
		return ColorHSLfun[k]
	end
}
setmetatable(ColorHSL,{
	__index = function(self,k)
		return ColorHSLfun[k]
	end,
	__call = function (self,...)
		local arg = {...}
		local h,s,l
		if #arg==0 then
			h,s,l=0,0,0
		elseif #arg==1 then
			if type(arg[1])=='table' or type(arg[1])=='userdata' and arg[1].__tag then
				local c = arg[1]:toHSL()
				h,s,v = c.h,c.s,c.l
			elseif type(arg[1]=='number') and arg[1]>=0 and arg[1]<=0xffffff then
				local r,g,b=floor(arg[1]/0x10000)/0xff,floor(arg[1]/0x100)%0x100/0xff,arg[1]%0x100/0xff
				local c = colorApi.rgbToHSL(r,g,b)
				h,s,v = c.h,c.s,c.l
			end
		elseif #arg==3 and type(arg[1])=='number' and type(arg[2])=='number' and type(arg[3])=='number' then
				h,s,l=...
				if h<0 or h>360 or s<0 or s>100 or l<0 or l>100 then error()
			end
		else
			error()
		end
		return setmetatable({h=h,s=s,l=l},ColorHSLMeta)
	end
})


function base.transformColor(pattern,...) --中转函数用,pattern:Color3B,Color3F,ColorHSV,ColorHSL
	local pattern = pattern or error('received nil')
	local arg={...}
	local r,g,b,h,s,v,l
	if #arg==1 then
		if type(arg[1])=='table' and type(arg[1])=='userdata' and arg[1].__tag then
			return arg[1][transformStr[pattern]](arg[1])
		elseif type(arg[1])=='string' then
			local c = tonumber(t[1],16)
			if pattern=='Color3B' or pattern=='ColorHSV' then
				r,g,b=floor(c/0x10000),floor(c/0x100)%0x100,c%0x100
			elseif pattern=='Color3F' or pattern=='ColorHSL' then
				r,g,b=floor(c/0x10000)/0xff,floor(c/0x100)%0x100/0xff,c%0x100/0xff
			else 
				error('pattern error')
			end
			return colorApi[transformStr.RGB[pattern]](r,g,b)
		elseif type(arg[1])=='number' and arg[1]>=0 and arg[1]<=0xffffff then
			if pattern=='Color3B' or pattern=='ColorHSV' then
				r,g,b=floor(arg[1]/0x10000),floor(arg[1]/0x100)%0x100,arg[1]%0x100
			elseif pattern=='Color3F' or pattern=='ColorHSL' then
				r,g,b=math.floor(arg[1]/0x10000)/0xff,math.floor(arg[1]/0x100)%0x100/0xff,arg[1]%0x100/0xff
			else
				error('pattern error')				
			end
			return colorApi[transformStr.RGB[pattern]](r,g,b)
		end
	elseif #arg==3 then
		if type(arg[1])=="number" and type(arg[2])=="number" and type(arg[3])=="number" then
			if pattern=='Color3B' then
				r,g,b=...
				if r<0 or r>255 or g<0 or g>255 or b<0 or b>255 then error() end
			elseif pattern=='Color3F' then
				r,g,b=...
				if r<0 or r>1 or g<0 or g>1 or b<0 or b>1 then error() end
			elseif pattern=='ColorHSV' then
				h,s,v=...
				if h<0 or h>360 or s<0 or s>100 or v<0 or v>100 then error() end
			elseif pattern=='ColorHSL' then
				h,s,l=...
				if h<0 or h>360 or s<0 or s>100 or l<0 or l>100 then error() end				
			end
		end
	else
		error()
	end
end

function Color3B:toC3F()
	return Color3F(self) 
end
function Color3F:toC3B() 
	return Color3B(self)	
end
function Color3B:toHSL()
	local c = self:toC3F()
	return rgbToHSL(c.r,c.g,c.b)
end
function Color3B:toHSV()
	return rgbToHSV(self.r,self.g,self.b)
end
function Color3F:toHSL()
	return rgbToHSL(self.r,self.g,self.b)
end
function Color3F:toHSV()
	local c = self:toC3B()	
	return rgbToHSV(c.r,c.g,c.b)
end

function ColorHSVfun:toHSV()
	return self
end
function ColorHSVfun:toHSL()
	return self
end

return base