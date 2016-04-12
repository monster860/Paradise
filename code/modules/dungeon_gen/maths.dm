// This shit is ported from https://github.com/Yonaba/delaunay

/proc/quat_cross(a, b, c)
	return sqrt((a + b + c) * (a + b - c) * (a - b + c) * (-a + b + c))

/proc/cross_product(var/datum/math/point/a, var/datum/math/point/b, var/datum/math/point/c)
	var/x1 = b.x - a.x
	var/x2 = c.x - b.x
	var/y1 = b.y - a.y
	var/y2 = c.y - b.y
	return (x1 * y2) - (y1 * x2)

/proc/is_flat_angle(a, b, c)
	return (cross_product(a, b, c) == 0)

/datum/math
	var/id = 0
	var/meta
	var/name

/datum/math/proc/eq(b)
	return 0

/datum/math/point
	var/x
	var/y

/datum/math/point/New(x = 0, y = 0)
	src.x = x
	src.y = y

/datum/math/point/proc/dist2(var/datum/math/point/p2)
	var/dx = x - p2.x
	var/dy = y - p2.y
	return (dx * dx) + (dy * dy)

/datum/math/point/proc/dist(p2)
	return sqrt(dist2(p2))

/datum/math/point/eq(var/datum/math/point/b)
	return b.x == x && b.y == y

/datum/math/point/proc/in_circle(var/datum/math/circle/c)
	var/dx = c.x - x
	var/dy = c.y - y
	return ((dx * dx) + (dy * dy)) <= (c.r * c.r)

/datum/math/edge
	var/datum/math/point/p1
	var/datum/math/point/p2
	var/len_val = 0

/datum/math/edge/New(p1, p2)
	src.p1 = p1
	src.p2 = p2
	len_val = len()
	if(len_val < 10)
		name = "000[len_val]"
	else if(len_val < 100)
		name = "00[len_val]"
	else if(len_val < 1000)
		name = "0[len_val]"
	else
		name = "[len_val]"

/datum/math/edge/proc/same(var/datum/math/edge/b)
	return (p1.eq(b.p1) && p2.eq(b.p2)) || (p1.eq(b.p2) && p2.eq(b.p1))

/datum/math/edge/proc/len()
	return p1.dist(p2)

/datum/math/edge/proc/midpoint()
	var/x = (p1.x + p2.x) / 2
	var/y = (p1.y + p2.y) / 2
	return new /datum/math/point(x, y)

/datum/math/triangle
	var/datum/math/point/p1
	var/datum/math/point/p2
	var/datum/math/point/p3
	var/datum/math/edge/e1
	var/datum/math/edge/e2
	var/datum/math/edge/e3

/datum/math/triangle/New(p1, p2, p3)
	src.p1 = p1
	src.p2 = p2
	src.p3 = p3
	src.e1 = new(p1, p2)
	src.e2 = new(p2, p3)
	src.e3 = new(p3, p1)
	if(is_flat_angle(p1, p2, p3))
		world << "\red ERROR - FLAT ANGLE"

/datum/math/triangle/proc/is_cw()
	return cross_product(p1, p2, p3) < 0

/datum/math/triangle/proc/is_ccw()
	return cross_product(p1, p2, p3) > 0

/datum/math/triangle/proc/center()
	var/x = (p1.x + p2.x + p3.x) / 2
	var/y = (p1.y + p2.y + p3.y) / 2
	return new /datum/math/point(x, y)

/datum/math/triangle/proc/circumcircle()
	var/datum/math/point/P = circumcenter()
	var/r = circumradius()
	return new /datum/math/circle(P.x, P.y, r)

/datum/math/triangle/proc/circumcenter()
	var/A = p2.x - p1.x
	var/B = p2.y - p1.y
	var/C = p3.x - p1.x
	var/D = p3.y - p1.y
	var/E = A * (p1.x + p2.x) + B * (p1.y + p2.y)
	var/F = C * (p1.x + p3.x) + D * (p1.y + p3.y)
	var/G = 2.0 * (A * (p3.y - p2.y) - B * (p3.x - p2.x))
	if(G == 0)
		return new /datum/math/point(0,0)
	var/x = (D * E - B * F) / G
	var/y = (A * F - C * E) / G
	return new /datum/math/point(x,y)

/datum/math/triangle/proc/circumradius()
	var/a = e1.len()
	var/b = e2.len()
	var/c = e3.len()
	var/cross = quat_cross(a, b, c)
	if(cross == 0)
		return 0
	return ((a * b * c) / cross)

/datum/math/triangle/proc/area()
	return quat_cross(e1.len(), e2.len(), e3.len()) / 4

/datum/math/triangle/proc/in_circumcircle(var/datum/math/point/P)
	return P.in_circle(circumcircle())

/datum/math/circle
	var/x
	var/y
	var/r

/datum/math/circle/New(x, y, r)
	src.x = x
	src.y = y
	src.r = r