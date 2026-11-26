extends RefCounted
## One authored wand grip/tip geometry source for equipment, light and casts.
## Coordinates are Ghost-local; scene transforms are respected via to_global.
const PATH: String = "res://resources/wand_pose_guides_v163.json"
const GENTLE = preload("res://scripts/gentle_weapon_motion_v191.gd")
static var _rows: Dictionary = {}

static func rows() -> Dictionary:
	if _rows.is_empty() and FileAccess.file_exists(PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary:
			_rows = parsed.get("animations", {}) as Dictionary
	return _rows

static func span(animation_name: String, frame_index: int, face: String = "front") -> PackedVector2Array:
	var record: Dictionary = rows().get(animation_name, {})
	if record.is_empty():
		record = rows().get("wand_idle_" + face, {})
	var guides: Array = record.get("guides", [])
	if guides.is_empty():
		var rightward: float = -1.0 if face == "left" else 1.0
		return PackedVector2Array([Vector2(12.0 * rightward, 10.0), Vector2(30.0 * rightward, -23.0)])
	var frame: int = clampi(frame_index, 0, guides.size() - 1)
	var points: Variant = guides[frame]
	if not points is Array or points.size() != 4:
		return PackedVector2Array()
	return PackedVector2Array([
		Vector2(float(points[0]), float(points[1])),
		Vector2(float(points[2]), float(points[3]))
	])

# Ghost-local wrist targets match the independent equipped-weapon guides.
# Keeping this delta in one place prevents the painted wand, wand light and
# projectile muzzle from disagreeing across direction/pose changes.
static func target_grip(face: String) -> Vector2:
	match face:
		"left": return Vector2(-17.0, 12.0)
		"right": return Vector2(17.0, 12.0)
		"back": return Vector2(13.0, 0.0)
		_: return Vector2(15.0, 14.0)

static func alignment_offset(animation_name: String, frame_index: int, face: String) -> Vector2:
	var points: PackedVector2Array = span(animation_name, frame_index, face)
	return target_grip(face) - points[0] if points.size() == 2 else Vector2.ZERO

static func rendered_span(body: AnimatedSprite2D, face: String) -> PackedVector2Array:
	if body == null:
		return PackedVector2Array()
	var animation_name: String = str(body.animation)
	var frame: int = 0 if GENTLE.modular_idle(animation_name) and animation_name.begins_with("wand_idle_") else body.frame
	var points: PackedVector2Array = span(animation_name, frame, face)
	if points.size() != 2:
		return points
	var grip: Vector2 = points[0]
	var tip: Vector2 = points[1]
	if animation_name.begins_with("wand_idle_") and GENTLE.modular_idle(animation_name):
		var angle: float = GENTLE.angle_at(GENTLE.phase_of(body))
		tip = grip + (tip - grip).rotated(angle)
	var delta: Vector2 = target_grip(face) - grip
	return PackedVector2Array([grip + delta, tip + delta])

static func world_tip(actor: Node2D) -> Vector2:
	if actor == null:
		return Vector2.ZERO
	var body: AnimatedSprite2D = actor.get_node_or_null("Ghost") as AnimatedSprite2D
	if body == null:
		return actor.global_position + Vector2(0.0, -44.0)
	var points: PackedVector2Array = rendered_span(body, str(actor.get("facing_name")))
	if points.size() != 2:
		return actor.global_position + Vector2(0.0, -44.0)
	return body.to_global(points[1])
