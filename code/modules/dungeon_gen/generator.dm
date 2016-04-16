/obj/effect/spawner/dungeon
	var/list/pipe_spawners = list()

/obj/effect/spawner/dungeon/New()
	spawn(10)
		generate_dungeon()

/obj/effect/spawner/dungeon/proc/generate_dungeon()
	set background = 1
	var/list/rooms = list()
	var/centerx = x / 2
	var/centery = y / 2
	for(var/I in 1 to 200)
		var/x = rand(-20,20) + centerx
		var/y = rand(-20,20) + centery
		var/size = (rand(0,100) / 100)
		size = size * size * size
		size *= 7
		size += 2
		var/w = round(size)
		var/h = round(size) + rand(-2,2)
		if(h < 1)
			h = 1
		var/obj/effect/dungeon_room/S = new(x,y,w,h)
		S.z = z
		S.tag = 0
		if(w > 6)
			S.large = 1
		rooms += S
	//world << "Starting seperation"
	var/done = 1
	for(var/I in 1 to 1000)
		done = 1
		world << "Stepping"
		sleep(1)
		for(var/obj/effect/dungeon_room/A in rooms)
			var/dx = 0
			var/dy = 0
			var/hasIntersect = 0
			for(var/obj/effect/dungeon_room/B in rooms)
				if(A == B)
					continue
				if(A.intersects(B))
					hasIntersect = 1
					done = 0
					if(A.center_x() > B.center_x())
						dx++
					if(A.center_y() > B.center_y())
						dy++
					if(A.center_x() < B.center_x())
						dx--
					if(A.center_y() < B.center_y())
						dy--
			if(hasIntersect && dx == 0 && dy == 0)
				dx = rand(-10,10)
				dy = rand(-10,10)
			A.next_x = A.x + sign(dx) / 1
			A.next_y = A.y + sign(dy) / 1
			while(A.n_bottom() <= 1)
				A.next_y += 1
			while(A.n_left() <= 1)
				A.next_x += 1
			while(A.n_top() >= y)
				A.next_y -= 1
			while(A.n_right() >= x)
				A.next_x -= 1
			A.x = A.next_x
			A.y = A.next_y
		for(var/obj/effect/dungeon_room/A in rooms)
			A.x = A.next_x
			A.y = A.next_y
		if(done)
			break
	sleep(1)
	//world << "Triangulating"
	var/list/verts = list()
	var/room_type_index = 0
	for(var/obj/effect/dungeon_room/room in rooms)
		if(room.large)
			var/datum/math/point/P = new(room.center_x(),room.center_y())
			P.meta = room
			verts += P
			room_type_index++
			var/area/awaycontent/A = new()
			A.name = "Dungeon Room [rand(111,999)]"
			for(var/turf/T in block(locate(room.left(), room.bottom(), z), locate(room.right(), room.top(), z)))
				T = T.ChangeTurf(/turf/simulated/floor/plating)
				T.fullUpdateMineralOverlays()
				A.contents += T
			populate_large_room(room, room_type_index, z)
		room.invisibility = 101
	var/list/edges = delaunay_edges(verts)
	//world << "Triangulated"
	var/list/edges_used = list()
	var/list/edges_discarded = list()
	edges = sortList(edges)
	var/datum/disjoint_set/S = new(verts.len)
	for(var/datum/math/edge/E in edges)
		var/I1 = verts.Find(E.p1)
		var/I2 = verts.Find(E.p2)
		if(S.find(I1) == S.find(I2))
			edges_discarded |= E
		else
			edges_used |= E
			S.union(I1, I2)
	for(var/datum/math/edge/E in edges_discarded)
		if(prob(10))
			edges_discarded -= E
			edges_used |= E
	for(var/datum/math/edge/E in edges_used)
		//new /obj/line{color="#339933"}(E.p1.meta,E.p2.meta,"Line")
		connect_rooms(E, z)
	//for(var/datum/math/edge/E in edges_discarded)
	//	new /obj/line(E.p1.meta,E.p2.meta,"Line")
	for(var/obj/effect/dungeon_room/room in rooms)
		if(!room.marked)
			rooms -= room
			qdel(room)
			continue
		for(var/turf/T in block(locate(room.left(), room.bottom(), z), locate(room.right(), room.top(), z)))
			if(istype(T,/turf/simulated/mineral))
				T = T.ChangeTurf(/turf/simulated/floor/plating)
				T.fullUpdateMineralOverlays()
		room.marked = 0
	
	for(var/datum/math/edge/E in edges_used)
		gen_dungeon_doors(E, z)
	
	place_wallmounts(rooms)
	generate_maint_loot(rooms)
	
	prune_pipespawners()

