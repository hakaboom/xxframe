local colorApi={
	['Color3B']=Color3B,['Color3F']=Color3F,
}
local transformApi={
	RGB={
		Color3B='Color3B',Color3F='Color3F',ColorHSV='rgbToHSV',ColorHSL='rgbToHSL',
	},
	Tag={
		Color3B='toC3B',Color3F='toC3F',ColorHSV='toHSV',ColorHSL='toHSL',
	},
}
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
    S=S*100
    L=L*100
    return H*360,S,L --H[0~360] S[0~100] V[0~100]
end
local function rgbToHSV(r,g,b) --Color3B {h,s,v}
	local h,s,v = 0,0,0
	local max=math.max(r,g,b)
	local min=math.min(r,g,b)
	if r == max and g ~= max then h = (g-b)/(max-min) end
	if g == max and b ~= max then h = 2 + (b-r)/(max-min) end
	if b == max and r ~= max then h = 4 + (r-g)/(max-min) end
	h = round((h*60),0)
	if h < 0 then h = h + 360 end
	if max == 0 then return h,s,v end
	v=max/255*100
	s=(max-min)/max*100
	return h,s,v --H[0~360] S[0~100] V[0~100]
end
local function HSLToRGB(h,s,l)
	local h = h/360
	local s,l=s/100,l/100
	local m1,m2
	if l<=0.5 then
		m2 = l*(s+1)
	else
		m2=l+s-l*s
	end
	m1 = l*2-m2

	local function _h2rgb(m1, m2, h)
		if h<0 then h = h+1 end
		if h>1 then h = h-1 end
		if h*6<1 then 
			return m1+(m2-m1)*h*6
		elseif h*2<1 then 
			return m2 
		elseif h*3<2 then 
			return m1+(m2-m1)*(2/3-h)*6
		else
			return m1
		end
	end
	return _h2rgb(m1, m2, h+1/3), _h2rgb(m1, m2, h), _h2rgb(m1, m2, h-1/3)
end
local function HSVToRGB(h,s,v)
	local s,v=s/100,v/100
	local c = v * s
	local x = c*(1-math.abs((h/60)%2-1))
	local m = v - c
	local r,g,b
	if h==360 then h=0 end
	if h>=0 and h<60 then r,g,b=c,x,0 end
	if h>=60 and h<120 then r,g,b=x,c,0 end
	if h>=120 and h<180 then r,g,b=0,c,x end
	if h>=180 and h<240 then r,g,b=0,x,c end
	if h>=240 and h<300 then r,g,b=x,0,c end
	if h>=300 and h<360 then r,g,b=c,0,x end
	if h>360 then error() end
	return (r+m)*255,(g+m)*255,(b+m)*255
end
colorApi.rgbToHSV = rgbToHSV
colorApi.rgbToHSL = rgbToHSL


ColorHSV={}
colorApi.ColorHSV = ColorHSV
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
				h,s,v = arg[1]:toHSV()
			elseif type(arg[1]=='number') and arg[1]>=0 and arg[1]<=0xffffff then
				local r,g,b=floor(arg[1]/0x10000),floor(arg[1]/0x100)%0x100,arg[1]%0x100
				h,s,v= rgbToHSV(r,g,b)
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
colorApi.ColorHSL = ColorHSL
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
				h,s,l = arg[1]:toHSL()
			elseif type(arg[1]=='number') and arg[1]>=0 and arg[1]<=0xffffff then
				local r,g,b=floor(arg[1]/0x10000)/0xff,floor(arg[1]/0x100)%0x100/0xff,arg[1]%0x100/0xff
				h,s,l = rgbToHSL(r,g,b)
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


