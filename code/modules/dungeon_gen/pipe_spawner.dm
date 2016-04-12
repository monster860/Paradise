var/global/list/pipe_spawner_exits = list(1, 1, 2, 1, 2, 2, 3, 1, 2, 2, 3, 2, 3, 3, 4)
var/global/list/pipe_spawner_dirs = list(NORTH, SOUTH, NORTH, EAST, NORTHEAST, SOUTHEAST, WEST, WEST, NORTHWEST, SOUTHWEST, EAST, EAST, SOUTH, NORTH, NORTH)
/obj/effect/spawner/pipes
	var/scrubbers = 1
	var/supply = 1
	var/cable = 1

/obj/effect/spawner/pipes/New()
	for(var/obj/effect/spawner/pipes/spawner in loc.contents)
		if(spawner != src && spawner.type == type)
			qdel(src)
			return
	spawn(50)
		do_spawn()
	spawn(100)
		qdel(src)

/obj/effect/spawner/pipes/proc/do_spawn()
	if(scrubbers)
		world << "Spawning pipes"
		var/dirs
		for(var/cdir in cardinal)
			for(var/obj/effect/spawner/pipes/S in get_step(src,cdir))
				world << "Detected pipe spawner"
				if(S.scrubbers)
					if(cdir)
						dirs |= cdir
						world << "[cdir], added to [dirs]"
		if(dirs == 0)
			return
		var/obj/machinery/atmospherics/pipe/P
		var/pipe_type
		switch(pipe_spawner_exits[dirs])
			if(1)
				pipe_type =  /obj/machinery/atmospherics/pipe/cap/hidden/scrubbers
			if(2)
				pipe_type =  /obj/machinery/atmospherics/pipe/simple/hidden/scrubbers
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
		var/dirs
		for(var/cdir in cardinal)
			for(var/obj/effect/spawner/pipes/S in get_step(src,cdir))
				world << "Detected pipe spawner"
				if(S.supply)
					if(cdir)
						dirs |= cdir
						world << "[cdir], added to [dirs]"
		if(dirs == 0)
			return
		var/obj/machinery/atmospherics/pipe/P
		var/pipe_type
		switch(pipe_spawner_exits[dirs])
			if(1)
				pipe_type =  /obj/machinery/atmospherics/pipe/cap/hidden/supply
			if(2)
				pipe_type =  /obj/machinery/atmospherics/pipe/simple/hidden/supply
			if(3)
				pipe_type = /obj/machinery/atmospherics/pipe/manifold/hidden/supply
			if(4)
				pipe_type = /obj/machinery/atmospherics/pipe/manifold4w/hidden/supply
		P = new pipe_type(get_turf(src))
		P.dir = pipe_spawner_dirs[dirs]
		P.initialize_directions = dirs
		spawn(40)
			P.initialize()