/obj/effect/spawner/dungeon/proc/connect_rooms(var/datum/math/edge/E, var/z)
	var/datum/math/point/p1
	var/datum/math/point/p2
	if(prob(50))
		p1 = E.p1
		p2 = E.p2
	else
		p1 = E.p2
		p2 = E.p1
	world << "([p1.x],[p1.y])-([p2.x],[p1.y]), ([p2.x],[p1.y])-([p2.x],[p2.y])"
	var/list/platings = list()
	var/list/platings2 = list()
	
	for(var/turf/T in block(locate(p1.x,p1.y,z),locate(p2.x,p1.y,z)))
		for(var/obj/effect/dungeon_room/O in T.contents)
			O.marked = 1
			//O.invisibility = 0
		if(istype(T,/turf/simulated/mineral))
			T = T.ChangeTurf(/turf/simulated/floor/plating)
			T.fullUpdateMineralOverlays()
			platings += T
		pipe_spawners += new /obj/effect/spawner/pipes(T)
	if(p1.x > p2.x)
		platings = reverselist(platings)
	for(var/turf/T in block(locate(p2.x,p1.y,z),locate(p2.x,p2.y,z)))
		for(var/obj/effect/dungeon_room/O in T.contents)
			O.marked = 1
			//O.invisibility = 0
		if(istype(T, /turf/simulated/mineral))
			T = T.ChangeTurf(/turf/simulated/floor/plating)
			T.fullUpdateMineralOverlays()
			platings += T
		pipe_spawners += new /obj/effect/spawner/pipes(T)
	if(p1.y > p2.y)
		platings2 = reverselist(platings2)
	E.meta = platings + platings2

/obj/effect/spawner/dungeon/proc/populate_large_room(var/obj/effect/dungeon_room/R, var/type_index, var/z)
	switch(type_index)
		if(1) // Gateway Room
			var/turf/T = locate(R.center_x(), R.center_y(), z)
			var/obj/machinery/gateway/G = new(get_step(T, WEST))
			G.dir = WEST
			G = new(get_step(T, NORTHWEST))
			G.dir = NORTHWEST
			G = new(get_step(T, NORTH))
			G.dir = NORTH
			G = new(get_step(T, NORTHEAST))
			G.dir = NORTHEAST
			G = new(get_step(T, EAST))
			G.dir = EAST
			G = new(get_step(T, SOUTHEAST))
			G.dir = SOUTHEAST
			G = new(get_step(T, SOUTH))
			G.dir = SOUTH
			G = new(get_step(T, SOUTHWEST))
			G.dir = SOUTHWEST
			new /obj/machinery/gateway/centeraway(T)

/obj/effect/spawner/dungeon/proc/gen_dungeon_doors(var/datum/math/edge/E, var/z)
	var/list/platings = E.meta
	var/turf/T1
	var/turf/T2
	for(var/turf/T in platings)
		//world << "Plating\..."
		if((istype(get_step(T, NORTH), /turf/simulated/mineral) && istype(get_step(T, SOUTH), /turf/simulated/mineral)) || (istype(get_step(T, WEST), /turf/simulated/mineral) && istype(get_step(T, EAST), /turf/simulated/mineral)))
			if(!T1)
				T1 = T
			T2 = T
	if(T1 == T2)
		T2 = null
	if(T1 && !(/obj/machinery/door/airlock/glass_mining in T1.contents))
		new /obj/machinery/door/airlock/glass_mining(T1)
	if(T2 && !(/obj/machinery/door/airlock/glass_mining in T1.contents))
		new /obj/machinery/door/airlock/glass_mining(T2)

/obj/effect/spawner/dungeon/proc/place_wallmounts(var/list/rooms)
	for(var/obj/effect/dungeon_room/R in rooms)
		if(!R.large)
			continue
		var/list/possible_locs = list()
		var/list/north_wall = list()
		var/list/south_wall = list()
		var/list/west_wall = list()
		var/list/east_wall = list()
		for(var/turf/T in R.locs) // Requirements here is at least one adjacent solid turf.
			if(!istype(T, /turf/simulated/floor))
				continue
			if(istype(get_step(T, NORTH), /turf/simulated/mineral))
				north_wall += T
				possible_locs += T
			if(istype(get_step(T, SOUTH), /turf/simulated/mineral))
				south_wall += T
				possible_locs += T
			if(istype(get_step(T, WEST), /turf/simulated/mineral))
				west_wall += T
				possible_locs += T
			if(istype(get_step(T, EAST), /turf/simulated/mineral))
				east_wall += T
				possible_locs += T
		if(!possible_locs.len)
			continue
		
		if(north_wall.len && south_wall.len && prob(50))
			var/turf/T = pick_n_take(north_wall)
			possible_locs -= T
			var/obj/machinery/light/L = new(T)
			L.dir = NORTH
			T = pick(south_wall)
			L = new(T)
			L.dir = SOUTH
		else if(east_wall.len && west_wall.len)
			var/turf/T = pick_n_take(east_wall)
			possible_locs -= T
			var/obj/machinery/light/L = new(T)
			L.dir = EAST
			T = pick(west_wall)
			L = new(T)
			L.dir = WEST
		else // No opposing walls? Just put down one.
			var/turf/T = pick_n_take(possible_locs)
			var/obj/machinery/light/L = new(T)
			if(T in north_wall)
				L.dir = NORTH
				north_wall -= T
			if(T in south_wall)
				L.dir = SOUTH
				south_wall -= T
			if(T in east_wall)
				L.dir = EAST
				east_wall -= T
			if(T in west_wall)
				L.dir = WEST
				west_wall -= T
		
		if(!possible_locs.len)
			continue
		// APC
		var/turf/T = pick_n_take(possible_locs)
		var/the_dir
		if(T in north_wall)
			the_dir = NORTH
			north_wall -= T
		if(T in south_wall)
			the_dir = SOUTH
			south_wall -= T
		if(T in east_wall)
			the_dir = EAST
			east_wall -= T
		if(T in west_wall)
			the_dir = WEST
			west_wall -= T
		var/obj/machinery/power/apc/A = new(T, the_dir, 1)
		A.opened = 0
		A.operating = 1
		A.stat = 0
		A.init()
		var/p1x
		var/p2x
		var/p1y
		var/p2y
		if(prob(50))
			p1x = A.x
			p1y = A.y
			p2x = R.center_x()
			p2y = R.center_y()
		else
			p1x = R.center_x()
			p1y = R.center_y()
			p2x = A.x
			p2y = A.y
		for(var/turf/T2 in block(locate(p1x,p1y,R.z),locate(p2x,p1y,R.z)))
			pipe_spawners += new /obj/effect/spawner/pipes/cable(T2)
		for(var/turf/T2 in block(locate(p2x,p1y,R.z),locate(p2x,p2y,R.z)))
			pipe_spawners += new /obj/effect/spawner/pipes/cable(T2)
		for(var/obj/effect/spawner/pipes/S in A)
			if(S.cable)
				S.node = 1