function transformColor(pattern,...) --pattern:Color3B,Color3F,ColorHSV,ColorHSL,为啥写了好像没啥用
	local pattern = pattern or error('received nil')
	local arg={...}
	local r,g,b,h,s,v,l
	local m1,m2,m3
	if #arg==1 then
		if type(arg[1])=='table' or type(arg[1])=='userdata' and arg[1].__tag then
			return arg[1][transformApi.Tag[pattern]](arg[1])
		elseif type(arg[1])=='string' then
			local c = tonumber(t[1],16)
			if pattern=='Color3B' or pattern=='ColorHSV' then
				r,g,b = floor(c/0x10000),floor(c/0x100)%0x100,c%0x100
			elseif pattern=='Color3F' or pattern=='ColorHSL' then
				r,g,b = floor(c/0x10000)/0xff,floor(c/0x100)%0x100/0xff,c%0x100/0xff
			else 
				error('pattern error')
			end
			return colorApi[transformApi.RGB[pattern]](r,g,b)
		elseif type(arg[1])=='number' and arg[1]>=0 and arg[1]<=0xffffff then
			if pattern=='Color3B' or pattern=='ColorHSV' then
				r,g,b = floor(arg[1]/0x10000),floor(arg[1]/0x100)%0x100,arg[1]%0x100
			elseif pattern=='Color3F' or pattern=='ColorHSL' then
				r,g,b = math.floor(arg[1]/0x10000)/0xff,math.floor(arg[1]/0x100)%0x100/0xff,arg[1]%0x100/0xff
			else
				error('pattern error')				
			end
			m1,m2,m3 = colorApi[transformApi.RGB[pattern]](r,g,b)
		else
			error()
		end
	elseif #arg==3 then
		if type(arg[1])=="number" and type(arg[2])=="number" and type(arg[3])=="number" then
			if pattern=='Color3B' then
				m1,m2,m3 =... -- r,g,b
				if m1<0 or m1>255 or m2<0 or m2>255 or m3<0 or m3>255 then error() end
			elseif pattern=='Color3F' then
				m1,m2,m3 =... --r,g,b
				if m1<0 or m1>1 or m2<0 or m2>1 or m3<0 or m3>1 then error() end
			elseif pattern=='ColorHSV' then
				m1,m2,m3 =... --h,s,v
				if m1<0 or m1>360 or m2<0 or m2>100 or m3<0 or m3>100 then error() end
			elseif pattern=='ColorHSL' then
				m1,m2,m3 =... - h,s,l
				if m1<0 or m1>360 or m2<0 or m2>100 or m3<0 or m3>100 then error() end				
			end
		end
	else
		error()
	end
	return colorApi[pattern](m1,m2,m3)
end

function Color3B:toC3F()
	return Color3F(self) 
end
function Color3F:toC3B() 
	return Color3B(self)	
end
function Color3B:toHSL()
	local c = self:toC3F()
	return ColorHSL(rgbToHSL(c.r,c.g,c.b))
end
function Color3B:toHSV()
	return ColorHSV(rgbToHSV(self.r,self.g,self.b))
end
function Color3F:toHSL()
	return ColorHSL(rgbToHSL(self.r,self.g,self.b))
end
function Color3F:toHSV()
	local c = self:toC3B()
	return ColorHSV(rgbToHSV(c.r,c.g,c.b))
end

function ColorHSLfun:toC3B()
	local r,g,b = HSLToRGB(self.h,self.s,self.l)
	return Color3B(r*0xff,g*0xff,b*0xff)
end
function ColorHSLfun:toC3F()
	return Color3B(HSLToRGB(self.h,self.s,self.l))
end
function ColorHSLfun:toHSV()
	local r,g,b = HSVToRGB(self.h,self.s,self.l)
	return transformColor('ColorHSV',r,g,b)
end

function ColorHSVfun:toC3B()
	local r,g,b = HSVToRGB(self.h,self.s,self.v)
	return Color3B(r,g,b)
end
function ColorHSVfun:toC3F()
	local r,g,b = HSVToRGB(self.h,self.s,self.v)
	return Color3F(r/0xff,g/0xff,b/0xff)
end
function ColorHSVfun:toHSL()
	local r,g,b = HSVToRGB(self.h,self.s,self.v)
	return transformColor('ColorHSL',r/0xff,g/0xff,b/0xff)
end
