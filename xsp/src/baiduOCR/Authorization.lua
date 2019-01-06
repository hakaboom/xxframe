local sha2=require'baiduOCR.sha2'


local accessKeyId =		"a3d03a3fb3d643638693bedfb9e32920"
local secretAccessKey =	"6f93a6822c0d47f3a7c0717e0d1baa58"

local BCE_AUTH_VERSION = 	"bce-auth-v1"
local BCE_PREFIX = 			'x-bce-'

local function belongvalue(aimTable,aim)--判断目标变量在表中是否存在
	for _,v in pairs(aimTable) do
		if aim==v then
			return true
		end
	end
	return false
end

local function belongHeader(header)
	header = string.lower(header:trim())	--将Header的名字变成全小写,去掉开头和结尾的空白字符
	
	if header=="host" then
		return true
	end
	
	local prefix = string.sub(header, 1, string.len(BCE_PREFIX))
    if prefix == BCE_PREFIX then
        return true
    else
        return false
    end
end

local function signHeaders(headers)
	local tbl = {}
	for k, v in pairs(headers) do
        if string.len(string.trim(v)) > 0 then
            if belongHeader(k) then
                tbl[k] = v
            end
        end
    end
    return tbl
end

function table.keys(t)
    local keys = {}
    for k, _ in pairs(t) do
        keys[#keys + 1] = k
    end
    return keys
end

function string.trim(s)
	s=tostring(s)
	return s:match'^%s*(.*%S)'  or ''
end

local function urlEncode(s)
    local except = {'-', '.', '_', '~'}
    s = string.gsub(s,"([^%w%.%- ])", function(w)
        if belongvalue(except,w) then return w end
			return string.format("%%%02X",string.byte(w))
    end)
    return (string.gsub(s," ","+"))
end

local function urlEncodeExceptSlash(s)
    return (string.gsub(urlEncode(s),'%%2F',"/"))
end

local function makeCanonicalQueryString(QueryParameter)
    if not QueryParameter then
        return " "
    end
	
	local QueryParameterString = {}
	for k,v in pairs(QueryParameter) do
		if string.find(k, "Authorization") == nil then --对于key是authorization，直接忽略。
			if v then 
				--对于key=value的项，转换为 UriEncode(key) + "=" + UriEncode(value) 的形式
				QueryParameterString[#QueryParameterString+1]=urlEncode(k) .. "=" .. urlEncode(v)
			else
				--对于只有key的项，转换为UriEncode(key) + "="的形式。
				QueryParameterString[#QueryParameterString+1]=urlEncode(k) .. "="
			end
		end
	end
	
	table.sort(QueryParameterString)
	
	return table.concat(QueryParameterString, '&')
end

local function makeCanonicalHeaders(Headers)
    if not Headers then
        return ''
    end
	
	local HeaderStrings = {}
	
	for k,v in pairs(Headers) do
		if v == nil then --为空字符串的Header忽略
			v = ''
		end	
		HeaderStrings[#HeaderStrings+1]=urlEncode(string.lower(k:trim())) .. ':' .. urlEncode(v:trim())
	end
	
	table.sort(HeaderStrings)	--照字典序进行排序
	
	return table.concat(HeaderStrings, "\n")	--用\n符号连接
end

local function sign(httpMethod, path, headers, params)
    -- 有效时间
    local expirationInSeconds = 1800
	
    local timestamp            = os.date("!%Y-%m-%dT%H:%M:%SZ")
    local authString           = BCE_AUTH_VERSION .. '/' .. accessKeyId .. '/' .. timestamp .. '/' .. expirationInSeconds
	local signingKey           = sha2.hmac(sha2.sha256,secretAccessKey,authString)
    local canonicalURI         = urlEncodeExceptSlash(path)
    local canonicalQueryString = makeCanonicalQueryString(params);
    local headersToSign        = signHeaders(headers)
    local canonicalHeader      = makeCanonicalHeaders(headersToSign)

    headersToSign = table.keys(headersToSign)
    table.sort(headersToSign)

    -- 整理headersToSign，以';'号连接
    local signedHeaders = string.lower((table.concat(headersToSign, ';')))
	
    -- 组成标准请求串
    local canonicalRequest = httpMethod .. "\n" .. canonicalURI .. "\n" .. canonicalQueryString .. "\n" .. canonicalHeader
    local signature = sha2.hmac(sha2.sha256,signingKey,canonicalRequest)
    local authorizationHeader = authString .. '/' .. signedHeaders .. '/' .. signature
	
    return authorizationHeader
end

return sign