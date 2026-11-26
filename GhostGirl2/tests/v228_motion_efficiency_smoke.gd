extends SceneTree
const MOTION = preload("res://scripts/gentle_weapon_motion_v191.gd")
const SILK = preload("res://scripts/silk_motion_v226.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var frames: SpriteFrames = SpriteFrames.new()
	var image: Image = Image.create_empty(256, 220, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture: Texture2D = ImageTexture.create_from_image(image)
	for name in ["walk_front", "blink_front"]:
		frames.add_animation(name)
		for weight in [0.5, 2.0, 1.0, 3.0]:
			frames.add_frame(name, texture, weight)
	var body: AnimatedSprite2D = AnimatedSprite2D.new()
	body.sprite_frames = frames
	body.animation = "walk_front"
	var expected: Array[float] = []
	for i in range(4):
		body.set_frame_and_progress(i, 0.37)
		expected.append(MOTION.phase_of(body))
	MOTION.prepare_timing(frames)
	for i in range(4):
		body.set_frame_and_progress(i, 0.37)
		if not is_equal_approx(MOTION.phase_of(body), expected[i]):
			_fail("Cached phase differs from weighted source")
			return
	frames.emit_changed()
	if frames.has_meta(MOTION.TIMING_META):
		_fail("Timing cache did not invalidate")
		return
	MOTION.prepare_timing(frames)
	var material: ShaderMaterial = ShaderMaterial.new()
	material.shader = load("res://assets/equipment/dress_palette.gdshader")
	body.material = material
	var flow = SILK.new()
	flow.update(body, Vector2(160, 0), 0.1, false)
	var moving: Vector2 = flow.cloth_lag
	body.animation = "blink_front"
	flow.update(body, Vector2.ZERO, 0.05, false)
	if flow.cloth_lag.length() <= 0.0 or flow.cloth_lag.length() >= moving.length() or flow.was_active:
		_fail("Hidden clip reset inertia or stayed warped")
		return
	body.animation = "walk_front"
	var prior: Vector2 = flow.cloth_lag
	flow.update(body, Vector2.ZERO, 0.05, true)
	if flow.cloth_lag != prior or not flow.was_active:
		_fail("Hitstop changed silk motion")
		return
	SILK.enabled = false
	flow.update(body, Vector2.ZERO, 0.05, false)
	SILK.enabled = true
	if flow.cloth_lag != Vector2.ZERO or flow.was_active:
		_fail("Off did not reset motion")
		return
	body.free()
	print("v2.28 PASS: weighted phase cache equivalence and invalidation; hidden pose inertia and hitstop")
	quit(0)

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
