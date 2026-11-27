extends RefCounted
## New weapons use original clean body texture references, no new atlases.
const HAND = preload("res://scripts/dagger_thrust_v186.gd")
const AIM = preload("res://scripts/crossbow_v236.gd")
const ART = preload("res://scripts/modular_weapon_art_v178.gd")
static func sequence(name: String, face: String) -> Array[int]:
	var neutral: int = 1 if face == "back" else 0
	if name.contains("_idle_"):
		return [neutral, neutral, neutral, neutral, neutral, neutral, neutral, neutral]
	if name.contains("_walk_"):
		return [neutral, 1, 2, 1, neutral, 1, 2, 1]
	if name.contains("forge_dagger_"):
		return HAND.sequence(name.contains("_heavy_"))
	return [1, 2, 3, 4, 4, 5, 2, 1]

static func install(frames: SpriteFrames) -> void:
	for face in ["front", "back", "left", "right"]:
		var source: String = "attack_unarmed_light_" + face
		if not frames.has_animation(source) or frames.get_frame_count(source) < 8:
			continue
		for prefix in ["forge_bow", "forge_dagger"]:
			var actions: Array[String] = ["light", "heavy"]
			if prefix == "forge_dagger":
				actions.assign(["pierce", "heavy_pierce"])
			var names: Array[String] = [prefix + "_idle_" + face, prefix + "_walk_" + face]
			for action in actions:
				names.append("attack_" + prefix + "_" + action + "_" + face)
			for name in names:
				if frames.has_animation(name):
					continue
				frames.add_animation(name)
				frames.set_animation_loop(name, not name.begins_with("attack_"))
				frames.set_animation_speed(name, 16.0 if name.begins_with("attack_") else 8.0)
				for index in sequence(name, face):
					frames.add_frame(name, frames.get_frame_texture(source, index))

static func span(name: String, face: String, frame: int) -> PackedVector2Array:
	var index: int = clampi(frame, 0, 7)
	var hand: int = 0 if face == "left" else 1
	if name.begins_with("attack_forge_dagger_"):
		return HAND.span(face, index, hand, name.contains("_heavy_"), false)
	var grip: Vector2 = HAND.hand_anchor(face, sequence(name, face)[index], hand)
	if grip == Vector2.INF:
		return PackedVector2Array()
	var axis: Vector2 = HAND.direction(face)
	if not name.begins_with("attack_"):
		axis = axis.rotated(0.75 if face == "left" else -0.75)
	return PackedVector2Array([grip, grip + axis * (32.0 if name.contains("forge_bow_") else 39.0)])

static func bow_span(body: AnimatedSprite2D, name: String, face: String, frame: int, heading: Vector2) -> PackedVector2Array:
	var points: PackedVector2Array = span(name, face, frame)
	return AIM.aimed_span(body, points, heading) if name.begins_with("attack_") else points

static func limbs(grip: Vector2, axis: Vector2, base: String, width_scale: float) -> Array[PackedVector2Array]:
	var n: Vector2 = axis.orthogonal()
	var recurve: bool = base == "vesper_recurve_bow_v238"
	var half: float = (33.0 if recurve else 43.0) * clampf(width_scale, 0.9, 1.1)
	var result: Array[PackedVector2Array] = []
	for side in [-1.0, 1.0]:
		var a: Vector2 = n * side
		var points: PackedVector2Array = PackedVector2Array([grip, grip + a * half * 0.26 + axis * 2.0, grip + a * half * 0.58 - axis * (5.0 if recurve else 3.0), grip + a * half * 0.84 - axis * (12.0 if recurve else 9.0), grip + a * half - axis * (8.0 if recurve else 17.0)])
		result.append(points)
	return result

static func draw_bow(canvas: Node2D, points: PackedVector2Array, base: String, profile: Dictionary, limb_colors: Array[Color], string_colors: Array[Color], draw_amount: float, glow: float) -> void:
	if points.size() != 2 or profile.is_empty() or limb_colors.size() < 2 or string_colors.size() < 2:
		return
	var grip: Vector2 = points[0]
	var axis: Vector2 = (points[1] - grip).normalized()
	var n: Vector2 = axis.orthogonal()
	var build: Array[PackedVector2Array] = limbs(grip, axis, base, float(profile.get("width_scale", 1.0)))
	var trim: Color = profile.get("ornament_ink", Color("b6abb8"))
	var steel: Color = profile.get("metal", Color("8c8695"))
	for side in range(2):
		var limb: PackedVector2Array = build[side]
		# Dark backing and laminated wood/horn faces. Existing limb endpoints
		# are also the string endpoints; never shift the shot geometry.
		canvas.draw_polyline(limb, Color("231e23"), 4.8, true)
		for i in range(limb.size() - 1):
			var u: float = float(i) / float(limb.size() - 2)
			var pigment: Color = GhostCosmeticRNGV152.sample_palette(limb_colors, u)
			var tone: Color = pigment.lerp(steel, 0.16)
			var thickness: float = lerpf(3.9,1.65,u)
			var grain: Vector2 = axis * thickness * 0.26
			if glow > 0.0:
				canvas.draw_line(limb[i], limb[i+1], Color(tone.r, tone.g, tone.b, glow * 0.22), 5.2, true)
			canvas.draw_line(limb[i], limb[i + 1], tone.darkened(0.18), thickness, true)
			canvas.draw_line(limb[i]-grain,limb[i+1]-grain,tone.lightened(0.18),0.72,true)
			canvas.draw_line(limb[i]+grain,limb[i+1]+grain,tone.darkened(0.42),0.62,true)
			if i < 3:
				canvas.draw_line(limb[i].lerp(limb[i+1],0.16),limb[i].lerp(limb[i+1],0.78),tone.lightened(0.10),0.42,true)
		var tip: Vector2 = limb[limb.size()-1]
		var horn: Color = trim.lerp(steel,0.54)
		canvas.draw_line(limb[limb.size()-2].lerp(tip,0.54),tip,horn.darkened(0.42),2.5,true)
		canvas.draw_line(limb[limb.size()-2].lerp(tip,0.60),tip,horn,1.45,true)
		var at: Vector2 = limb[1].lerp(limb[2], 0.5)
		for i in range(3):
			var band: Vector2 = at+n*(float(i)-1.0)*1.8
			canvas.draw_line(band-axis*1.6,band+axis*1.6,trim.darkened(0.40),1.25,true)
			canvas.draw_line(band-axis*1.35,band+axis*1.35,trim.lerp(steel,0.60),0.52,true)
	var notch: Vector2 = grip - axis * lerpf(12.0, 34.0, clampf(draw_amount, 0.0, 1.0))
	var string: Color = GhostCosmeticRNGV152.sample_palette(string_colors, 0.5)
	var cord: PackedVector2Array = PackedVector2Array([build[0][4],notch,build[1][4]])
	canvas.draw_polyline(cord,Color("28232b"),1.35,true)
	canvas.draw_polyline(cord,string.lerp(Color("d3cbd4"),0.38),0.72,true)
	ART.draw_grip(canvas, grip-n*5.0, grip+n*5.0, 2.0, profile)

static func draw_dagger(canvas: Node2D, points: PackedVector2Array, profile: Dictionary) -> void:
	if points.size() != 2 or profile.is_empty():
		return
	var axis: Vector2 = (points[1] - points[0]).normalized()
	var root: Vector2 = points[0] + axis * 8.0
	ART.draw_grip(canvas, points[0] - axis * 7.0, root, 2.4, profile)
	ART.draw_blade(canvas, root, points[1], 2.8, profile)
