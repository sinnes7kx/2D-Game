extends SceneTree
const ART = preload("res://scripts/ghost_diagonal_art_v247.gd")

func _initialize() -> void:
	var frames: SpriteFrames = SpriteFrames.new()
	for cardinal in ["front", "back"]:
		for action in ["idle", "walk"]:
			var name: String = action + "_" + cardinal
			frames.add_animation(name)
			frames.set_animation_speed(name, 6.0)
			for i in range(8):
				frames.add_frame(name, GradientTexture2D.new())
	if ART.available():
		assert(ART.install(frames))
		for direction in ART.DIRECTIONS:
			for action in ["idle", "walk"]:
				assert(frames.get_frame_count(action + "_" + direction) == 8)
	else:
		assert(not ART.install(frames))
	# Test resolver even when the optional image has not been installed.
	if not frames.has_animation("idle_front_right"):
		frames.add_animation("idle_front_right")
	assert(ART.resolve("idle_front", "front_right", "front", false, frames) == "idle_front_right")
	assert(ART.resolve("idle_front", "front_right", "front", true, frames) == "idle_front")
	assert(ART.resolve("sword_idle_front", "front_right", "front", false, frames) == "sword_idle_front")
	assert(ART.resolve("attack_front", "front_right", "front", false, frames) == "attack_front")
	assert(ART.resolve("idle_front", "front", "front", false, frames) == "idle_front")
	if frames.has_animation("sword_modular_idle_front_right"):
		assert(ART.armed_clip("sword_modular_idle_front", "front_right", "front", frames) == "sword_modular_idle_front_right")
	assert(ART.wrist("sword_modular_idle_front_right",0) != Vector2.INF)
	assert(ART.cardinal_for_clip("wand_walk_back_left") == "back")
	assert(ART.cardinal_for_clip("sword_modular_idle_front_right") == "front")
	if frames.has_animation("sword_modular_idle_back_left"):
		assert(ART.wrist("sword_modular_idle_back_left",0) != Vector2.INF)
	if frames.has_animation("dodge_back_left"):
		assert(ART.action_clip("dodge","back_left","dodge_back",frames) == "dodge_back_left")
	else:
		assert(ART.action_clip("dodge","back_left","dodge_back",frames) == "dodge_back")
	if frames.has_animation("jump_front_right"):
		assert(frames.get_frame_count("jump_front_right") == 8)
		assert(not frames.get_animation_loop("jump_front_right"))
	for prefix in ["scythe_", "halberd_", "maul_", "ashglass_maul_", "forge_bow_"]:
		var clip: String = prefix + "walk_front_right"
		for i in range(8):
			var points: PackedVector2Array = ART.carried_span(clip,i,70.0,true)
			assert(points.size()==2 and points[0]==ART.wrist(clip,i))
			assert(is_equal_approx(points[0].distance_to(points[1]),70.0))
		if frames.has_animation(clip):
			assert(ART.armed_clip(prefix+"walk_front","front_right","front",frames)==clip)
	var wand = preload("res://scripts/wand_anchors_v216.gd")
	var result: PackedVector2Array = wand.transformed_span(PackedVector2Array([Vector2(12,5),Vector2(32,-10)]),Vector2(-20,30),0.17)
	assert(result[0]==Vector2(-20,30))
	assert(result[1].is_equal_approx(Vector2(-20,30)+Vector2(20,-15).rotated(0.17)*wand.VISUAL_SCALE))
	var audio = preload("res://scripts/combat_juice_v194.gd")
	for cue in ["blunt_hit","blade_hit","bow_release","crossbow_fire","crossbow_reload","dagger_swing","polearm_swing"]:
		var stream: AudioStreamWAV = audio._render(cue)
		assert(stream.mix_rate==audio.RATE and stream.data.size()>1000)
	print("v257 diagonal anchors, shared wand transform and audio cue assertions")
	quit(0)
