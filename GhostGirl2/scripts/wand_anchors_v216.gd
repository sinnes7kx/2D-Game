extends RefCounted
## One authored wand grip/tip geometry source for equipment, light and casts.
## Coordinates are Ghost-local; scene transforms are respected via to_global.
const PATH: String = "res://resources/wand_pose_guides_v163.json"
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

static func world_tip(actor: Node2D) -> Vector2:
	if actor == null:
		return Vector2.ZERO
	var body: AnimatedSprite2D = actor.get_node_or_null("Ghost") as AnimatedSprite2D
	if body == null:
		return actor.global_position + Vector2(0.0, -44.0)
	var animation_name: String = str(body.animation)
	var face: String = str(actor.get("facing_name"))
	var points: PackedVector2Array = span(animation_name, body.frame, face)
	if points.size() != 2:
		return actor.global_position + Vector2(0.0, -44.0)
	return body.to_global(points[1])
