extends SceneTree
const DIAGONAL = preload("res://scripts/ghost_diagonal_art_v247.gd")
const BOW = preload("res://scripts/bow_palette_overlay_v139.gd")
const DIRECTION = preload("res://scripts/direction_controller_v245.gd")
const AIR = preload("res://scripts/airborne_attacks_v203.gd")
const PLAY = preload("res://scripts/animation/directional_playback.gd")
const RENDER = preload("res://scripts/animation/weapon_render_contract.gd")

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
		for style in ["thornrose","moonveil"]:
			for action in ["light","heavy"]:
				var requested: String = "attack_"+style+"_"+action+"_"+cardinal
				var clip: String = "attack_"+style+"_"+action+"_"+direction
				var air: String = AIR.air_name(clip)
				assert(AIR.base_name(air)==clip and AIR.air_name(air)==air)
				assert(DIAGONAL.is_painted_bow_combat(clip) and DIAGONAL.is_painted_bow_combat(air))
				assert(DIAGONAL.combat_body_source_v294(clip)=="idle_"+direction)
				assert(DIAGONAL.combat_body_source_v294(air)=="jump_"+direction)
				frames.add_animation(clip)
				frames.add_animation(air)
				var texture: GradientTexture2D = GradientTexture2D.new()
				texture.gradient = Gradient.new()
				frames.add_frame(clip, texture)
				frames.add_frame(air, texture)
				assert(PLAY.action_clip(requested,direction,frames)==clip)
				assert(PLAY.action_clip(AIR.air_name(requested),direction,frames)==air)
				for i in range(8):
					var wrist: Vector2 = Vector2(-24.0 if left else 24.0, 30.0)
					var heading: Vector2 = DIAGONAL.heading_v294(direction)
					var pose: Dictionary = BOW.diagonal_shoot_pose(clip,wrist,heading,style,float(i))
					var angle: float = deg_to_rad(float(pose["rotation_deg"]))
					assert(((pose["position"] as Vector2)+(pose["source_handle"] as Vector2).rotated(angle)).is_equal_approx(wrist))
					var chord: Vector2 = Vector2(17.1,88.5) if style=="moonveil" else Vector2(16.4,87.7)
					if left:
						chord.x = -chord.x
					if i<6:
						assert(absf(chord.rotated(angle).normalized().dot(heading))<0.001)
					assert(bool(pose["behind"])==rear)
					count+=1
	for direction_index in range(8):
		var heading: Vector2 = DIRECTION.heading(direction_index)
		for hand in [-1,0,1]:
			var axis: Vector2 = RENDER.guard_axis(heading,Vector2(12,20),hand)
			assert(axis.is_finite() and is_equal_approx(axis.length(),1.0) and axis.y<0.0)
	for dx in [-1,1]:
		for dy in [-1,1]:
			var movement: Vector2 = DIRECTION.digital_vector(dx<0,dx>0,dy<0,dy>0)
			assert(is_equal_approx(movement.length(),1.0))
	print("v2.75 bow diagonal carry, shooting, airborne aliases and guard axes PASS: ",count," samples")
	quit(0)
