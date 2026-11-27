extends RefCounted
## Presentation and timing for one physical bolt. No added sprite textures.
const HAND = preload("res://scripts/dagger_thrust_v186.gd")
const FX = preload("res://scripts/anomalous_steel_fx_v180.gd")
const FX_LEVEL = preload("res://scripts/fx_intensity_v1924.gd")

static func weapon_scale(base: String) -> float:
	return 0.70 if base == "blackthorn_crossbow_v236" else 1.0

static func offhand_span(name: String, face: String, frame: int, axis: Vector2) -> PackedVector2Array:
	var diagonal = preload("res://scripts/ghost_diagonal_art_v247.gd")
	if not diagonal.diagonal_name(name).is_empty():
		var wrist: Vector2 = diagonal.far_wrist(name,frame)
		return PackedVector2Array() if wrist==Vector2.INF else PackedVector2Array([wrist,wrist+axis.normalized()*32.0])
	var hand: int = 1 if face == "left" else 0
	var grip: Vector2 = HAND.hand_anchor(face, sequence(name, face)[clampi(frame, 0, 7)], hand)
	if grip == Vector2.INF:
		return PackedVector2Array()
	return PackedVector2Array([grip, grip + axis.normalized() * 32.0])
# One release event per volley. The saved damage roll is shared by the bolts.
static func bolt_count(base: String) -> int:
	return 2 if base == "blackthorn_crossbow_v236" else 1

static func bolt_angle(index: int, count: int) -> float:
	return deg_to_rad(-2.5 if index == 0 else 2.5) if count == 2 else 0.0

const FIRE_TIME: float = 0.20
const RELOAD_TIME: float = 0.76
const HEAVY_RELOAD: float = 1.02
const RELEASE_AT: float = 0.10
static func sequence(name: String, face: String) -> Array[int]:
	var neutral: int = 1 if face == "back" else 0
	if name.contains("_idle_"):
		return [neutral, neutral, neutral, neutral, neutral, neutral, neutral, neutral]
	if name.contains("_walk_"):
		return [neutral, 1, 2, 1, neutral, 1, 2, 1]
	if name.contains("_reload_"):
		return [2, 1, 2, 3, 2, 1, neutral, neutral]
	return [1, 2, 3, 3, 4, 5, 2, neutral]

static func install(frames: SpriteFrames) -> void:
	for face in ["front", "back", "left", "right"]:
		var source: String = "attack_unarmed_light_" + face
		if not frames.has_animation(source) or frames.get_frame_count(source) < 8:
			continue
		for name in ["crossbow_idle_" + face, "crossbow_walk_" + face, "attack_crossbow_fire_" + face, "attack_crossbow_reload_" + face]:
			if frames.has_animation(name):
				continue
			frames.add_animation(name)
			frames.set_animation_loop(name, not name.begins_with("attack_"))
			frames.set_animation_speed(name, 8.0 if not name.begins_with("attack_") else 16.0)
			for index in sequence(name, face):
				frames.add_frame(name, frames.get_frame_texture(source, index))

static func span(name: String, face: String, frame: int) -> PackedVector2Array:
	var diagonal = preload("res://scripts/ghost_diagonal_art_v247.gd")
	if not diagonal.diagonal_name(name).is_empty():
		return diagonal.crossbow_span(name,frame)
	var index: int = clampi(frame, 0, 7)
	var grip: Vector2 = HAND.hand_anchor(face, sequence(name, face)[index], 0 if face == "left" else 1)
	if grip == Vector2.INF:
		return PackedVector2Array()
	var axis: Vector2 = HAND.direction(face)
	if name.contains("_idle_") or name.contains("_walk_"):
		axis = axis.rotated(-0.42 if face != "left" else 0.42)
	elif name.contains("_reload_"):
		axis = axis.rotated(-0.75 if face != "left" else 0.75)
	return PackedVector2Array([grip, grip + axis * 32.0])

# Physics-clock sampling keeps the visible shot and reload in step with
# the single-release guard, even while menus or hitstop pause simulation.
static func action_sample(left: float, duration: float) -> Vector2:
	var sample: float = clampf(1.0 - left / maxf(duration, 0.001), 0.0, 1.0) * 8.0
	var frame: int = mini(7, floori(sample))
	return Vector2(frame, clampf(sample - float(frame), 0.0, 1.0))

