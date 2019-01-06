function TableCopy(Tbl)--表复制没有复制元表
	local t={}
	if getmetatable(Tbl) then setmetatable(t,getmetatable(Tbl)) end
	for k,v in pairs(Tbl) do
		if type(v)=="table" then
			t[k]=TableCopy(v)
		else
			t[k]=v
		end
	end
	return t
end

function slp(T)	--传入秒
	T=T or 0.05
	T=T*1000
	sleep(T)
end

function belongvalue(aimTable,aim)--判断目标变量在表中是否存在
	for _,v in pairs(aimTable) do
		if aim==v then
			return true
		end
	end
	return false
end

function belongkey(aimTable,aim)--判断目标变量在表中是否存在
	for k,_ in pairs(aimTable) do
		if aim==k then
			return true
		end
	end
	return false
end

function getTableFromString(str,aim) --从字符串中查找符合aim的条件,以表返回
	local insert=table.insert
	local aimTable={}
	for v in string.gmatch(str,aim) do
		insert(aimTable,v)
	end
	return aimTable
end

function getTableRepeatnum(tbl)--获取表中重复的数字
local t={}
	for k,v in pairs(tbl) do
		if t[v] then
			t[v]=t[v]+1
		else
			t[v]=1
		end
	end
	return t
end

function getStrLen(str)--获取字符串长度
	local l=string.len(str)
	local len=0
	for i=1,l do
	local ascii=string.byte(string.sub(str,i,i))
		if ascii>127 then
			len=len+1/3
		else
			len=len+1
		end
	end
	return math.floor(len+0.5)
end

function getTblLen(tbl)--获取表长度
	local len=0
	for k,v in pairs(tbl) do
		len=len+1
	end
	return len
end

