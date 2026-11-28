extends RefCounted
const SEED_FX = preload("res://scripts/anomalous_steel_fx_v180.gd")
const SEED_PARTICLES = preload("res://scripts/weapon_particle_paths_v244.gd")
const DIAGONAL = preload("res://scripts/ghost_diagonal_art_v247.gd")
const HAND = preload("res://scripts/dagger_thrust_v186.gd")
const PAINTED_V287 = preload("res://scripts/painted_relic_art_v287.gd")
const SERAPH = preload("res://assets/ui/weapons_v292/seraph_reaper_held.svg")
const MODELS: Dictionary = {
	"ivory_duelist_rapier_v286":preload("res://assets/ui/weapons_v286/ivory_duelist_rapier_v286.svg"),
	"nightglass_rapier_v286":preload("res://assets/ui/weapons_v286/nightglass_rapier_v286.svg"),
	"rosehook_bearded_axe_v286":preload("res://assets/ui/weapons_v286/rosehook_bearded_axe_v286.svg"),
	"ossuary_poleaxe_v286":preload("res://assets/ui/weapons_v286/ossuary_poleaxe_v286.svg"),
	"blackthorn_crossbow_v236":preload("res://assets/ui/weapons_v283/blackthorn_crossbow_v236.svg"),
	"silver_reliquary_crossbow_v236":preload("res://assets/ui/weapons_v283/silver_reliquary_crossbow_v236.svg"),
	"vesper_latch_crossbow_v237":preload("res://assets/ui/weapons_v283/vesper_latch_crossbow_v237.svg"),
	"ossuary_arbalest_v237":preload("res://assets/ui/weapons_v283/ossuary_arbalest_v237.svg"),
	"mourning_star_crossbow_v277":preload("res://assets/ui/weapons_v283/mourning_star_crossbow_v277.svg"),
	"vesper_rapier":preload("res://assets/ui/weapons_v283/vesper_rapier.svg"),
	"cathedral_rapier_v283":preload("res://assets/ui/weapons_v283/cathedral_rapier_v283.svg"),
	"moonneedle_rapier_v283":preload("res://assets/ui/weapons_v283/moonneedle_rapier_v283.svg"),
	"briar_hatchet_v283":preload("res://assets/ui/weapons_v283/briar_hatchet_v283.svg"),
	"gravecleaver_axe_v283":preload("res://assets/ui/weapons_v283/gravecleaver_axe_v283.svg"),
	"gallows_greataxe_v283":preload("res://assets/ui/weapons_v283/gallows_greataxe_v283.svg")
}

static func sequence(clip: String, face: String) -> Array[int]:
	var neutral: int = 1 if face=="back" else 0
	if clip.contains("_idle_"):
		return [neutral,neutral,neutral,neutral,neutral,neutral,neutral,neutral]
	if clip.contains("_walk_"):
		return [neutral,1,2,1,neutral,1,2,1]
	if clip.contains("rapier_"):
		return HAND.sequence(clip.contains("_heavy_"))
	if clip.contains("_heavy_"):
		return [neutral,2,2,3,3,5,6,neutral]
	return [neutral,1,2,3,5,6,7,neutral]

static func install(frames: SpriteFrames) -> void:
	for face in ["front","back","left","right"]:
		var source: String = "attack_unarmed_light_"+face
		if not frames.has_animation(source) or frames.get_frame_count(source)<8:
			continue
		for style in ["rapier","axe","seraph_scythe"]:
			var names: Array[String] = [style+"_idle_"+face,style+"_walk_"+face]
			if style=="rapier":
				names.append_array(["attack_rapier_pierce_"+face,"attack_rapier_heavy_pierce_"+face])
			else:
				names.append_array(["attack_"+style+"_light_"+face,"attack_"+style+"_heavy_"+face])
			for name in names:
				if frames.has_animation(name):
					continue
				frames.add_animation(name)
				# Support both the Godot 4.7 loop-mode API and older 4.x builds.
				var loops: bool = name.begins_with(style+"_")
				if frames.has_method("set_animation_loop_mode"):
					frames.call("set_animation_loop_mode",name,1 if loops else 0)
				else:
					frames.call("set_animation_loop",name,loops)
				frames.set_animation_speed(name,16.0 if name.begins_with("attack_") else 8.0)
				for index in sequence(name,face):
					frames.add_frame(name,frames.get_frame_texture(source,index))

