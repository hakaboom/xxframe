local xmodApi={}
for _,v in pairs({'crypto','cjson'}) do
	xmodApi[v] = require(v)
end

function table.deepcopy(tbl)
	local up_table = {}
	local function _copy(obj)
		if type(obj)~= 'table' then
			return obj
		elseif up_table[obj] then
			return up_table[obj]
		end
		local new_table = {}
		up_table[obj] = new_table
		for index,value in pairs(obj) do
			new_table[_copy(index)] = _copy(value)
		end
		return setmetatable(new_table,getmetatable(obj))
	end
	return _copy(tbl)
end
function table.copy(tbl)
	local new_table = {}
	for index,value in pairs(tbl) do
		if type(value) == 'table' then
			new_table[index] = table.copy(value)
		else
			new_table[k] = v
		end
	end
	return new_table
end
function table.contain(aimTable,aim,modex)
	local mode = mode or 'v'
	if mode == 'k' then
		return (aimTable[aim]~=nil)
	elseif mode == 'v' then
		for _,v in pairs(aimTable) do
			if v == aim then
				return true
			end
		end
		return false
	end
end
function table.getLen(tbl)
	local len=0
	for k,v in pairs(tbl) do
		len=len+1
	end
	return len
end
function table.keyPairs(tbl,comp)
	local ary = table.copy(tbl)
	for k in pairs(tbl) do
		ary[#ary+1] = k
	end
	table.sort(ary,comp)
	local i = 0
	local iter = function ()
		i = i+1
		if ary[i] == nil then
			return nil
		else
			return ary[i],tbl[ary[i]]
		end
	end
	return iter
end
function table.jsonEncode(tbl)
	return xmodApi['cjson'].encode(tbl)
end
function table.getIndexByValue(tbl,value)
	for k,v in pairs(tbl) do
		if v==value then
			return k
		end
	end
	return nil
end

function string.trim(s)
	return s:match'^%s*(.*%S)'  or ''
end
function string.split(str,pattern)
	if str==nil or pattern==nil then
		return {}
	end
	local result = {}
	local pattern = string.format('([^%s]+)',(pattern or '\t'))
	str:gsub(pattern,function(v) 
		result[#result] = v
	end)
	return result
end
function string.urlEncode(s)
	return s:gsub('[^%w%d%?=&:/._%-%* ]', function(c) return string.format('%%%02X', string.byte(c)) end):gsub(' ', '+')
end
function string.urlDecode(s)
	return s:gsub('%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
end
local function SubStringGetByteCount(str,index)
	local byte = string.byte(str,index)
	local byteCount = 1
	if byte == nil then
		byteCount = 0
	elseif byte > 0 and byte< 127 then
		byteCount = 1
	elseif byte>=192 and byte<224 then
		byteCount = 2
	elseif byte>=224 and byte<240 then
		byteCount = 3
	elseif byte>=240 and byte<248 then
		byteCount = 4
	elseif byte>=248 and byte<252 then
		byteCount = 5
	elseif byte>=252 then
		byteCount = 6
	end
	return byteCount
end
local function SubStringGetTrueIndex(str,index)
	local currentIndex = 0
	local i = 1
	local lastCount = 1
	repeat 
		lastCount = SubStringGetByteCount(str,i)
		i = i + lastCount
		currentIndex = currentIndex + 1
	until(currentIndex >= index)
	return i - lastCount
end
function string.utf8Len(s)
	return utf8.len(s)
end
function string.utf8Sub(s,startIndex,endIndex)
	if startIndex < 0 then
		startIndex = string.utf8Len(s) + startIndex + 1
	end
	if endIndex ~=nil and endIndex < 0 then
		endIndex = string.utf8Len(s) + endIndex + 1
	end
	if endIndex == nil then
		return string.sub(s,SubStringGetTrueIndex(s,startIndex))
	else
		return string.sub(s,SubStringGetTrueIndex(s,startIndex),SubStringGetTrueIndex(s,endIndex+1)-1)
	end

end
function string.Base64Encode(s)
	return xmodApi['crypto'].base64Encode(s)
end
function string.base64Decode(s)
	return xmodApi['crypto'].base64Decode(s)
end
function string.isInstr(s,aim)
	return string.find(s,aim)~=nil
end
function string.jsonDecode(s)
	return xmodApi['cjson'].decode(s)
end

function math.round(num,i)
    local mult = 10^(i or 0)
    local mult10 = mult * 10
    return math.floor((num * mult10 + 5)/10)/ mult
end

Base = {}
function Base.jsonDecode(s)
	return xmodApi['cjson'].decode(s)
end
function Base.jsonEncode(tbl)
	return xmodApi['cjson'].encode(tbl)
end
--/////////////////////////////////
local timeTransform={
	'ms','s','m','h','d','M',
	['ms']=1000,['s']=60,['m']=60,['h']=24,['d']=31,['M']=12
}
function Base.timeTransform(time,pattern,repl)
	if not pattern or not repl or not time then error('received nil') end
	local time = time
	local paIndex=table.getIndexByValue(timeTransform,pattern)
	local reIndex=table.getIndexByValue(timeTransform,repl)
	if paIndex < reIndex then
		for i=paIndex,reIndex-1 do
			time = time/timeTransform[timeTransform[i]]
		end
	elseif paIndex > reIndex then
		for i=reIndex,paIndex-1 do
			time = time*timeTransform[timeTransform[i]]
		end	
	end
	return time
end
function Base.formatTime(time,pattern)
	local time = Base.timeTransform(time,pattern,'s')
	return string.format("%.2d时%.2d分%.2d秒",time/(60*60),time/60%60,time%60)
end


function slp(T)	--传入秒
	T=T or 0.05
	T=T*1000
	sleep(T)
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


function _SpaceNumRep(SpaceNum,Num)
	if SpaceNum[Num] then
		return SpaceNum[Num]
	end
	return Num == 0 and '' or string.rep('\t',Num)
end
local _GetSpaceNum = {
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
function Print(...)
	local SpaceNum,format=_GetSpaceNum,string.format
	local Num=0
	local arg={...}
	local tbl={}
	local function printTable(t,Num)
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
			elseif _type=="string" then
				tbl[#tbl+1]=format("%s[%s](str) = %s",_Space,tostring(k),(v=="" and "empty_s"  or v))
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
			if (t._type=="point" or t._type=="multiPoint") then
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
	if #tbl==0 then 
		print('nil')
	else
		print(table.concat(tbl))
	end
end
-- local format=string.format
-- function Print(...)
-- 	local arg={...}
-- 	local tbl,Num={},0
-- 	local function printTable(t,Num)
-- 		Num=Num+1
-- 		local tbl = {}
-- 		for k,v in pairs(t) do
-- 			local _type,str=type(v)
-- 			local _space=_spaceNumRep(SpaceNum,Num)
-- 			if _type=='table' and k~='_G' and not v.package then
-- 				str=format()
-- 			end
-- 		end
-- 	end
-- 	for i=1,#arg do
-- 		local value,str=arg[i]
-- 		local _type=type(value)
-- 		if _type=='table' then
-- 			str=format('\n Table = { \n %s ',printTable(t,Num))
-- 		elseif _type=='string' then
-- 			str=format('%s, ',(value:utf8Len()==0 and 'empty_s' or value))
-- 		else
-- 			str=format('%s, ',tostring(value))
-- 		end
-- 		tbl[#tbl+1]=str
-- 	end
-- 	if #tbl==0 then 
-- 		print('nil')
-- 	else
-- 		print(table.concat(tbl))
-- 	end
-- end