function split(str,pattern,content)--字符串分割
	if str==nil or str=='' or pattern==nil then
		return {}
	end
	local result = {}
	if content=="single" then
		str=str..pattern
		pattern="(.-)"..pattern
	end
	
	for v in string.gmatch(str,pattern) do
		result[#result+1]=v
	end
	return result
end

function urlencode(w)
local pattern = "[^%w%d%?=&:/._%-%* ]"
    s = string.gsub(w, pattern, function(c)
        local c = string.format("%%%02X", string.byte(c))
        return c
    end)
    s = string.gsub(s, " ", "+")
    return s
end

function string.trim(s)
	return s:match'^%s*(.*%S)'  or ''
end

function screenPoint(Table,n)
local abs=math.abs
local sqrt=math.sqrt
	local new = {}
	for i = 1, #Table do
		new[i] = {}
		for k = 1, #Table do
			if k ~= i then
--			local distance = sqrt((Table[k].x-Table[i].x)^2+(Table[k].y-Table[i].y)^2)
--				if distance <= n then
--					new[i][#new[i]+1] = k
--				end
--			end
				if abs(Table[k].x-Table[i].x)<=n and abs(Table[k].y-Table[i].y)<=n then
					new[i][#new[i]+1] = k
				end
			end
		end
	end
--根据new[i]的长度 排出一个table
	local length = {}
	for i = 1, #new do
		length[i] = {length=#new[i],key=i}
	end
	table.sort(length,function(a,b) return a.length>b.length end)
	for i = 1, #length do
		local key = length[i].key
		if new[key] then
			for k = 1, #new[key] do
				new[new[key][k]] = false
			end
		end
	end
	local retPoint = {}
	for i = 1, #new do
		if new[i] then
			retPoint[#retPoint+1] = Table[i]
		end
	end
	return retPoint
end

function getScaleMainPoint(MainPoint,Anchor,Arry)	--缩放锚点
	local point={
		x=MainPoint.x-Arry.Dev.Left,
		y=MainPoint.y-Arry.Dev.Top,
	}
	local x,y,fun
	fun=_const.MainPointScale[Anchor]
	x,y=fun(point,Arry)
	return {x=x,y=y}
end

function getScaleXY(point,MainPoint,DstMainPoint,Arry)	--缩放XY
	local x=DstMainPoint.x+(point.x-MainPoint.x)*Arry.AppurtenantScaleMode
	local y=DstMainPoint.y+(point.y-MainPoint.y)*Arry.AppurtenantScaleMode
	return x,y
end

function getScaleArea(Area,DstMainPoint,MainPoint,Arry)	--缩放Area
	if DstMainPoint then
		if #Area==2 then return 
		{getScaleXY({x=Area[1],y=Area[2]},MainPoint,DstMainPoint,Arry)} end
		Area[1],Area[2]=getScaleXY({x=Area[1],y=Area[2]},MainPoint,DstMainPoint,Arry)
		Area[3],Area[4]=getScaleXY({x=Area[3],y=Area[4]},MainPoint,DstMainPoint,Arry)
	else
		if #Area==2 then return 
				{(Area[1]-Arry.Dev.Left)*Arry.AppurtenantScaleMode+Arry.Cur.Left,
				(Area[2]-Arry.Dev.Top)*Arry.AppurtenantScaleMode+Arry.Cur.Top}
		end
		Area[1]=(Area[1]-Arry.Dev.Left)*Arry.AppurtenantScaleMode+Arry.Cur.Left
		Area[3]=(Area[3]-Arry.Dev.Left)*Arry.AppurtenantScaleMode+Arry.Cur.Left
		Area[2]=(Area[2]-Arry.Dev.Top)*Arry.AppurtenantScaleMode+Arry.Cur.Top
		Area[4]=(Area[4]-Arry.Dev.Top)*Arry.AppurtenantScaleMode+Arry.Cur.Top
	end
	local width=Area[3]-Area[1]
	local height=Area[4]-Area[2]
	return  Rect(Area[1],Area[2],width,height)
end

function _SpaceNumRep(SpaceNum,Num)
	if SpaceNum[Num] then
		return SpaceNum[Num]
	end
	return Num == 0 and '' or string.rep('\t',Num)
end
	
function Print(...)
local SpaceNum=_GetSpaceNum()
local Num=0
local format=string.format
local arg={...}
local tbl={}
	function printTable(t,Num)
	Num=Num+1
	local tbl={}
		for k,v in pairs(t) do
			local _type=type(v)
			local _Space=_SpaceNumRep(SpaceNum,Num)
			if _type=="table" and (v._type=="point" or v._type=="multiPoint") then
				tbl[#tbl+1]=format("%s[%s] = %s",_Space,tostring(k),(_printcustomData_(v._type))(v,_SpaceNumRep(SpaceNum,Num+1)))
			elseif _type=="table" and k~="_G" and(not v.package) then
				tbl[#tbl+1]=format("%s[%s](tbl)={ \n %s %s }",_Space,tostring(k),printTable(v,Num),_SpaceNumRep(SpaceNum,Num))
			elseif _type=="table" and (v.package) then
				tbl[#tbl+1]=format("%s[%s](%s) = %s",_Space,tostring(k),_type,v)
			elseif _type=="boolean" then
				tbl[#tbl+1]=format("%s[%s](bool) = %s",_Space,tostring(k),(v and "true" or "false"))
			else
				tbl[#tbl+1]=format("%s[%s](%s) = %s",_Space,tostring(k),string.sub(_type,1,3),v)
			end
			tbl[#tbl+1]="\n"
		end
		return table.concat(tbl)
	end
	
	for i=1,#arg do
		local t=arg[i]
		local _type=type(t)
			if _type=="table" then
				if t._type then 
					tbl[#tbl+1]=format("%s",(_printcustomData_(t._type))(t))
				else
					tbl[#tbl+1]=format("\n Table = { \n %s }",printTable(t,Num))
				end
			elseif _type=="string" then
				tbl[#tbl+1]=format("%s",(t=="" and "empty_s"  or t))
			elseif _type=="boolean" then
				tbl[#tbl+1]=format("%s",(t and "true" or "false"))
			elseif _type=="nil" then
				tbl[#tbl+1]=format("%s","nil")
			else
				tbl[#tbl+1]=format("%s",t)
			end
		tbl[#tbl+1]=","
	end
	tbl[#tbl]=""
print(table.concat(tbl))
end