static func span(clip: String, face: String, frame: int) -> PackedVector2Array:
	var n: int = clampi(frame,0,7)
	var rapier: bool = clip.contains("rapier_")
	if rapier and clip.begins_with("attack_"):
		var thrust: PackedVector2Array = HAND.single_span(face,n,clip.contains("_heavy_"))
		if thrust.size()==2:
			thrust[1]=thrust[0]+(thrust[1]-thrust[0]).normalized()*84.0
		return thrust
	var anchor: Vector2 = HAND.hand_anchor(face,sequence(clip,face)[n],0 if face=="left" else 1)
	if anchor==Vector2.INF:
		return PackedVector2Array()
	var axis: Vector2 = HAND.direction(face)
	if clip.begins_with("attack_"):
		var angles: Array[float] = [-1.22,-1.55,-0.98,-0.20,0.65,1.10,0.45,-0.55]
		if clip.contains("_heavy_"):
			angles.assign([-1.35,-1.90,-1.90,-1.05,0.0,1.25,0.80,-0.55])
		axis=axis.rotated(angles[n]*(-1.0 if face=="left" else 1.0))
	else:
		axis=Vector2(-0.45 if face=="left" else 0.45,-0.89).normalized()
	return PackedVector2Array([anchor,anchor+axis*(84.0 if rapier else 68.0)])

# The positive local X axis is always the head/blade, never the butt.
static func seraph_axis(heading: Vector2, progress: float, impact: float, left: bool) -> Vector2:
	var t: float = clampf(progress,0.0,1.0)
	var hit: float = clampf(impact,0.05,0.95)
	var angle: float = lerpf(-1.25,0.0,t/hit) if t<=hit else lerpf(0.0,1.12,(t-hit)/(1.0-hit))
	return heading.normalized().rotated(angle*(-1.0 if left else 1.0))

static func diagonal_attack_span(clip: String,frame: int) -> PackedVector2Array:
	var anchor: Vector2 = DIAGONAL.wrist(clip,frame)
	if anchor==Vector2.INF:
		return PackedVector2Array()
	var direction: String = DIAGONAL.diagonal_name(clip)
	var heading: Vector2 = DIAGONAL.heading_v294(direction)
	if heading.is_zero_approx():
		return PackedVector2Array()
	var i: int = clampi(frame,0,7)
	var left: bool = direction.ends_with("left")
	var rapier: bool = clip.contains("rapier_")
	var angles: Array[float] = [-1.25,-1.55,-0.75,0.0,0.34,1.05,0.64,-0.38]
	if rapier:
		angles.assign([-0.75,-0.95,-0.40,0.0,0.0,0.17,-0.45,-0.75])
	elif clip.contains("_heavy_"):
		angles.assign([-1.35,-1.65,-1.20,-0.35,0.0,1.25,0.80,-0.38])
	var axis: Vector2 = heading.rotated(angles[i]*(-1.0 if left else 1.0))
	return PackedVector2Array([anchor,anchor+axis*(84.0 if rapier else 68.0)])

# Ironwood axes use an original shared silhouette, not the inventory icon
# stretched into a held weapon. All points are wrist-local with +X forward.
static func axe_edge(id: String) -> PackedVector2Array:
	match id:
		"briar_hatchet_v283": return PackedVector2Array([Vector2(45,-15),Vector2(55,-19),Vector2(61,-13),Vector2(62,-5)])
		"gravecleaver_axe_v283": return PackedVector2Array([Vector2(55,-18),Vector2(65,-24),Vector2(74,-20),Vector2(77,-10),Vector2(74,-4)])
		"gallows_greataxe_v283": return PackedVector2Array([Vector2(59,-21),Vector2(71,-27),Vector2(83,-23),Vector2(88,-12),Vector2(84,-5)])
		"rosehook_bearded_axe_v286": return PackedVector2Array([Vector2(51,-19),Vector2(63,-24),Vector2(74,-20),Vector2(78,-10),Vector2(72,-4),Vector2(55,-8)])
		"ossuary_poleaxe_v286": return PackedVector2Array([Vector2(64,-15),Vector2(75,-22),Vector2(85,-18),Vector2(89,-8)])
	return PackedVector2Array()

