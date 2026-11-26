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
	assert(ART.wrist("sword_modular_idle_back_left",0) == Vector2.INF)
	assert(ART.action_clip("dodge","back_left","dodge_back",frames) == "dodge_back")
	if frames.has_animation("jump_front_right"):
		assert(frames.get_frame_count("jump_front_right") == 8)
		assert(not frames.get_animation_loop("jump_front_right"))
	print("v248 diagonal art: frame structure, wrist guides, action fallbacks")
	quit(0)
