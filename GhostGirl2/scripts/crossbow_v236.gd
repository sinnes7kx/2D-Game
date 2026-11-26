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

static func draw_weapon(canvas: Node2D, grip: Vector2, tip: Vector2, profile: Dictionary, loaded: bool, silver: bool) -> void:
	if profile.is_empty() or grip.distance_squared_to(tip) < 4.0:
		return
	var axis: Vector2 = (tip - grip).normalized()
	var n: Vector2 = axis.orthogonal()
	var wood: Color = profile.get("grip", Color("69515e"))
	var metal: Color = profile.get("edge", Color("b5aebd"))
	wood = wood.lerp(Color("382a30"), 0.40)
	metal = metal.lerp(Color("b6b4bc") if silver else Color("747582"), 0.45)
	var butt: Vector2 = grip - axis * 18.0
	var mount: Vector2 = grip + axis * 21.0
	var width: float = 20.0 if silver else 17.0
	canvas.draw_colored_polygon(PackedVector2Array([butt-n*4.0, grip-n*3.0, tip-n*2.0, tip+n*2.0, grip+n*3.0, butt+n*4.0]), wood.darkened(0.3))
	canvas.draw_line(butt, tip, wood, 3.0, true)
	canvas.draw_line(grip-n*1.0, tip-n*1.0, metal.darkened(0.3), 1.0, true)
	var left: Vector2 = mount - n * width - axis * 5.0
	var right: Vector2 = mount + n * width - axis * 5.0
	var limbs: PackedVector2Array = PackedVector2Array([left, mount-n*9.0+axis*4.0, mount, mount+n*9.0+axis*4.0, right])
	canvas.draw_polyline(limbs, metal.darkened(0.40), 4.1, true)
	canvas.draw_polyline(limbs, metal, 2.0, true)
	var notch: Vector2 = grip + axis * (2.0 if loaded else 16.0)
	canvas.draw_polyline(PackedVector2Array([left, notch, right]), Color("bdb2be"), 0.85, true)
	if loaded:
		canvas.draw_line(notch, tip+axis*5.0, metal.lightened(0.28), 1.5, true)
		canvas.draw_line(tip+axis*2.0-n*1.7, tip+axis*5.0, metal, 1.4, true)