static func aimed_span(body: AnimatedSprite2D, points: PackedVector2Array, heading: Vector2) -> PackedVector2Array:
	if body == null or points.size() != 2 or heading.length_squared() < 0.001:
		return points
	var origin: Vector2 = body.to_global(points[0])
	var local_tip: Vector2 = body.to_local(origin + heading.normalized())
	var axis: Vector2 = (local_tip - points[0]).normalized()
	return PackedVector2Array([points[0], points[0] + axis * 32.0])

# Base determines construction; existing seeded forge rolls determine
# bounded variations within each base. No new save fields.
static func construction(profile: Dictionary, base: String) -> Dictionary:
	var style: int = 0
	match base:
		"silver_reliquary_crossbow_v236": style = 1
		"vesper_latch_crossbow_v237": style = 2
		"ossuary_arbalest_v237": style = 3
	var widths: Array[float] = [17.0, 20.0, 15.0, 23.0]
	var stocks: Array[float] = [18.0, 18.0, 15.0, 22.0]
	return {"style": style, "width": widths[style] * clampf(float(profile.get("width_scale", 1.0)), 0.85, 1.15), "stock": stocks[style], "ornament": posmod(int(profile.get("ornament", 0)), 4), "wraps": clampi(int(profile.get("wrap_count", 4)), 3, 6), "sweep": [5.0, 7.0, 2.0, 4.0][style]}

static func draw_weapon(canvas: Node2D, grip: Vector2, tip: Vector2, profile: Dictionary, loaded: bool, base: String, cocking: float = 0.0, look: Dictionary = {}, colors: Array[Color] = [], phase: float = 0.0, glow_scale: float = 1.0) -> void:
	var pigment: Color = profile.get("metal",Color.WHITE)
	var glow: float = FX_LEVEL.intensity*0.55*glow_scale if not look.is_empty() else 0.0
	if preload("res://scripts/weapon_models_v283.gd").draw_crossbow(canvas,base,grip,tip,loaded,cocking,pigment,glow,colors,look,phase):
		return
	var scale: float = weapon_scale(base)
	canvas.draw_set_transform(grip, 0.0, Vector2.ONE * scale)
	_draw_local(canvas, Vector2.ZERO, tip - grip, profile, loaded, base, cocking, look, colors, phase)
	canvas.draw_set_transform(Vector2.ZERO)