static func _draw_ironwood(canvas: Node2D,id: String,pigment: Color,surface: Color,glow: float,colors: Array[Color],look: Dictionary,phase: float) -> void:
	var edge: PackedVector2Array = axe_edge(id)
	if edge.is_empty():
		return
	var end: float = edge[edge.size()-1].x
	var haft_end: float = 55.0 if id.begins_with("briar_") else (82.0 if id.begins_with("gallows_") or id.begins_with("ossuary_") else 70.0)
	var butt: float = -19.0 if id.begins_with("briar_") else -29.0
	var wood: Color = Color("503933").lerp(surface,0.22)
	var steel: Color = Color("777781").lerp(pigment,0.42)
	var bevel: Color = Color("d0c8c0").lerp(pigment,0.24)
	canvas.draw_line(Vector2(butt,0),Vector2(haft_end,0),Color("211d24"),5.8,true)
	canvas.draw_line(Vector2(butt+1,0),Vector2(haft_end,0),wood,3.8,true)
	canvas.draw_line(Vector2(butt+2,-1),Vector2(haft_end-4,-1),wood.lightened(0.28),0.7,true)
	for j in range(7):
		var x: float = -11.0+float(j)*3.2
		canvas.draw_line(Vector2(x,-2.0),Vector2(x-1.6,2.0),Color("aa8b73"),0.85,true)
	canvas.draw_line(Vector2(butt,-2.5),Vector2(butt,2.5),steel,2.4,true)
	var sides: Array[float] = [1.0]
	if id.begins_with("gallows_"):
		sides.append(-1.0)
	for side in sides:
		var outer: PackedVector2Array = PackedVector2Array()
		for p in edge:
			outer.append(Vector2(p.x,p.y*side))
		var root: Vector2 = Vector2(haft_end-8.0,0.0)
		var outline: PackedVector2Array = PackedVector2Array([root])
		outline.append_array(outer)
		outline.append(Vector2(end,0.0))
		canvas.draw_colored_polygon(outline,steel.darkened(0.23))
		for j in range(outer.size()-1):
			var a: Vector2 = outer[j]
			var b: Vector2 = outer[j+1]
			var inner_a: Vector2 = a.lerp(root,0.24)
			var inner_b: Vector2 = b.lerp(root,0.24)
			canvas.draw_polygon(PackedVector2Array([a,b,inner_b,inner_a]),PackedColorArray([bevel,bevel,steel,steel]))
		canvas.draw_polyline(outer,bevel.lightened(0.12),0.85,true)
		canvas.draw_line(root,outer[outer.size() >> 1],steel.lightened(0.18),0.8,true)
		if glow>0.0:
			seeded_edge(canvas,outer,colors,look,phase,glow)
	canvas.draw_line(Vector2(haft_end-7,-3),Vector2(haft_end+2,-3),steel.lightened(0.25),1.2,true)
	canvas.draw_circle(Vector2(haft_end-4,0),2.0,Color("b49a7e"))

static func cutting_edge(id: String, painted: bool = false) -> PackedVector2Array:
	var ironwood: PackedVector2Array = axe_edge(id)
	if not ironwood.is_empty():
		return ironwood
	if id=="seraph_reaper_v292":
		return PackedVector2Array([Vector2(16,-45),Vector2(35,-46),Vector2(55,-44),Vector2(78,-33),Vector2(86,-16),Vector2(79,0)])
	if painted:
		return PAINTED_V287.edge(id)
	if id.contains("rapier"):
		return PackedVector2Array([Vector2(12,0),Vector2(83,0)])
	if id=="rosehook_bearded_axe_v286":
		return PackedVector2Array([Vector2(67,-25),Vector2(74,-20),Vector2(76,-13),Vector2(70,-4),Vector2(58,12)])
	if id=="ossuary_poleaxe_v286":
		return PackedVector2Array([Vector2(74,-28),Vector2(84,-23),Vector2(88,-15),Vector2(88,-8),Vector2(76,-2)])
	var length: float = 53.0 if id.begins_with("briar_") else (82.0 if id.begins_with("gallows_") else 68.0)
	var width: float = 19.0 if length==53.0 else (29.0 if length==82.0 else 24.0)
	return PackedVector2Array([Vector2(length-8,-width),Vector2(length+3,-width*0.68),Vector2(length+6,-5)])

static func seeded_edge(canvas: Node2D, edge: PackedVector2Array, colors: Array[Color], look: Dictionary, phase: float, glow: float) -> void:
	if edge.size()<2 or colors.is_empty() or look.is_empty() or glow<=0.0:
		return
	var paths: Array[PackedVector2Array] = [edge]
	SEED_FX.draw_blade_light(canvas,paths,colors,look,phase,glow)
	var center: Vector2 = edge[0].lerp(edge[-1],0.5)
	var axis: Vector2 = (edge[-1]-edge[0]).normalized()
	SEED_PARTICLES.draw_pattern(canvas,center,axis,Vector2(edge[0].distance_to(edge[-1])*0.53,7.0),colors,look,phase,glow)

