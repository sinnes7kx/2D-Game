extends SceneTree
## Synthetic frame sequences, no user saves or original art modifications.
const SWORD = preload("res://scripts/sword_attack_frames_v224.gd")
const MOTION = preload("res://scripts/gentle_weapon_motion_v191.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var frames: SpriteFrames = SpriteFrames.new()
	var keys: Array[Texture2D] = []
	for i in range(8):
		var picture: Image = Image.create_empty(8, 8, false, Image.FORMAT_RGBA8)
		picture.fill(Color.TRANSPARENT)
		picture.fill_rect(Rect2i(1 + i % 2, 1, 4, 6), Color(float(i) / 8.0, 0.4, 0.8, 1.0))
		keys.append(ImageTexture.create_from_image(picture))
	var names: Array[String] = ["attack_sword_light_front", "attack_sword_heavy_front", "attack_sword_heavy_air_front", "attack_unarmed_light_front"]
	for name in names:
		frames.add_animation(name)
		frames.set_animation_loop(name, false)
		frames.set_animation_speed(name, 16.0)
		for i in range(8):
			frames.add_frame(name, keys[i], 1.0 + float(i % 2) * 0.5)
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	SWORD.install(sprite)
	for name in names:
		if not SWORD.matches_ground(name):
			if frames.get_frame_count(name) != 8 or SWORD.has_samples(frames, name):
				_fail("Frame-indexed air/unarmed clip changed")
				return
			continue
		if frames.get_frame_count(name) != 22 or frames.get_animation_loop(name):
			_fail("Ground clip sample count or loop flag wrong")
			return
		var total: float = 0.0
		for i in range(22):
			total += frames.get_frame_duration(name, i)
			var pose: int = SWORD.source_pose_index(frames, name, i)
			var expected: int = mini(floori(float(i + 1) / 3.0), 7)
			if pose != expected:
				_fail("Blade guide did not select visible source silhouette")
				return
			var actual: Image = frames.get_frame_texture(name, i).get_image()
			var original: Image = keys[pose].get_image()
			for y in range(8):
				for x in range(8):
					if not is_equal_approx(actual.get_pixel(x, y).a, original.get_pixel(x, y).a):
						_fail("Intermediate damaged blade/body alpha")
						return
			if i % 3 == 0 and frames.get_frame_texture(name, i) != keys[floori(float(i) / 3.0)]:
				_fail("Original sword pose replaced")
				return
		if not is_equal_approx(total, 10.0) or not is_equal_approx(frames.get_frame_duration(name, 21), 1.5):
			_fail("Non-looping final hold or total action duration changed")
			return
		var rate: float = MOTION.playback_rate(frames, name, 0.4)
		if not is_equal_approx(total / (16.0 * rate), 0.4):
			_fail("Expanded clip no longer fits original combat timer")
			return
	if frames.get_frame_texture(names[0], 1) != frames.get_frame_texture(names[1], 1):
		_fail("Shared light/heavy samples unnecessarily duplicated")
		return
	SWORD.install(sprite)
	if frames.get_frame_count(names[0]) != 22:
		_fail("Attack expansion not idempotent")
		return
	if SWORD.motion_at(0.0, false).length() > 0.001 or SWORD.motion_at(1.0, true).length() > 0.001:
		_fail("Anticipation/recovery does not return to neutral")
		return
	for i in range(101):
		var flow: Vector3 = SWORD.motion_at(float(i) / 100.0, true)
		if absf(flow.x) > 4.0 or absf(flow.y) > 4.0 or absf(flow.z) > 0.10:
			_fail("Visual motion outside bounded transform")
			return
	sprite.free()
	var player_source: String = FileAccess.get_file_as_string("res://scripts/player.gd")
	if not player_source.contains("body_art.speed_scale = 1.0\n\taction_animation_rate = 1.0") or not player_source.contains("body_art.play(body_art.animation, action_animation_rate)") or not player_source.contains("body_art.set_frame_and_progress(frame_index, fraction)"):
		_fail("Timed playback or hitstop resume wiring missing")
		return
	print("v2.24 PASS: 22 ground sword samples, aligned silhouette guides, weighted timing, final hold and bounded follow-through")
	quit(0)

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
