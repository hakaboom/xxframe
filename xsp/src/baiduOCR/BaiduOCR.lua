local sign=require("baiduOCR.Authorization")
local baiduOCR = {}

local function belongkey(aimTable,aim)--判断目标变量在表中是否存在
	for k,_ in pairs(aimTable) do
		if aim==k then
			return true
		end
	end
	return false
end

local function snapshotRead(rect)
	local filename = xmod.getPublicPath() .. '/ocr.png'
	screen.snapshot(filename,rect)
	local file = io.open(filename, 'r')
	local retbyte = file:read("*a")
	file:close()
	return retbyte
end

local function urlEncode(s)
    s = string.gsub(s, "([^%w%.%- ])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
    return (string.gsub(s, " ", "+"))
end

function baiduOCR.getText(rect)
	local imgRaw    = snapshotRead(rect)
	local imgBase64 = require('crypto').base64Encode(imgRaw)
	local imgData   = urlEncode(imgBase64)

	if imgData == nil or #imgData <= 0 then return "" end

	local http = require'socket.http'
	local json=require("cjson")
	local post_data = 'image='..imgData
	local params = {}
	local response_body = {}
	local method    = "POST"
	local url       = 'http://aip.baidubce.com/rest/2.0/ocr/v1/general_basic'
	local path      = '/rest/2.0/ocr/v1/general_basic'
	local headers = {
			['host']           = 'aip.baidubce.com',
	        ['Content-Type']   = 'application/x-www-form-urlencoded',
	        ['Content-Length'] = #post_data,
	}	
	local sign = sign(method, path, headers, params)
	headers['Authorization'] = sign
	local res, code = http.request {  
	    url     = url,
	    method  = method,
	    headers = headers,
	    source  = ltn12.source.string(post_data),
	    sink    = ltn12.sink.table(response_body)
	}

	if res == 1 and #response_body > 0 then
		local data = json.decode(response_body[1])
		if belongkey(data,'words_result') and #data['words_result'] > 0 then
			local text = data['words_result'][1]['words']
			return text
		end
	end

	return ""
end

return baiduOCR