_const={
	Middle = "Middle",	--居中
	Left = "Left",	--左
	Right = "Right",--右
	Top = "Top",	--上
	Bottom = "Bottom",	--下
	LeftTop = "LeftTop",	--左上
	LeftBottom = "LeftBottom",	--左下
	RightTop = "RightTop",	--右上
	RightBottom ="RightBottom",	--右下	
	getXY = "GetXY",
	FilePath = "private",
	offsetMode = "withArry",
	GetColorMode = "getColor", --"getBilinear" "getColor"
	Arry=nil,
	MainPointScale={
		["Middle"] = function(point,Arry)
			local x=Arry.Cur.x/2-((Arry.Dev.x/2-point.x)*Arry.MainPointsScaleMode)+Arry.Cur.Left
			local y=Arry.Cur.y/2-((Arry.Dev.y/2-point.y)*Arry.MainPointsScaleMode)+Arry.Cur.Top
			return x,y
		end,
		["Left"] = function (point,Arry)--左中
			local x=point.x*Arry.MainPointsScaleMode+Arry.Cur.Left
			local y=Arry.Cur.y/2-((Arry.Dev.y/2-point.y)*Arry.MainPointsScaleMode)+Arry.Cur.Top
			return x,y
		end,
		["Right"] = function (point,Arry)--右中
			local x=Arry.Cur.x-((Arry.Dev.x-point.x)*Arry.MainPointsScaleMode)+Arry.Cur.Left
			local y=Arry.Cur.y/2-((Arry.Dev.y/2-point.y)*Arry.MainPointsScaleMode)+Arry.Cur.Top
			return x,y
		end,
		["Top"] = function (point,Arry)--上中 
			local x=Arry.Cur.x/2-((Arry.Dev.x/2-point.x)*Arry.MainPointsScaleMode)+Arry.Cur.Left
			local y=point.y*Arry.MainPointsScaleMode+Arry.Cur.Top
			return x,y
		end,
		["Bottom"] = function (point,Arry)--下中
			local x=Arry.Cur.x/2-((Arry.Dev.x/2-point.x)*Arry.MainPointsScaleMode)+Arry.Cur.Left
			local y=Arry.Cur.y-((Arry.Dev.y-point.y)*Arry.MainPointsScaleMode)+Arry.Cur.Top
			return x,y
		end,
		["LeftTop"] = function (point,Arry)--左上
			local x=point.x*Arry.MainPointsScaleMode+Arry.Cur.Left
			local y=point.y*Arry.MainPointsScaleMode+Arry.Cur.Top
			return x,y
		end,
		["LeftBottom"] = function (point,Arry)--左下
			local x=point.x*Arry.MainPointsScaleMode+Arry.Cur.Left
			local y=Arry.Cur.y-((Arry.Dev.y-point.y)*Arry.MainPointsScaleMode)+Arry.Cur.Top
			return x,y
		end,
		["RightTop"] = function (point,Arry) --右上角
			local x=Arry.Cur.x-((Arry.Dev.x-point.x)*Arry.MainPointsScaleMode)+Arry.Cur.Left
			local y=point.y*Arry.MainPointsScaleMode+Arry.Cur.Top
			return x,y
		end,
		["RightBottom"] = function (point,Arry) --右下角
			local x=Arry.Cur.x-((Arry.Dev.x-point.x)*Arry.MainPointsScaleMode)+Arry.Cur.Left
			local y=Arry.Cur.y-((Arry.Dev.y-point.y)*Arry.MainPointsScaleMode)+Arry.Cur.Top
			return x,y
		end,
	},
}

_GetSpaceNum = 	{
		"\t",
		"\t\t",
		"\t\t\t",
		"\t\t\t\t",
		"\t\t\t\t\t",
		"\t\t\t\t\t\t",
		"\t\t\t\t\t\t\t",
		"\t\t\t\t\t\t\t\t",
		"\t\t\t\t\t\t\t\t\t",
		"\t\t\t\t\t\t\t\t\t\t",
		"\t\t\t\t\t\t\t\t\t\t\t",
	}

_printcustomData_ = function (_type)
	if _type=="point" then
		return _printPoint_
	elseif _type=="multiPoint" then
		return _printmultiPoint_ 
	end
end
_printcmpColorErr_ = function (Cur,Dev,tag,key) 
	tag=tag or "" 
	return  
end
_printPoint_ = function (p)
	return string.format("point<x=%.2f,y=%.2f>",p.Cur.x,p.Cur.y)
end
_printmultiPoint_ = function (multi,Num)
Num=Num or ""
	local str="multiPoint< \n"
		for k,v in ipairs(multi) do
			str=str..string.format("%s[x=%.2f,y=%.2f]>\n",
			Num,v.Cur.x,v.Cur.y)
		end
		if multi.Area then str=str..string.format("%s%s",Num,multi.Area) end
		if multi.index then str=str..string.format("%s%s",multi.index) end
		str=str..">"
	return str
end

return _const
