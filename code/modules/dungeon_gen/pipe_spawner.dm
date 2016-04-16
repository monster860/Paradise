var/global/list/pipe_spawner_exits = list(1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4)
var/global/list/pipe_spawner_dirs = list(NORTH, SOUTH, NORTH, EAST, NORTHEAST, SOUTHEAST, WEST, WEST, NORTHWEST, SOUTHWEST, EAST, EAST, SOUTH, NORTH, NORTH)
var/global/list/pipe_spawner_cables1 = list("0-1", "0-2", "1-2", "0-4", "1-4", "2-4", "1-2", "0-8", "1-8", "2-8", "1-2", "4-8", "4-8", "4-8", "0-1")
var/global/list/pipe_spawner_cables2 = list(null, null, null, null, null, null, "2-4", null, null, null, "2-8", null, "1-8", "2-4", "0-2")
var/global/list/pipe_spawner_cables3 = list(null, null, null, null, null, null, "1-4", null, null, null, "1-8", null, "1-4", "2-8", "0-4")
var/global/list/pipe_spawner_cables4 = list(null, null, null, null, null, null, null, null, null, null, null, null, null, null, "0-8")

/obj/effect/spawner/pipes
	var/scrubbers = 1
	var/supply = 1
	var/cable = 1
	var/dummy = 0
	
	var/marked = 0
	var/node = 0
	var/obj/effect/spawner/dungeon/generator
	var/list/completed = list()
	var/list/edges = list()
	var/junction = 0

/obj/effect/spawner/pipes/New(turf/loc, G)
	..()
	generator = G
	if(!dummy)
		for(var/obj/effect/spawner/pipes/spawner in loc.contents)
			if(spawner != src)
				if(spawner.scrubbers) // We don't need duplicates here.
					scrubbers = 0
				if(spawner.supply)
					supply = 0
				if(spawner.cable)
					cable = 0
		if (!scrubbers && !supply && !cable)
			qdel(src)
			return
		spawn(50)
			do_spawn()
	spawn(100)
		qdel(src)

/obj/effect/spawner/pipes/Destroy()
	if(generator && istype(generator) && generator.pipe_spawners && islist(generator.pipe_spawners))
		generator.pipe_spawners -= src
	generator = null
	scrubbers = 0
	supply = 0
	cable = 0
	return ..()

/obj/effect/spawner/pipes/proc/do_spawn()
	if(scrubbers)
		world << "Spawning pipes"
		var/dirs = get_connected_dirs(1)
		if(dirs == 0)
			return
		var/obj/machinery/atmospherics/pipe/P
		var/pipe_type
		switch(pipe_spawner_exits[dirs])
			if(1)
				pipe_type = /obj/machinery/atmospherics/pipe/cap/hidden/scrubbers
			if(2)
				pipe_type = /obj/machinery/atmospherics/pipe/simple/hidden/scrubbers
			if(3)
				pipe_type = /obj/machinery/atmospherics/pipe/manifold/hidden/scrubbers
			if(4)
				pipe_type = /obj/machinery/atmospherics/pipe/manifold4w/hidden/scrubbers
		P = new pipe_type(get_turf(src))
		P.dir = pipe_spawner_dirs[dirs]
		P.initialize_directions = dirs
		spawn(40)
			P.initialize()
	if(supply)
		world << "Spawning pipes"
		var/dirs = get_connected_dirs(2)
		if(dirs == 0)
			return
		var/obj/machinery/atmospherics/pipe/P
		var/pipe_type
		switch(pipe_spawner_exits[dirs])
			if(1)
				pipe_type = /obj/machinery/atmospherics/pipe/cap/hidden/supply
			if(2)
				pipe_type = /obj/machinery/atmospherics/pipe/simple/hidden/supply
			if(3)
				pipe_type = /obj/machinery/atmospherics/pipe/manifold/hidden/supply
			if(4)
				pipe_type = /obj/machinery/atmospherics/pipe/manifold4w/hidden/supply
		P = new pipe_type(get_turf(src))
		P.dir = pipe_spawner_dirs[dirs]
		P.initialize_directions = dirs
		spawn(40)
			P.initialize()
	if(cable)
		var/dirs = get_connected_dirs(3)
		var/obj/structure/cable/C
		if(pipe_spawner_cables1[dirs])
			C = new(loc)
			C.icon_state = pipe_spawner_cables1[dirs]
			var/dash = findtext(C.icon_state, "-")
			C.d1 = text2num(copytext(C.icon_state, 1, dash) )
			C.d2 = text2num(copytext(C.icon_state, dash+1) )
		if(pipe_spawner_cables2[dirs])
			C = new(loc)
			C.icon_state = pipe_spawner_cables2[dirs]
			var/dash = findtext(C.icon_state, "-")
			C.d1 = text2num(copytext(C.icon_state, 1, dash) )
			C.d2 = text2num(copytext(C.icon_state, dash+1) )
		if(pipe_spawner_cables3[dirs])
			C = new(loc)
			C.icon_state = pipe_spawner_cables3[dirs]
			var/dash = findtext(C.icon_state, "-")
			C.d1 = text2num(copytext(C.icon_state, 1, dash) )
			C.d2 = text2num(copytext(C.icon_state, dash+1) )
		if(pipe_spawner_cables4[dirs])
			C = new(loc)
			C.icon_state = pipe_spawner_cables4[dirs]
			var/dash = findtext(C.icon_state, "-")
			C.d1 = text2num(copytext(C.icon_state, 1, dash) )
			C.d2 = text2num(copytext(C.icon_state, dash+1) )

/obj/effect/spawner/pipes/proc/get_connected_dirs(var/kind)
	var/dirs
	for(var/cdir in cardinal)
		for(var/obj/effect/spawner/pipes/S in get_step(src, cdir))
			if(has_kind(kind) && S.has_kind(kind))
				dirs |= cdir
	return dirs

/obj/effect/spawner/pipes/proc/get_connected(var/kind)
	var/list/connected = list()
	for(var/cdir in cardinal)
		for(var/obj/effect/spawner/pipes/S in get_step(src, cdir))
			if(has_kind(kind) && S.has_kind(kind))
				connected += S
	return connected

/obj/effect/spawner/pipes/proc/has_kind(var/kind)
	return (kind == 1 && scrubbers) || (kind == 2 && supply) || (kind == 3 && cable)

/obj/effect/spawner/pipes/proc/remove_kind(var/kind)
	if(kind == 1)
		scrubbers = 0
	if(kind == 2)
		supply = 0
	if(kind == 3)
		cable = 0

/obj/effect/spawner/pipes/scrubbers
	scrubbers = 1
	supply = 0
	cable = 0
/obj/effect/spawner/pipes/scrubbers/dummy
	dummy = 1
/obj/effect/spawner/pipes/supply
	scrubbers = 0
	supply = 1
	cable = 0
/obj/effect/spawner/pipes/supply/dummy
	dummy = 1
/obj/effect/spawner/pipes/cable
	scrubbers = 0
	supply = 0
	cable = 1
/obj/effect/spawner/pipes/cable/dummy
	dummy = 1
