extends RefCounted
## Presentation and timing for one physical bolt. No added sprite textures.
const HAND = preload("res://scripts/dagger_thrust_v186.gd")
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

static func draw_weapon(canvas: Node2D, grip: Vector2, tip: Vector2, profile: Dictionary, loaded: bool, base: String, cocking: float = 0.0) -> void:
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
	canvas.draw_line(butt, tip, wood, 3.0, true)
	canvas.draw_line(grip-n*1.0, tip-n*1.0, metal.darkened(0.3), 1.0, true)
	var sweep: float = float(build["sweep"])
	var left: Vector2 = mount - n * width - axis * sweep
	var right: Vector2 = mount + n * width - axis * sweep
	var limbs: PackedVector2Array = PackedVector2Array([left, mount-n*9.0+axis*4.0, mount, mount+n*9.0+axis*4.0, right])
	canvas.draw_polyline(limbs, metal.darkened(0.40), 4.1, true)
	canvas.draw_polyline(limbs, metal, 2.0, true)
	# Fine forged bevels and stock furniture; fixed small draw budget.
	canvas.draw_polyline(limbs, metal.lightened(0.35), 0.65, true)
	canvas.draw_line(mount - n * 3.0, mount + n * 3.0, trim, 2.0, true)
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
	canvas.draw_polyline(PackedVector2Array([left, notch, right]), Color("bdb2be"), 0.85, true)
	if loaded:
		canvas.draw_line(notch, tip+axis*5.0, metal.lightened(0.28), 1.5, true)
		canvas.draw_line(tip+axis*2.0-n*1.7, tip+axis*5.0, metal, 1.4, true)
