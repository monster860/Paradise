/turf/space
	icon = 'icons/turf/space.dmi'
	name = "\proper space"
	icon_state = "0"
	dynamic_lighting = 0
	luminosity = 1

	temperature = TCMB
	thermal_conductivity = OPEN_HEAT_TRANSFER_COEFFICIENT
	heat_capacity = 700000

	var/destination_z
	var/destination_x
	var/destination_y

/turf/space/New()
	. = ..()
	if(!global_space_area)
		global_space_area = new /area/space()
		global_space_area.white_overlay = image(loc=global_space_area, icon='icons/turf/space.dmi', icon_state="white")
		global_space_area.white_overlay.plane = SPACE_WHITE_PLANE
	if(istype(loc,/area/space))
		global_space_area.contents += src
	else
		var/area/A = loc
		if(!A.white_overlay)
			A.white_overlay = image(loc=A, icon='icons/turf/space.dmi', icon_state="white")
			A.white_overlay.plane = SPACE_WHITE_PLANE
			for(var/client/C in parallax_on_clients)
				C.images |= A.white_overlay

	if(!istype(src, /turf/space/transit))
		plane = SPACE_TURF_PLANE
		icon_state = "[((x + y) ^ ~(x * y) + z) % 25]"
	update_starlight()

/turf/space/Destroy()
	return QDEL_HINT_LETMELIVE

/turf/space/proc/update_starlight()
	if(!config.starlight)
		return
	if(locate(/turf/simulated) in orange(src,1))
		set_light(config.starlight)
	else
		set_light(0)

/turf/space/attackby(obj/item/C as obj, mob/user as mob, params)
	..()
	if(istype(C, /obj/item/stack/rods))
		var/obj/item/stack/rods/R = C
		var/obj/structure/lattice/L = locate(/obj/structure/lattice, src)
		if(L)
			if(R.use(1))
				user << "<span class='notice'>You begin constructing catwalk...</span>"
				playsound(src, 'sound/weapons/Genhit.ogg', 50, 1)
				qdel(L)
				ChangeTurf(/turf/simulated/floor/plating/airless/catwalk)
			else
				user << "<span class='warning'>You need two rods to build a catwalk!</span>"
			return
		if(R.use(1))
			user << "<span class='notice'>Constructing support lattice...</span>"
			playsound(src, 'sound/weapons/Genhit.ogg', 50, 1)
			ReplaceWithLattice()
		else
			user << "<span class='warning'>You need one rod to build a lattice.</span>"
		return

	if(istype(C, /obj/item/stack/tile/plasteel))
		var/obj/structure/lattice/L = locate(/obj/structure/lattice, src)
		if(L)
			var/obj/item/stack/tile/plasteel/S = C
			if(S.use(1))
				qdel(L)
				playsound(src, 'sound/weapons/Genhit.ogg', 50, 1)
				user << "<span class='notice'>You build a floor.</span>"
				ChangeTurf(/turf/simulated/floor/plating)
			else
				user << "<span class='warning'>You need one floor tile to build a floor!</span>"
		else
			user << "<span class='warning'>The plating is going to need some support! Place metal rods first.</span>"

/turf/space/Entered(atom/movable/A as mob|obj)
	..()
	if ((!(A) || src != A.loc))
		return

	if(destination_z)
		A.x = destination_x
		A.y = destination_y
		A.z = destination_z

		if(isliving(A))
			var/mob/living/L = A
			if(L.pulling)
				var/turf/T = get_step(L.loc,turn(A.dir, 180))
				L.pulling.loc = T

		//now we're on the new z_level, proceed the space drifting
		sleep(0)//Let a diagonal move finish, if necessary
		A.newtonian_move(A.inertia_dir)

/turf/space/proc/Sandbox_Spacemove(atom/movable/A as mob|obj)
	var/cur_x
	var/cur_y
	var/next_x
	var/next_y
	var/target_z
	var/list/y_arr

	if(src.x <= 1)
		if(istype(A, /obj/effect/meteor)||istype(A, /obj/effect/space_dust))
			qdel(A)
			return

		var/list/cur_pos = src.get_global_map_pos()
		if(!cur_pos) return
		cur_x = cur_pos["x"]
		cur_y = cur_pos["y"]
		next_x = (--cur_x||global_map.len)
		y_arr = global_map[next_x]
		target_z = y_arr[cur_y]
/*
		//debug
		world << "Src.z = [src.z] in global map X = [cur_x], Y = [cur_y]"
		world << "Target Z = [target_z]"
		world << "Next X = [next_x]"
		//debug
*/
		if(target_z)
			A.z = target_z
			A.x = world.maxx - 2
			spawn (0)
				if ((A && A.loc))
					A.loc.Entered(A)
	else if (src.x >= world.maxx)
		if(istype(A, /obj/effect/meteor))
			qdel(A)
			return

		var/list/cur_pos = src.get_global_map_pos()
		if(!cur_pos) return
		cur_x = cur_pos["x"]
		cur_y = cur_pos["y"]
		next_x = (++cur_x > global_map.len ? 1 : cur_x)
		y_arr = global_map[next_x]
		target_z = y_arr[cur_y]
/*
		//debug
		world << "Src.z = [src.z] in global map X = [cur_x], Y = [cur_y]"
		world << "Target Z = [target_z]"
		world << "Next X = [next_x]"
		//debug
*/
		if(target_z)
			A.z = target_z
			A.x = 3
			spawn (0)
				if ((A && A.loc))
					A.loc.Entered(A)
	else if (src.y <= 1)
		if(istype(A, /obj/effect/meteor))
			qdel(A)
			return
		var/list/cur_pos = src.get_global_map_pos()
		if(!cur_pos) return
		cur_x = cur_pos["x"]
		cur_y = cur_pos["y"]
		y_arr = global_map[cur_x]
		next_y = (--cur_y||y_arr.len)
		target_z = y_arr[next_y]
/*
		//debug
		world << "Src.z = [src.z] in global map X = [cur_x], Y = [cur_y]"
		world << "Next Y = [next_y]"
		world << "Target Z = [target_z]"
		//debug
*/
		if(target_z)
			A.z = target_z
			A.y = world.maxy - 2
			spawn (0)
				if ((A && A.loc))
					A.loc.Entered(A)

	else if (src.y >= world.maxy)
		if(istype(A, /obj/effect/meteor)||istype(A, /obj/effect/space_dust))
			qdel(A)
			return
		var/list/cur_pos = src.get_global_map_pos()
		if(!cur_pos) return
		cur_x = cur_pos["x"]
		cur_y = cur_pos["y"]
		y_arr = global_map[cur_x]
		next_y = (++cur_y > y_arr.len ? 1 : cur_y)
		target_z = y_arr[next_y]
/*
		//debug
		world << "Src.z = [src.z] in global map X = [cur_x], Y = [cur_y]"
		world << "Next Y = [next_y]"
		world << "Target Z = [target_z]"
		//debug
*/
		if(target_z)
			A.z = target_z
			A.y = 3
			spawn (0)
				if ((A && A.loc))
					A.loc.Entered(A)
	return

/turf/space/singularity_act()
	return

/turf/space/can_have_cabling()
	return 0