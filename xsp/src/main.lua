if not rawget(_G, 'xmod') then
	error("the 'xmod' not find")
end
-- 交流群qq:952589499
-- v1.3.17
--  框架手册			 https://www.zybuluo.com/hakaboom/note/1370480
--	叉叉2.0开发手册   https://www.zybuluo.com/xxzhushou/note/1271276
--	lua 5.3手册	  	 https://cloudwu.github.io/lua53doc/contents.html
--	GitHub		   	 https://github.com/hakaboom/xxframe 
--把自定义取色放到叉叉集成开发环境下的data.lua,可以直接覆盖,抓图的时候用Anchor
--打印函数为Print()
--初始化必须调用
--	K=System:new(DevScreen,CurScreen,1,"Height","Height")
--	需要自己调用screen.init

require"base"require'Frame'require'const' --必须要的前置代码
DevScreen={	--开发分辨率
	Top=0,Bottom=0,Left=0,Right=0,
	Width=1920,Height=1080,
}
CurScreen={	--本机分辨率
	Top=0,Bottom=0,Left=93,Right=93,
	Width=2436,Height=1125,
}
_K=System:new(DevScreen,DevScreen,1,"Height","Height")

_K:keep(true)

rect=Rect(1,1,1,1)
local v = {
	{pos=Point(100,200),color=0xffffff},
	{pos=Point(200,200),color=0xffffff},
	{pos=Point(100,300),color=0xffffff},
	{pos=Point(500,200),color=0xffffff}
}
nowTime=os.milliTime()
for i = 1, 20000 do
	local x = screen.findColor(rect,v,100)
end
print((os.milliTime()-nowTime).."ms")
print(">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")

nowTime=os.milliTime()
for i=1,20000 do
	screen.matchColors(v)
end
print((os.milliTime()-nowTime).."ms")
