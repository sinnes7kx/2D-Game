extends RefCounted
const ART = preload("res://scripts/modular_weapon_art_v178.gd")
const SURFACE = preload("res://scripts/living_metal_v187.gd")
const FX = preload("res://scripts/anomalous_steel_fx_v180.gd")
const HAND = preload("res://scripts/dagger_thrust_v186.gd")

static func matches(name: String) -> bool:
	return name.begins_with("scythe_") or name.begins_with("attack_scythe_")

static func source_frame(name: String, frame: int) -> int:
	var i: int = clampi(frame, 0, 7)
	if name.contains("_idle_"):
		return [0, 0, 1, 0, 0, 1, 0, 0][i]
	if name.contains("_walk_"):
		return [0, 1, 2, 1, 0, 1, 2, 1][i]
	return i

static func install(sprite: AnimatedSprite2D) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	var frames: SpriteFrames = sprite.sprite_frames
	for value in frames.get_animation_names():
		var name: String = str(value)
		if not matches(name):
			continue
		var face: String = name.get_slice("_", name.get_slice_count("_") - 1)
		var source: String = "attack_unarmed_light_" + face
		if not frames.has_animation(source) or frames.get_frame_count(source) < 8:
			continue
		# Keep exact clip names, speed, frame durations and count; only replace
		# the baked weapon with the approved weapon-free body texture.
		for i in range(frames.get_frame_count(name)):
			var duration: float = frames.get_frame_duration(name, i)
			frames.set_frame(name, i, frames.get_frame_texture(source, source_frame(name, i)), duration)

static func span(name: String, frame: int, guides: Dictionary) -> PackedVector2Array:
	if not matches(name):
		return PackedVector2Array()
	var face: String = name.get_slice("_", name.get_slice_count("_") - 1)
	var anchor: Vector2 = HAND.hand_anchor(face, source_frame(name, frame), 0 if face == "left" else 1)
	# At the back the hand can be hidden by hair. A behind-body shaft emerges
	# from the concealed grip instead of floating outside the silhouette.
	if anchor == Vector2.INF:
		if face != "back":
			return PackedVector2Array()
		anchor = Vector2(34, 27)
	var direction: Vector2 = Vector2(-0.55 if face == "left" else 0.55, -0.84)
	var rows: Array = guides.get(name, [])
	if not rows.is_empty():
		var row: Array = rows[clampi(frame, 0, rows.size() - 1)]
		if row.size() == 4:
			var authored: Vector2 = Vector2(float(row[2]), float(row[3])) - Vector2(float(row[0]), float(row[1]))
			if authored.length_squared() > 16.0:
				direction = authored.normalized()
	return PackedVector2Array([anchor, anchor + direction.normalized() * 76.0])

# Crescent cutting edge with exact pointed tip, and tapered spine. Independent
# curvature, blade span and depth retain a recognizable agricultural silhouette.
static func contours(head: Vector2, axis: Vector2, profile: Dictionary, side: float = 1.0) -> Array[PackedVector2Array]:
	var tangent: Vector2 = axis.normalized()
	var normal: Vector2 = Vector2(-tangent.y, tangent.x) * side
	var reach: float = 43.0 * float(profile.get("scythe_span", 1.0))
	var curve: float = float(profile.get("scythe_curve", 0.7))
	var depth: float = 8.0 * float(profile.get("width_scale", 1.0))
	var outside: PackedVector2Array = PackedVector2Array()
	var inside: PackedVector2Array = PackedVector2Array()
	for i in range(13):
		var u: float = float(i) / 12.0
		var center: Vector2 = head + normal * (reach * u) + tangent * (9.0 * sin(u * PI) - reach * curve * u * u)
		var thickness: float = depth * (0.55 + 0.45 * sin(u * PI)) * (1.0 - u)
		outside.append(center + tangent * thickness)
		inside.append(center - tangent * thickness * 0.65)
	return [outside, inside]

static func draw_scythe(canvas: Node2D, grip: Vector2, head: Vector2, p: Dictionary, look: Dictionary, colors: Array[Color], phase: float, side: float, glow: bool) -> void:
	if p.is_empty() or grip.distance_squared_to(head) < 16.0:
		return
	var axis: Vector2 = (head - grip).normalized()
	var foot: Vector2 = grip - axis * 31.0
	var shaft: Color = p["grip"]
	var trim: Color = p["ornament_ink"]
	canvas.draw_line(foot, head, Color("211b29"), 5.0, true)
	canvas.draw_line(foot, head, shaft.lightened(0.14), 3.3, true)
	canvas.draw_line(foot + axis * 2.0, head, trim.darkened(0.4), 0.65, true)
	ART.draw_grip(canvas, grip - axis * 9.0, grip + axis * 9.0, 4.1, p)
	for collar in [foot + axis * 2.0, head - axis * 5.0]:
		var n: Vector2 = Vector2(-axis.y, axis.x)
		canvas.draw_line(collar - n * 2.5, collar + n * 2.5, trim, 1.6, true)
	var edges: Array[PackedVector2Array] = contours(head, axis, p, side)
	var outer: PackedVector2Array = edges[0]
	var inner: PackedVector2Array = edges[1]
	for i in range(outer.size() - 1):
		var u: float = (float(i) + 0.5) / float(outer.size() - 1)
		var m0: Vector2 = outer[i].lerp(inner[i], 0.45)
		var m1: Vector2 = outer[i+1].lerp(inner[i+1], 0.45)
		var a: Color = SURFACE.surface_color(p, u, 0.25, phase)
		var b: Color = SURFACE.surface_color(p, u, 0.75, phase)
		canvas.draw_colored_polygon(PackedVector2Array([outer[i],outer[i+1],m1,m0]), a)
		canvas.draw_colored_polygon(PackedVector2Array([m0,m1,inner[i+1],inner[i]]), b)
	canvas.draw_polyline(outer, p["edge"], 0.85, true)
	canvas.draw_polyline(inner, p["edge"], 1.0, true)
	canvas.draw_line(head - axis * 3.5, head + axis * 3.5, trim, 2.2, true)
	if glow:
		FX.draw_edge(canvas, inner, colors, look, phase, 0.85)