static func _draw_local(canvas: Node2D, grip: Vector2, tip: Vector2, profile: Dictionary, loaded: bool, base: String, cocking: float, look: Dictionary, colors: Array[Color], phase: float) -> void:
	if profile.is_empty() or grip.distance_squared_to(tip) < 4.0:
		return
	var axis: Vector2 = (tip - grip).normalized()
	var n: Vector2 = axis.orthogonal()
	var wood: Color = profile.get("grip", Color("69515e"))
	var metal: Color = profile.get("edge", Color("b5aebd"))
	wood = wood.lerp(Color("382a30"), 0.40)
	var build: Dictionary = construction(profile, base)
	var style: int = int(build["style"])
	var raw_metal: Color = profile.get("metal", metal)
	metal = raw_metal.lerp(Color("b6b4bc") if style == 1 else Color("747582"), 0.32)
	var butt: Vector2 = grip - axis * float(build["stock"])
	var mount: Vector2 = grip + axis * 21.0
	var width: float = float(build["width"])
	var trim: Color = profile.get("ornament_ink", metal)
	trim = trim.lerp(metal, 0.52)
	canvas.draw_colored_polygon(PackedVector2Array([butt-n*4.0, grip-n*3.0, tip-n*2.0, tip+n*2.0, grip+n*3.0, butt+n*4.0]), wood.darkened(0.3))
	canvas.draw_line(butt,tip,wood,3.8,true)
	canvas.draw_line(butt-n*2.15,grip-n*1.7,wood.lightened(0.28),0.75,true)
	canvas.draw_line(butt+n*2.2,grip+n*1.6,wood.darkened(0.34),0.85,true)
	for i in range(5):
		var a: float = float(i)/5.0
		canvas.draw_line(butt.lerp(grip,a)-n*0.8,butt.lerp(grip,a+0.12)-n*0.8,wood.darkened(0.24),0.45,true)
	# Recessed bolt rail and steel lock housing, retaining muzzle/notch.
	canvas.draw_line(grip+axis*5.0,tip,metal.darkened(0.52),3.0,true)
	canvas.draw_line(grip+axis*5.0-n*1.05,tip-n*1.05,metal.lightened(0.22),0.62,true)
	canvas.draw_line(grip+axis*5.0+n*1.05,tip+n*1.05,metal,0.62,true)
	canvas.draw_line(butt-n*3.5,butt+n*3.5,metal.darkened(0.38),2.6,true)
	canvas.draw_line(butt-n*2.8-axis*0.45,butt+n*2.8-axis*0.45,metal.lightened(0.20),0.65,true)
	var sweep: float = float(build["sweep"])
	var left: Vector2 = mount - n * width - axis * sweep
	var right: Vector2 = mount + n * width - axis * sweep
	var limbs: PackedVector2Array = PackedVector2Array([left, mount-n*9.0+axis*4.0, mount, mount+n*9.0+axis*4.0, right])
	canvas.draw_polyline(limbs,metal.darkened(0.55),4.8,true)
	canvas.draw_polyline(limbs,metal.darkened(0.10),2.9,true)
	# Off-center polished bevel, rather than a uniformly bright wire.
	for i in range(limbs.size()-1):
		canvas.draw_line(limbs[i]-axis*0.75,limbs[i+1]-axis*0.75,metal.lightened(0.24),0.72,true)
		canvas.draw_line(limbs[i]+axis*0.85,limbs[i+1]+axis*0.85,metal.darkened(0.32),0.62,true)
	canvas.draw_line(mount-n*3.6,mount+n*3.6,metal.darkened(0.48),4.0,true)
	canvas.draw_line(mount-n*3.0-axis*0.9,mount+n*3.0-axis*0.9,trim,0.85,true)
	for sign_value in [-1.0,1.0]:
		var rivet: Vector2 = mount+n*sign_value*2.1
		canvas.draw_circle(rivet,1.05,metal.darkened(0.50))
		canvas.draw_circle(rivet-axis*0.3,0.48,metal.lightened(0.35))
	for i in range(int(build["wraps"])):
		var at: Vector2 = grip - axis * (2.0 + float(i) * 1.8)
		canvas.draw_line(at - n * 2.1, at + n * 2.1 - axis * 1.0, trim.darkened(0.18), 0.65, true)
	var ornament: int = int(build["ornament"])
	var inset: Vector2 = grip + axis * 12.0
	if ornament == 0:
		canvas.draw_polyline(PackedVector2Array([inset-axis*3.0, inset-n*1.7, inset+axis*3.0, inset+n*1.7, inset-axis*3.0]), trim, 0.7, true)
	elif ornament == 1:
		canvas.draw_line(inset-axis*3.0, inset+axis*3.0, trim, 0.85, true)
		canvas.draw_line(inset-n*2.0, inset+n*2.0, trim, 0.85, true)
	elif ornament == 2:
		canvas.draw_arc(inset, 2.0, 0.0, TAU, 10, trim, 0.75, true)
	else:
		canvas.draw_line(inset-axis*3.0+n, inset+axis*3.0+n, trim, 0.65, true)
		canvas.draw_line(inset-axis*3.0-n, inset+axis*3.0-n, trim, 0.65, true)
	var notch: Vector2 = grip + axis * (2.0 if loaded else lerpf(16.0, 2.0, clampf(cocking, 0.0, 1.0)))
	var cord: PackedVector2Array = PackedVector2Array([left,notch,right])
	canvas.draw_polyline(cord,Color("282329"),1.4,true)
	canvas.draw_polyline(cord,Color("bdb2be"),0.72,true)
	if not look.is_empty() and not colors.is_empty() and FX_LEVEL.intensity > 0.0:
		FX.draw_edge(canvas, limbs, colors, look, phase, 0.85)
		FX.draw_signature(canvas, limbs, colors, look, phase)
		preload("res://scripts/weapon_particle_paths_v244.gd").draw_pattern(canvas, mount, n, Vector2(width + 4.0, 9.0), colors, look, phase)
	if loaded:
		canvas.draw_line(notch, tip+axis*5.0, metal.lightened(0.28), 1.5, true)
		canvas.draw_line(tip+axis*2.0-n*1.7, tip+axis*5.0, metal, 1.4, true)
