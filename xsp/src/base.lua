local xmodApi={}
for _,v in pairs({'crypto','cjson','lfs'}) do
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



--Print抄自Zqys,在群文件中开源的print代码
local _SpaceNum = {}
for i = 1,10 do
	_SpaceNum[i] = ('\t'):rep(i)
end
local format = string.format
function Print(...) 
	local arg,str,_print = {...},{}
	_print = function(t,SpaceNum)
		local str = {}
		SpaceNum = SpaceNum + 1
		for k,v in pairs(t) do
			local value,_type = tostring(v),type(v)
			if _type == 'table' and k~='_G' and not v.package then
				if v.__tag then
					str[#str+1] = format('%s[%s](cur) = %s\r',(_SpaceNum[SpaceNum] or ('\t'):rep(SpaceNum)),tostring(k),value)
				else
					str[#str+1] = format('%s[%s](table) = {\r',(_SpaceNum[SpaceNum] or ('\t'):rep(SpaceNum)),tostring(k))
					if not next(v) then
						str[#str] = str[#str]:gsub('\r', '}\r')
					else
						str[#str+1] = format('%s%s}\r',_print(v,SpaceNum),(_SpaceNum[SpaceNum] or ('\t'):rep(SpaceNum)))
					end
				end
			else
	                --[ (附加功能: 更加人性化的function显示)
	                value = _type == 'function' and value:gsub('[^0]+', '', 1) or value --]]

	                --[ (附加功能: 更加简便的前缀)
	                _type = _type:sub(1, not (#_type > 6) and 3 or 4) --]]

	                --[[ (附加功能: 替换table中string的转义)
	                for k, v in pairs {['r'] = '\r', ['t'] = '\t', ['n'] = '\n', ['0'] = '\0'} do
	                    value = value:gsub(v, '(◇\\' .. k .. ')') --注意, 1.9中使用必须把↑↑上面的['0']项删掉
	                end --]]
	                str[#str + 1] = format('%s[%s](%s) = %s\r',(_SpaceNum[SpaceNum] or ('\t'):rep(SpaceNum)),tostring(k),_type,value)
			end
		end
		return table.concat(str)
	end
		for i=1, #arg do
			local _type = type(arg[i])
			if _type == 'table' and not arg[i].__tag then
				str[#str + 1] = format('\r◇ Table = {\r %s }\r\r',_print(arg[i], 0))
			else
				str[#str + 1] = format('%s%s',tostring(arg[i]),(i~=#arg and ', ' or ''))
			end
		end
		str = table.concat(str)
	print(str)
end