/obj/effect/spawner/dungeon/proc/generate_maint_loot(var/list/rooms)
	var/list/possible_locs = list()
	for(var/obj/effect/dungeon_room/R)
		if(R.large)
			continue
		for(var/turf/T in R.locs)
			var/pipes = 0
			for(var/obj/effect/spawner/pipes/P in T.contents)
				pipes = 1
			if(pipes)
				continue
			if(istype(get_step(T, NORTH), /turf/simulated/mineral) && istype(get_step(T, SOUTH), /turf/simulated/mineral))
				continue // We're blocking a path.
			if(istype(get_step(T, WEST), /turf/simulated/mineral) && istype(get_step(T, EAST), /turf/simulated/mineral))
				continue // We're blocking a path.
			if(istype(get_step(T, WEST), /turf/simulated/mineral) || \
				istype(get_step(T, EAST), /turf/simulated/mineral) || \
				istype(get_step(T, NORTH), /turf/simulated/mineral) || \
				istype(get_step(T, SOUTH), /turf/simulated/mineral))
				possible_locs += T
		
	for(var/turf/T in possible_locs)
		if(!prob(30))
			continue
		var/containerType = pick(/obj/structure/closet,/obj/structure/rack,/obj/structure/table)
		new containerType(T)
		new /obj/effect/spawner/lootdrop/maintenance(T)

/obj/effect/spawner/dungeon/proc/prune_pipespawners()
	/*for(var/pipe_type in 3 to 3)
		// Step 1- tree-ify the networks
		var/datum/disjoint_set/DS = new(pipe_spawners.len)
		var/list/junctions = list()
		for(var/obj/effect/spawner/pipes/S in pipe_spawners)
			S.completed = list()
			S.junction = S.node
			S.edges = list()
		for(var/obj/effect/spawner/pipes/S in pipe_spawners)
			var/list/connected = S.get_connected(pipe_type)
			if(connected.len > 2)
				S.junction = 1
				junctions += S
			for(var/obj/effect/spawner/pipes/S2 in connected)
				S2.completed += S 
				S.completed += S2*/
			

/obj/effect/dungeon_room
	var/w
	var/h
	var/next_x
	var/next_y
	var/marked = 0
	var/large = 0

/obj/effect/dungeon_room/New(x,y,w,h)
	src.w = w
	src.h = h
	src.x = x
	src.y = y
	bound_width = w*32
	bound_height = h*32
		

/obj/effect/dungeon_room/proc/intersects(var/obj/effect/dungeon_room/B)
	return !(B.left() > right() \
		|| B.right() < left() \
		|| B.bottom() > top() \
		|| B.top() < bottom())

/obj/effect/dungeon_room/proc/bottom()
	return y

/obj/effect/dungeon_room/proc/top()
	return y + h - 1

/obj/effect/dungeon_room/proc/left()
	return x

/obj/effect/dungeon_room/proc/right()
	return x + w - 1

/obj/effect/dungeon_room/proc/center_x()
	return round(x + (w / 2))

/obj/effect/dungeon_room/proc/center_y()
	return round(y + (h / 2))

/obj/effect/dungeon_room/proc/n_bottom()
	return next_y

/obj/effect/dungeon_room/proc/n_top()
	return next_y + h

/obj/effect/dungeon_room/proc/n_left()
	return next_x

/obj/effect/dungeon_room/proc/n_right()
	return next_x + w

/datum/pipe_spawner_edge
	var/list/spawners
	var/obj/effect/spawner/pipes/P1
	var/obj/effect/spawner/pipes/P2