extends SceneTree
const ACTION = preload("res://scripts/action_motion_samples_v225.gd")
const WAND = preload("res://scripts/wand_anchors_v216.gd")
const SOURCE = preload("res://scripts/walk_inbetweens_v223.gd")
const MOTION = preload("res://scripts/gentle_weapon_motion_v191.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var frames: SpriteFrames = SpriteFrames.new()
	var names: Array[String] = ["dodge_front", "wand_cast_front", "attack_wand_heavy_front"]
	var originals: Dictionary = {}
	for name in names:
		var count: int = 16 if name.begins_with("dodge_") else 8
		var keys: Array[Texture2D] = []
		frames.add_animation(name)
		frames.set_animation_loop(name, false)
		frames.set_animation_speed(name, 16.0)
		for i in range(count):
			var image: Image = Image.create_empty(8, 8, false, Image.FORMAT_RGBA8)
			image.fill(Color.TRANSPARENT)
			image.fill_rect(Rect2i(1 + i % 2, 1, 4, 6), Color(float(i) / float(count), 0.3, 0.7, 1.0))
			var texture: ImageTexture = ImageTexture.create_from_image(image)
			keys.append(texture)
			frames.add_frame(name, texture, 1.0 + float(i % 2) * 0.5)
		originals[name] = keys
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	ACTION.install(sprite)
	for name in names:
		var target: int = ACTION.target_count(name)
		if target == 0:
			if frames.get_frame_count(name) != 8:
				_fail("Unrelated wand attack changed")
				return
			continue
		if frames.get_frame_count(name) != target or frames.get_animation_loop(name):
			_fail("Sample count or loop flag wrong")
			return
		var source_keys: Array = originals[name]
		var map: Array[int] = ACTION.source_map(source_keys.size())
		var total: float = 0.0
		sprite.animation = name
		for i in range(target):
			var mapped: int = SOURCE.source_pose_index(frames, name, i)
			if mapped != map[i]:
				_fail("Pose index drifted from sample mapping")
				return
			var actual: Image = frames.get_frame_texture(name, i).get_image()
			var base: Image = source_keys[mapped].get_image()
			for y in range(8):
				for x in range(8):
					if not is_equal_approx(actual.get_pixel(x, y).a, base.get_pixel(x, y).a):
						_fail("New frame changed original silhouette")
						return
			if name.begins_with("wand_cast_"):
				sprite.set_frame_and_progress(i, 0.5)
				if WAND.visible_frame(sprite) != mapped:
					_fail("Wand atlas index disagrees with body")
					return
				var span: PackedVector2Array = WAND.rendered_span(sprite, "front")
				if span.size() != 2 or span[0].distance_to(WAND.target_grip("front", name, mapped)) > 0.02:
					_fail("Wand effect or muzzle grip drift")
					return
			total += frames.get_frame_duration(name, i)
		for key in source_keys:
			var found: bool = false
			for i in range(target):
				if frames.get_frame_texture(name, i) == key:
					found = true
			if not found:
				_fail("Approved original keyframe missing")
				return
		if not is_equal_approx(total, float(source_keys.size()) * 1.25) or not is_equal_approx(frames.get_frame_duration(name, target - 1), 1.5):
			_fail("Weighted duration or final hold changed")
			return
		var rate: float = MOTION.playback_rate(frames, name, 0.6)
		if not is_equal_approx(total / (16.0 * rate), 0.6):
			_fail("Timed clip duration changed")
			return
	ACTION.install(sprite)
	if frames.get_frame_count("dodge_front") != 24 or frames.get_frame_count("wand_cast_front") != 22:
		_fail("Repeated install duplicated frames")
		return
	if ACTION.dodge_flow(0.0).length() > 0.001 or ACTION.dodge_flow(1.0).length() > 0.001 or not is_equal_approx(ACTION.landing_weight(0.5), 0.5):
		_fail("Motion endpoints not eased")
		return
	sprite.free()
	print("v2.25 PASS: dodge/cast samples, preserved weighted timing and keyframes, shared wand guides, eased visual recovery")
	quit(0)

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
