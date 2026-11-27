extends RefCounted
const HAND = preload("res://scripts/dagger_thrust_v186.gd")
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
		for style in ["rapier","axe"]:
			var names: Array[String] = [style+"_idle_"+face,style+"_walk_"+face]
			if style=="rapier":
				names.append_array(["attack_rapier_pierce_"+face,"attack_rapier_heavy_pierce_"+face])
			else:
				names.append_array(["attack_axe_light_"+face,"attack_axe_heavy_"+face])
			for name in names:
				if frames.has_animation(name):
					continue
				frames.add_animation(name)
				frames.set_animation_loop(name.begins_with(style+"_"))
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

static func draw_melee(canvas: Node2D, id: String, grip: Vector2, tip: Vector2, pigment: Color, glow: float) -> void:
	if not MODELS.has(id):
		return
	var axis: Vector2 = (tip-grip).normalized()
	var rapier: bool = id.contains("rapier")
	var rect: Rect2 = Rect2(-14,-18,102,36) if rapier else Rect2(-25,-32,117,64)
	canvas.draw_set_transform(grip,axis.angle())
	canvas.draw_texture_rect(MODELS[id],rect,false,Color.WHITE.lerp(pigment,0.22))
	if glow>0.0:
		var ink: Color = Color(pigment.r,pigment.g,pigment.b,clampf(glow,0.0,1.0)*0.46)
		if rapier:
			canvas.draw_line(Vector2(12,0),Vector2(83,0),ink,2.4,true)
		elif id=="rosehook_bearded_axe_v286":
			canvas.draw_polyline(PackedVector2Array([Vector2(67,-25),Vector2(74,-20),Vector2(76,-13),Vector2(70,-4),Vector2(58,12)]),ink,2.4,true)
		elif id=="ossuary_poleaxe_v286":
			canvas.draw_polyline(PackedVector2Array([Vector2(74,-28),Vector2(84,-23),Vector2(88,-15),Vector2(88,-8),Vector2(76,-2)]),ink,2.6,true)
		else:
			var length: float = 53.0 if id.begins_with("briar_") else (82.0 if id.begins_with("gallows_") else 68.0)
			var width: float = 19.0 if length==53.0 else (29.0 if length==82.0 else 24.0)
			canvas.draw_polyline(PackedVector2Array([Vector2(length-8,-width),Vector2(length+3,-width*0.68),Vector2(length+6,-5)]),ink,2.7,true)
			if length==82.0:
				canvas.draw_polyline(PackedVector2Array([Vector2(length-8,width),Vector2(length+3,width*0.68),Vector2(length+6,5)]),ink,2.7,true)
	canvas.draw_set_transform(Vector2.ZERO)

static func draw_crossbow(canvas: Node2D, id: String, grip: Vector2, tip: Vector2, loaded: bool, cocking: float, pigment: Color, glow: float) -> bool:
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
	canvas.draw_texture_rect(MODELS[id],Rect2(-26,-30,67,60),false,Color.WHITE.lerp(pigment,0.25))
	var cord: PackedVector2Array = PackedVector2Array([Vector2(x,-w),Vector2(notch,0),Vector2(x,w)])
	canvas.draw_polyline(cord,Color("28232b"),1.4,true)
	canvas.draw_polyline(cord,Color("d6c6d9"),0.65,true)
	if loaded:
		canvas.draw_line(Vector2(notch,0),Vector2(37,0),Color("e2d5ce"),1.35,true)
		canvas.draw_line(Vector2(34,-1.8),Vector2(37,0),Color("e2d5ce"),1.2,true)
	if glow>0.0:
		var ink: Color = Color(pigment.r,pigment.g,pigment.b,clampf(glow,0.0,1.0)*0.35)
		canvas.draw_polyline(PackedVector2Array([Vector2(x,-w),Vector2(25,-w*0.45),Vector2(21,0),Vector2(25,w*0.45),Vector2(x,w)]),ink,2.6,true)
	canvas.draw_set_transform(Vector2.ZERO)
	return true
