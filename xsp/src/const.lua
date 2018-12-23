_const={
	Middle="Middle",	--居中
	Left="Left",	--左
	Right="Right",--右
	Top="Top",	--上
	Bottom="Bottom",	--下
	LeftTop="LeftTop",	--左上
	LeftBottom="LeftBottom",	--左下
	RightTop="RightTop",	--右上
	RightBottom="RightBottom",	--右下	
	getXY="GetXY",
	FilePath="private",
	offsetMode="withArry",
	GetColorMode="getBilinear", --"getBilinear" "getColor"
	Arry=nil,
	MainPointScale={
		["Middle"]=function(point,Arry)
			x=Arry.Cur.x/2-((Arry.Dev.x/2-point.x)*Arry.MainPointsScaleMode)+Arry.Cur.Left
			y=Arry.Cur.y/2-((Arry.Dev.y/2-point.y)*Arry.MainPointsScaleMode)+Arry.Cur.Top
			return x,y
		end,
		["Left"]=function (point,Arry)--左中
			x=point.x*Arry.MainPointsScaleMode+Arry.Cur.Left
			y=Arry.Cur.y/2-((Arry.Dev.y/2-point.y)*Arry.MainPointsScaleMode)+Arry.Cur.Top
			return x,y
		end,
		["Right"]=function (point,Arry)--右中
			x=Arry.Cur.x-((Arry.Dev.x-point.x)*Arry.MainPointsScaleMode)+Arry.Cur.Left
			y=Arry.Cur.y/2-((Arry.Dev.y/2-point.y)*Arry.MainPointsScaleMode)+Arry.Cur.Top
			return x,y
		end,
		["Top"]=function (point,Arry)--上中 
			x=Arry.Cur.x/2-((Arry.Dev.x/2-point.x)*Arry.MainPointsScaleMode)+Arry.Cur.Left
			y=MainPoint.y*Arry.MainPointsScaleMode+Arry.Cur.Top
			return x,y
		end,
		["Bottom"]=function (point,Arry)--下中
			x=Arry.Cur.x/2-((Arry.Dev.x/2-point.x)*Arry.MainPointsScaleMode)+Arry.Cur.Left
			y=Arry.Cur.y-((Arry.Dev.y-point.y)*Arry.MainPointsScaleMode)+Arry.Cur.Top
			return x,y
		end,
		["LeftTop"]=function (point,Arry)--左上
			x=point.x*Arry.MainPointsScaleMode+Arry.Cur.Left
			y=point.y*Arry.MainPointsScaleMode+Arry.Cur.Top
			return x,y
		end,
		["LeftBottom"]=function (point,Arry)--左下
			x=point.x*Arry.MainPointsScaleMode+Arry.Cur.Left
			y=Arry.Cur.y-((Arry.Dev.y-point.y)*Arry.MainPointsScaleMode)+Arry.Cur.Top
			return x,y
		end,
		["RightTop"]=function (point,Arry) --右上角
			x=Arry.Cur.x-((Arry.Dev.x-point.x)*Arry.MainPointsScaleMode)+Arry.Cur.Left
			y=point.y*Arry.MainPointsScaleMode+Arry.Cur.Top
			return x,y
		end,
		["RightBottom"]=function (point,Arry) --右下角
			x=Arry.Cur.x-((Arry.Dev.x-point.x)*Arry.MainPointsScaleMode)+Arry.Cur.Left
			y=Arry.Cur.y-((Arry.Dev.y-point.y)*Arry.MainPointsScaleMode)+Arry.Cur.Top
			return x,y
		end,
	},
}

_GetSpaceNum = function () 
return	{
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
end

_printcmpColorErr_ = function (Cur,Dev,tag,key) tag=tag or "" return  end

return _const
