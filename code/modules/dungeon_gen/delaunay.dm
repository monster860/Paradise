// This shit is ported from https://github.com/Yonaba/delaunay

#define CONVEX_MULT 10

/proc/delaunay(var/list/points)
	var/list/vertices = list()
	vertices += points
	if(vertices.len < 3)
		return
	if(vertices.len == 3)
		return new /datum/math/triangle(vertices[1], vertices[2], vertices[3])

	var/datum/math/point/temp = vertices[1]
	var/minX = temp.x
	var/minY = temp.y
	var/maxX = temp.x
	var/maxY = temp.y

	var/index = 1
	for(var/datum/math/point/P in vertices)
		P.id = index
		index++
		if(P.x < minX)
			minX = P.x
		if(P.y < minY)
			minY = P.y
		if(P.x > maxX)
			maxX = P.x
		if(P.y > maxY)
			maxY = P.y

	var/dx = (maxX - minX) * CONVEX_MULT
	var/dy = (maxY - minY) * CONVEX_MULT
	var/deltaMax = max(dx, dy)
	var/midX = (maxX + minX) * 0.5
	var/midY = (maxY + minY) * 0.5

	var/beginLen = vertices.len

	var/datum/math/point/p1 = new(midX - (2 * deltaMax), midY - deltaMax)
	var/datum/math/point/p2 = new(midX, midY + (2 * deltaMax))
	var/datum/math/point/p3 = new(midX + (2 * deltaMax), midY - deltaMax)
	p1.id = beginLen + 1
	p2.id = beginLen + 2
	p3.id = beginLen + 3
	vertices += p1
	vertices += p2
	vertices += p3

	//world << "[midX], [midY] ([deltaMax])"

	var/list/triangles = list()
	triangles += new /datum/math/triangle(p1, p2, p3)

	for(var/I in 1 to beginLen)
		var/list/edges = list()
		var/datum/math/point/P = vertices[I]
		//world << "Processing ([P.x], [P.y])"
		for(var/datum/math/triangle/T in triangles)
			if(T.in_circumcircle(P))
				edges += T.e1
				edges += T.e2
				edges += T.e3
				triangles -= T
				//world << "Removing ([T.p1.x], [T.p1.y]) ([T.p2.x], [T.p2.y]) ([T.p3.x], [T.p3.y])"

		for(var/datum/math/edge/E1 in edges)
			for(var/datum/math/edge/E2 in edges)
				if(E1 == E2)
					continue
				if(E1.same(E2))
					edges -= E1
					edges -= E2

		for(var/datum/math/edge/E1 in edges)
			//world << "Edge: ([E1.p1.x],[E1.p1.y])-([E1.p2.x],[E1.p2.y])"

		for(var/datum/math/edge/E in edges)
			var/datum/math/triangle/T = new /datum/math/triangle(E.p1, E.p2, P)
			//world << "Creating ([T.p1.x], [T.p1.y]) ([T.p2.x], [T.p2.y]) ([T.p3.x], [T.p3.y])"
			triangles += T

	for(var/datum/math/triangle/T in triangles)
		if(T.p1.id > beginLen || T.p2.id > beginLen || T.p3.id > beginLen)
			triangles -= T

	//world << "Done"

	return triangles

/proc/delaunay_edges(var/list/verts)
	var/list/tris = delaunay(verts)
	var/list/edges = list()
	for(var/datum/math/triangle/T in tris)
		edges += T.e1
		edges += T.e2
		edges += T.e3
	for(var/datum/math/edge/E1 in edges)
		for(var/datum/math/edge/E2 in edges)
			if(E1 == E2)
				continue
			if(E1.same(E2))
				edges -= E1
	return edges