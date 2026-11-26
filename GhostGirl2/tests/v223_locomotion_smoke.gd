extends SceneTree
## Synthetic source textures only; no user saves or imported artwork writes.
const WALK = preload("res://scripts/walk_inbetweens_v223.gd")
const MOTION = preload("res://scripts/gentle_weapon_motion_v191.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var frames: SpriteFrames = SpriteFrames.new()
	var originals: Dictionary = {}
	for face in ["front", "right", "back", "left"]:
		var name: String = "walk_" + face
		frames.add_animation(name)
		frames.set_animation_speed(name, 8.0)
		frames.set_animation_loop(name, true)
		var keys: Array[Texture2D] = []
		for i in range(8):
			var picture: Image = Image.create_empty(8, 8, false, Image.FORMAT_RGBA8)
			picture.fill(Color.TRANSPARENT)
			picture.fill_rect(Rect2i(1 + i % 2, 1, 4, 6), Color(float(i) / 8.0, 0.2, 0.8, 1.0))
			var texture: ImageTexture = ImageTexture.create_from_image(picture)
			keys.append(texture)
			frames.add_frame(name, texture, 1.0 + float(i % 2) * 0.5)
		originals[name] = keys
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	WALK.install(sprite)
	for name in originals:
		if frames.get_frame_count(name) != 24 or not is_equal_approx(frames.get_animation_speed(name), 24.0):
			_fail("Walk cycle was not expanded")
			return
		var total: float = 0.0
		for i in range(24):
			total += frames.get_frame_duration(name, i)
			var source: int = WALK.source_pose_index(frames, name, i)
			if source != posmod(floori(float(i + 1) / 3.0), 8):
				_fail("Original pose mapping drifted")
				return
			var base: Image = originals[name][source].get_image()
			var actual: Image = frames.get_frame_texture(name, i).get_image()
			for y in range(8):
				for x in range(8):
					if not is_equal_approx(base.get_pixel(x, y).a, actual.get_pixel(x, y).a):
						_fail("Intermediate frame damaged silhouette")
						return
			if i % 3 == 0 and frames.get_frame_texture(name, i) != originals[name][floori(float(i) / 3.0)]:
				_fail("Approved keyframe replaced")
				return
		if not is_equal_approx(total / 24.0, 1.25):
			_fail("Weighted cycle duration changed")
			return
	WALK.install(sprite)
	if frames.get_frame_count("walk_front") != 24:
		_fail("Walk expansion was not idempotent")
		return
	sprite.animation = "walk_front"
	sprite.set_frame_and_progress(13, 0.4)
	var phase: float = MOTION.phase_of(sprite)
	sprite.animation = "walk_right"
	MOTION.seek_phase(sprite, phase)
	if not is_equal_approx(MOTION.phase_of(sprite), phase):
		_fail("Turn restarted stride")
		return
	if not MOTION.same_walk_family("wand_walk_left", "wand_walk_back") or MOTION.same_walk_family("walk_left", "sword_walk_left") or MOTION.same_walk_family("walk_left", "attack_sword_light_left"):
		_fail("Walk phase crossed weapon or attack family")
		return
	if MOTION.gait_motion(0.0, 0.0) != Vector2.ZERO or MOTION.gait_motion(0.25, 1.5).length() > 2.0:
		_fail("Gait overlay outside visual bounds")
		return
	sprite.free()
	print("v2.23 PASS: 96 walk samples, exact keyframes, alpha preservation, weighted phase transfer and bounded gait")
	quit(0)

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
