--处理多点找色返回值test
abs=math.abs
local new = {}
for i = 1, #Table do
	new[i] = {}
	for k = 1, #Table do
		if k ~= i then
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

Print(retPoint)