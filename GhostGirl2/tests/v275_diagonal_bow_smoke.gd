extends SceneTree
const DIAGONAL = preload("res://scripts/ghost_diagonal_art_v247.gd")
const BOW = preload("res://scripts/bow_palette_overlay_v139.gd")
const DIRECTION = preload("res://scripts/direction_controller_v245.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var frames: SpriteFrames = SpriteFrames.new()
	var count: int = 0
	for direction in DIAGONAL.DIRECTIONS:
		var cardinal: String = "back" if direction.begins_with("back") else "front"
		var left: bool = direction.ends_with("left")
		var rear: bool = direction.begins_with("back")
		for family in ["thornrose", "moonveil", "forge_bow"]:
			for motion in ["idle", "walk"]:
				var clip: String = family + "_" + motion + "_" + direction
				var fallback: String = family + "_" + motion + "_" + cardinal
				assert(DIAGONAL.armed_clip(fallback,direction,cardinal,frames)==fallback)
				frames.add_animation(clip)
				assert(DIAGONAL.armed_clip(fallback,direction,cardinal,frames)==clip)
				for i in range(8):
					var wrist: Vector2 = Vector2((-30.0 if left else 30.0)+float(i),20.0-float(i))
					var pose: Dictionary = BOW.diagonal_hold_pose(clip,wrist)
					var source: Vector2 = pose["source_handle"]
					var position: Vector2 = pose["position"]
					assert((position+source.rotated(deg_to_rad(float(pose["rotation_deg"])))).is_equal_approx(wrist))
					assert(bool(pose["flip_h"])==left)
					assert(bool(pose["behind"])==rear)
					count+=1
		assert(BOW.diagonal_hold_pose("thornrose_walk_"+direction,Vector2.INF).is_empty())
		for motion in ["jump","dodge"]:
			var action: String = "moonveil_"+motion+"_"+direction
			frames.add_animation(action)
			assert(DIAGONAL.armed_action_clip(motion,"moonveil_walk_",direction,"fallback",frames)==action)
	for dx in [-1,1]:
		for dy in [-1,1]:
			var movement: Vector2 = DIRECTION.digital_vector(dx<0,dx>0,dy<0,dy>0)
			assert(is_equal_approx(movement.length(),1.0))
	print("v2.75 bow diagonal pivot/alias PASS: ",count," samples")
	quit(0)
