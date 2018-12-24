local Map={
	{0,0,0,0,1,0,0},
	{5,2,2,0,0,0,0},
	{4,0,4,0,0,2,0},
	{0,0,0,0,0,2,2},
	{0,0,4,0,2,0,0},
}
function CalcF(point)
	point.F = point.G + point.H
end