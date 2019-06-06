if not rawget(_G, 'xmod') then
	error("the 'xmod' not find")
end
-- xmod > v2.0.249
-- v1.4.0
--  框架手册			 https://www.zybuluo.com/hakaboom/note/1370480
--	叉叉2.0开发手册   https://www.zybuluo.com/xxzhushou/note/1271276
--	lua 5.3手册	  	 https://cloudwu.github.io/lua53doc/contents.html
--	GitHub		   	 https://github.com/hakaboom/xxframe
--把自定义取色放到叉叉集成开发环境下的data.lua,可以直接覆盖,抓图的时候用Anchor
--打印函数为Print()
--初始化必须调用

require'base'require'Frame' --必须要的前置代码
DevScreen={	--开发分辨率
	Top=0,Bottom=0,Left=0,Right=0,
	Width=1920,Height=1080,
}
CurScreen={	--本机分辨率
	Top=0,Bottom=0,Left=0,Right=0,
	Width=2280,Height=1080,
}
_K=System:new(DevScreen,CurScreen,1,{x='width',y='height'},{x='width',y='height'})

a=point:new({x=100,y=100,Anchor='Middle'}):printXY()
multiPoint:new({
	{x=100,y=100},
	Anchor='Middle',
}):printXY()