static func draw_melee(canvas: Node2D, id: String, grip: Vector2, tip: Vector2, pigment: Color, glow: float, colors: Array[Color] = [], look: Dictionary = {}, phase: float = 0.0, mirror_blade: bool = false, surface: Color = Color.WHITE) -> void:
	if id!="seraph_reaper_v292" and not MODELS.has(id):
		return
	var axis: Vector2 = (tip-grip).normalized()
	if axis.is_zero_approx():
		return
	if not axe_edge(id).is_empty():
		canvas.draw_set_transform(grip,axis.angle(),Vector2(1.0,-1.0 if mirror_blade else 1.0))
		_draw_ironwood(canvas,id,pigment,surface,glow,colors,look,phase)
		canvas.draw_set_transform(Vector2.ZERO)
		return
	var seraph: bool = id=="seraph_reaper_v292"
	var rapier: bool = id.contains("rapier")
	var painted: Texture2D = PAINTED_V287.texture(id,"held")
	var rect: Rect2 = Rect2(-34,-52,136,76) if seraph else (Rect2(-14,-18,102,36) if rapier else Rect2(-25,-32,117,64))
	var tex: Texture2D = SERAPH if seraph else (painted if painted!=null else MODELS[id])
	if painted!=null:
		rect=PAINTED_V287.held_rect(id)
	# Reflect the cutting edge across the shaft when changing swing handedness;
	# never reverse the shaft itself or move the grip away from the wrist.
	canvas.draw_set_transform(grip,axis.angle(),Vector2(1.0,-1.0 if mirror_blade else 1.0))
	var tint: Color = Color.WHITE.lerp(pigment.lerp(surface,0.30),0.50)
	canvas.draw_texture_rect(tex,rect,false,tint)
	var edge: PackedVector2Array = cutting_edge(id,painted!=null)
	if glow>0.0 and edge.size()>1:
		if colors.is_empty() or look.is_empty():
			canvas.draw_polyline(edge,Color(pigment.r,pigment.g,pigment.b,clampf(glow,0.0,1.0)*0.46),1.5,true)
		else:
			seeded_edge(canvas,edge,colors,look,phase,glow * (1.3 if seraph else 1.0))
			if seraph:
				seeded_edge(canvas,PackedVector2Array([Vector2(-27,0),Vector2(70,0)]),colors,look,phase,glow * 0.60)
		if id.begins_with("gallows_") and painted==null:
			var opposite: PackedVector2Array = PackedVector2Array()
			for point in edge:
				opposite.append(Vector2(point.x,-point.y))
			seeded_edge(canvas,opposite,colors,look,phase+0.2,glow)
	canvas.draw_set_transform(Vector2.ZERO)

static func draw_crossbow(canvas: Node2D, id: String, grip: Vector2, tip: Vector2, loaded: bool, cocking: float, pigment: Color, glow: float, colors: Array[Color] = [], look: Dictionary = {}, phase: float = 0.0) -> bool:
	if not MODELS.has(id) or not id.contains("crossbow") and id!="ossuary_arbalest_v237":
		return false
	var axis: Vector2 = (tip-grip).normalized()
	var index: int = ["blackthorn_crossbow_v236","silver_reliquary_crossbow_v236","vesper_latch_crossbow_v237","ossuary_arbalest_v237","mourning_star_crossbow_v277"].find(id)
	if index<0:
		return false
	var widths: Array[float] = [17.0,20.0,15.0,23.0,20.0]
	var sweeps: Array[float] = [5.0,7.0,2.0,4.0,6.0]
	var w: float = widths[index]
	var x: float = 21.0-sweeps[index]
	var notch: float = 2.0 if loaded else lerpf(16.0,2.0,clampf(cocking,0.0,1.0))
	canvas.draw_set_transform(grip,axis.angle(),Vector2.ONE*(0.70 if index==0 else 1.0))
	canvas.draw_texture_rect(MODELS[id],Rect2(-26,-30,67,60),false,Color.WHITE.lerp(pigment,0.50))
	var cord: PackedVector2Array = PackedVector2Array([Vector2(x,-w),Vector2(notch,0),Vector2(x,w)])
	canvas.draw_polyline(cord,Color("28232b"),1.4,true)
	canvas.draw_polyline(cord,Color("d6c6d9"),0.65,true)
	if loaded:
		canvas.draw_line(Vector2(notch,0),Vector2(37,0),Color("e2d5ce"),1.35,true)
		canvas.draw_line(Vector2(34,-1.8),Vector2(37,0),Color("e2d5ce"),1.2,true)
	if glow>0.0:
		var ink: Color = Color(pigment.r,pigment.g,pigment.b,clampf(glow,0.0,1.0)*0.35)
		var limbs: PackedVector2Array = PackedVector2Array([Vector2(x,-w),Vector2(25,-w*0.45),Vector2(21,0),Vector2(25,w*0.45),Vector2(x,w)])
		if colors.is_empty() or look.is_empty():
			canvas.draw_polyline(limbs,ink,1.4,true)
		else:
			seeded_edge(canvas,limbs,colors,look,phase,glow)
			seeded_edge(canvas,PackedVector2Array([Vector2(-20,-2),Vector2(7,-2),Vector2(35,-2)]),colors,look,phase,glow*0.85)
			seeded_edge(canvas,PackedVector2Array([Vector2(-20,2),Vector2(7,2),Vector2(35,2)]),colors,look,phase,glow*0.65)
			SEED_FX.draw_edge(canvas,cord,colors,look,phase,glow*0.55,false)
	canvas.draw_set_transform(Vector2.ZERO)
	return true
