extends SceneTree
## v2.22: pure timing / grip tests plus scene configuration, no user saves.
const MOTION = preload("res://scripts/gentle_weapon_motion_v191.gd")
const STEADY = preload("res://scripts/steady_weapon_idles_v195.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.add_animation("attack_test")
	frames.set_animation_speed("attack_test", 12.0)
	var image: Image = Image.create_empty(4, 4, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	frames.add_frame("attack_test", texture, 1.0)
	frames.add_frame("attack_test", texture, 2.0)
	frames.add_frame("attack_test", texture, 0.5)
	var rate: float = MOTION.playback_rate(frames, "attack_test", 0.5)
	if not is_equal_approx(3.5 / (12.0 * rate), 0.5):
		_fail("Unequal frame weights changed action duration")
		return
	var current: PackedVector2Array = PackedVector2Array([Vector2(10, 20), Vector2(50, 20)])
	var next: PackedVector2Array = PackedVector2Array([Vector2(40, 70), Vector2(40, 110)])
	var middle: PackedVector2Array = MOTION.subframe_span(current, next, 0.5)
	if middle.size() != 2 or middle[0] != current[0] or not is_equal_approx(middle[0].distance_to(middle[1]), 40.0):
		_fail("Subframe pose detached the grip or shortened the blade")
		return
	if not is_equal_approx((middle[1] - middle[0]).angle(), PI * 0.25):
		_fail("Subframe blade angle not interpolated")
		return
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.animation = "attack_test"
	sprite.set_frame_and_progress(0, 0.5)
	if not is_equal_approx(MOTION.attack_fraction(sprite, "attack_test", 0), 0.5):
		sprite.free()
		_fail("Frame progress not used")
		return
	sprite.set_frame_and_progress(2, 0.8)
	if MOTION.attack_fraction(sprite, "attack_test", 2) != 0.0:
		sprite.free()
		_fail("Last attack pose interpolated beyond clip")
		return
	sprite.free()
	if STEADY.SWORD_STEPS != 24 or not is_equal_approx(STEADY.CYCLE_SECONDS, 3.45):
		_fail("Idle sampling changed cycle")
		return
	if not bool(ProjectSettings.get_setting("physics/common/physics_interpolation", false)) or int(ProjectSettings.get_setting("physics/common/physics_ticks_per_second", 60)) != 60:
		_fail("Physics/render decoupling configuration missing")
		return
	var scene_text: String = FileAccess.get_file_as_string("res://scenes/player.tscn")
	var main_text: String = FileAccess.get_file_as_string("res://scenes/main.tscn")
	if not scene_text.contains("physics_interpolation_mode = 1") or not main_text.contains("physics_interpolation_mode = 2"):
		_fail("Interpolation must be scoped to player rather than entire world")
		return
	print("v2.22 PASS: weighted timing, wrist-locked subframe angles, last-frame safety, 24 idle samples, scoped interpolation")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
