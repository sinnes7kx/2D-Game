extends RefCounted
## One authored wand grip/tip geometry source for equipment, light and casts.
## Coordinates are Ghost-local; scene transforms are respected via to_global.
const PATH: String = "res://resources/wand_pose_guides_v163.json"
const GENTLE = preload("res://scripts/gentle_weapon_motion_v191.gd")
const HAND = preload("res://scripts/dagger_thrust_v186.gd")
const SAMPLES = preload("res://scripts/walk_inbetweens_v223.gd")
const VISUAL_SCALE: float = 1.20
static var _rows: Dictionary = {}

static func rows() -> Dictionary:
	if _rows.is_empty() and FileAccess.file_exists(PATH):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary:
			_rows = parsed.get("animations", {}) as Dictionary
	return _rows

static func is_wand_pose(animation_name: String) -> bool:
	return animation_name.begins_with("wand_") or animation_name.begins_with("attack_wand_")

static func pose_name(animation_name: String, face: String) -> String:
	var diagonal: String = preload("res://scripts/ghost_diagonal_art_v247.gd").diagonal_name(animation_name)
	if not diagonal.is_empty() and is_wand_pose(animation_name):
		var side: String = "left" if diagonal.ends_with("left") else "right"
		var action: String = "cast" if animation_name.contains("_cast_") or animation_name.begins_with("attack_") else ("walk" if animation_name.contains("_walk_") else "idle")
		return "wand_" + action + "_" + side
	if animation_name.begins_with("attack_wand_"):
		return "wand_cast_" + face
	return animation_name if rows().has(animation_name) else "wand_idle_" + face

static func body_frame(animation_name: String, frame: int) -> int:
	if animation_name.begins_with("wand_idle_"):
		return 0
	if animation_name.begins_with("wand_walk_"):
		var steps: Array[int] = [0, 1, 2, 1, 0, 1, 2, 1]
		return steps[posmod(frame, steps.size())]
	return clampi(frame, 0, 7)

static func install(body: AnimatedSprite2D) -> void:
	if body == null or body.sprite_frames == null:
		return
	var frames: SpriteFrames = body.sprite_frames
	for face in ["front", "back", "left", "right"]:
		var source: String = "attack_unarmed_light_" + face
		if not frames.has_animation(source) or frames.get_frame_count(source) < 8:
			continue
		for prefix in ["wand_idle_", "wand_walk_", "wand_cast_", "attack_wand_heavy_"]:
			var name: String = prefix + face
			if not frames.has_animation(name):
				continue
			for i in range(frames.get_frame_count(name)):
				var index: int = body_frame(name, i)
				frames.set_frame(name, i, frames.get_frame_texture(source, index), frames.get_frame_duration(name, i))

static func span(animation_name: String, frame_index: int, face: String = "front") -> PackedVector2Array:
	var record: Dictionary = rows().get(pose_name(animation_name, face), {})
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
static func target_grip(face: String, animation_name: String = "", frame_index: int = 0) -> Vector2:
	var diagonal: Vector2 = preload("res://scripts/ghost_diagonal_art_v247.gd").wrist(animation_name, frame_index)
	if diagonal != Vector2.INF:
		return diagonal
	var index: int = body_frame(animation_name, frame_index)
	var wrist: Vector2 = HAND.hand_anchor(face, index, 0 if face == "left" else 1)
	if wrist != Vector2.INF:
		return wrist
	return Vector2(42.0, 28.0) if face == "back" else Vector2(0.0, 25.0)

static func alignment_offset(animation_name: String, frame_index: int, face: String) -> Vector2:
	var points: PackedVector2Array = span(animation_name, frame_index, face)
	return target_grip(face, animation_name, frame_index) - points[0] if points.size() == 2 else Vector2.ZERO

static func visible_frame(body: AnimatedSprite2D) -> int:
	if body == null:
		return 0
	var name: String = str(body.animation)
	if not preload("res://scripts/ghost_diagonal_art_v247.gd").diagonal_name(name).is_empty():
		var guide_name: String = pose_name(name, "front")
		var record: Dictionary = rows().get(guide_name, {})
		var guides: Array = record.get("guides", [])
		var count: int = mini(maxi(1, int(record.get("count", 8))), maxi(1, guides.size()))
		return 0 if name.contains("_idle_") else clampi(body.frame, 0, count - 1)
	return 0 if name.begins_with("wand_idle_") else SAMPLES.source_pose_index(body.sprite_frames, name, body.frame)

static func rendered_span(body: AnimatedSprite2D, face: String) -> PackedVector2Array:
	if body == null:
		return PackedVector2Array()
	var animation_name: String = str(body.animation)
	var frame: int = visible_frame(body)
	var points: PackedVector2Array = span(animation_name, frame, face)
	if points.size() != 2:
		return points
	var grip: Vector2 = points[0]
	var wrist: Vector2 = preload("res://scripts/ghost_diagonal_art_v247.gd").wrist(animation_name, body.frame)
	if wrist == Vector2.INF:
		wrist = target_grip(face,animation_name,frame)
	return transformed_span(points,wrist,pose_rotation_v294(body,points))

static func pose_rotation_v294(body: AnimatedSprite2D,points: PackedVector2Array) -> float:
	var clip: String = str(body.animation)
	if clip.begins_with("wand_idle_"):
		return GENTLE.angle_at(GENTLE.phase_of(body))
	var diagonal = preload("res://scripts/ghost_diagonal_art_v247.gd")
	if points.size()==2 and diagonal.is_modular_combat_v294(clip) and (clip.begins_with("wand_cast_") or clip.begins_with("attack_wand_")):
		var heading: Vector2 = diagonal.heading_v294(diagonal.diagonal_name(clip))
		var local_heading: Vector2 = body.to_local(body.global_position+heading)
		if not local_heading.is_zero_approx() and points[0].distance_squared_to(points[1])>0.01:
			return (points[1]-points[0]).angle_to(local_heading)
	return 0.0

# Same transform used by equipment_visuals: scale and rotate about authored
# grip, then translate that grip to the actual visible wrist.
static func transformed_span(points: PackedVector2Array, wrist: Vector2, angle: float) -> PackedVector2Array:
	if points.size() != 2:
		return points
	return PackedVector2Array([wrist,wrist+((points[1]-points[0])*VISUAL_SCALE).rotated(angle)])

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
