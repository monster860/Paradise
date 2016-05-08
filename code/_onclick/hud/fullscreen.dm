#define FULLSCREEN_LAYER 18
#define DAMAGE_LAYER FULLSCREEN_LAYER + 0.1
#define BLIND_LAYER DAMAGE_LAYER + 0.1
#define CRIT_LAYER BLIND_LAYER + 0.1

/mob
	var/list/screens = list()

/mob/proc/overlay_fullscreen(category, type, severity)
	var/obj/screen/fullscreen/screen
	if(screens[category])
		screen = screens[category]
		if(screen.type != type)
			clear_fullscreen(category, FALSE)
			return .()
		else if(!severity || severity == screen.severity)
			return null
	else
		screen = new type

	screen.icon_state = "[initial(screen.icon_state)][severity]"
	screen.severity = severity

	screens[category] = screen
	if(client)
		client.screen += screen
	return screen

/mob/proc/clear_fullscreen(category, animated = 10)
	var/obj/screen/fullscreen/screen = screens[category]
	if(!screen)
		return

	screens -= category

	if(animated)
		spawn(0)
			animate(screen, alpha = 0, time = animated)
			sleep(animated)
			if(client)
				client.screen -= screen
			qdel(screen)
	else
		if(client)
			client.screen -= screen
		qdel(screen)

/mob/proc/clear_fullscreens()
	for(var/category in screens)
		clear_fullscreen(category)

/datum/hud/proc/reload_fullscreen()
	var/list/screens = mymob.screens
	for(var/category in screens)
		mymob.client.screen |= screens[category]

/obj/screen/fullscreen
	icon = 'icons/mob/screen_full.dmi'
	icon_state = "default"
	screen_loc = "CENTER-7,CENTER-7"
	layer = FULLSCREEN_LAYER
	mouse_opacity = 0
	var/severity = 0

/obj/screen/fullscreen/Destroy()
	..()
	severity = 0
	return QDEL_HINT_HARDDEL_NOW

/obj/screen/fullscreen/brute
	icon_state = "brutedamageoverlay"
	layer = DAMAGE_LAYER

/obj/screen/fullscreen/oxy
	icon_state = "oxydamageoverlay"
	layer = DAMAGE_LAYER

/obj/screen/fullscreen/crit
	icon_state = "passage"
	layer = CRIT_LAYER

/obj/screen/fullscreen/blind
	icon_state = "blackimageoverlay"
	layer = BLIND_LAYER

/obj/screen/fullscreen/impaired
	icon_state = "impairedoverlay"

/obj/screen/fullscreen/blurry
	icon = 'icons/mob/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "blurry"

/obj/screen/fullscreen/flash
	icon = 'icons/mob/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "flash"

/obj/screen/fullscreen/flash/noise
	icon = 'icons/mob/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "noise"

/obj/screen/fullscreen/high
	icon = 'icons/mob/screen_gen.dmi'
	screen_loc = "WEST,SOUTH to EAST,NORTH"
	icon_state = "druggy"

/obj/screen/fullscreen/pmaster_c_default
	plane = PLANE_LIGHTING_C
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_MULTIPLY
	screen_loc = "WEST,SOUTH to EAST,NORTH"

/obj/screen/fullscreen/pmaster_g_default
	plane = PLANE_LIGHTING_G
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_OVERLAY
	color = "#000000"
	screen_loc = "WEST,SOUTH to EAST,NORTH"

/obj/screen/fullscreen/pmaster_c_shadowling
	plane = PLANE_LIGHTING_C
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_ADD
	color = "#E6E6E6" // 90%
	screen_loc = "WEST,SOUTH to EAST,NORTH"

/obj/screen/fullscreen/pmaster_g_shadowling
	plane = PLANE_LIGHTING_G
	appearance_flags = PLANE_MASTER
	blend_mode = BLEND_ADD
	color = list(	0,	0,	0,	0.9, 
					0,	0,	0,	0,
					0,	0,	0,	0,
					0,	0,	0,	-0.9,
					1,	1,	1,	0)
	screen_loc = "WEST,SOUTH to EAST,NORTH"

#undef FULLSCREEN_LAYER
#undef BLIND_LAYER
#undef DAMAGE_LAYER
#undef CRIT_LAYER
