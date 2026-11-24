extends SceneTree
const MOTION = preload("res://scripts/gentle_weapon_motion_v191.gd")
func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var neutral: PackedVector2Array = PackedVector2Array([Vector2(23, 25), Vector2(-45, 15)])
	var previous: Vector2 = neutral[1]
	for i in range(321):
		var phase: float = float(i) / 320.0
		var span: PackedVector2Array = MOTION.rotate_span(neutral, phase)
		if span[0] != neutral[0] or not is_equal_approx(span[0].distance_to(span[1]), neutral[0].distance_to(neutral[1])):
			_fail("Idle movement shifted grip or stretched blade")
			return
		if previous.distance_to(span[1]) > 0.2:
			_fail("Idle rotation jumped between samples")
			return
		previous = span[1]
	if not previous.is_equal_approx(neutral[1]) or absf(MOTION.angle_at(0.25)) < 0.05:
		_fail("Idle rotation is not seamless or is stationary")
		return
	var actor: Node = (load("res://scenes/player.tscn") as PackedScene).instantiate()
	root.add_child(actor)
	var body: AnimatedSprite2D = actor.get_node("Ghost") as AnimatedSprite2D
	var frames: SpriteFrames = body.sprite_frames
	var checked: int = 0
	for value in frames.get_animation_names():
		var name: String = str(value)
		if not MOTION.modular_idle(name) or not frames.get_animation_loop(name):
			continue
		var first: Texture2D = frames.get_frame_texture(name, 0)
		var sum: float = 0.0
		for i in range(frames.get_frame_count(name)):
			if frames.get_frame_texture(name, i) != first:
				_fail("Idle still jumps among body poses: " + name)
				return
			sum += frames.get_frame_duration(name, i)
		if not is_equal_approx(sum / frames.get_animation_speed(name), MOTION.CYCLE_SECONDS):
			_fail("Idle clock does not match smooth cycle")
			return
		body.animation = name
		body.set_frame_and_progress(0, 0.5)
		if MOTION.phase_of(body) <= 0.0:
			_fail("Subframe progress ignored")
			return
		checked += 1
	if checked < 16 or MOTION.modular_idle("attack_rosemirror_twinblade_heavy_left"):
		_fail("Idle coverage or attack separation incorrect")
		return
	var ink: Color = MOTION.softened(Color(0.8,0.5,0.2,0.8))
	if not is_equal_approx(ink.a,0.8 * MOTION.EFFECT_ALPHA) or not is_equal_approx(ink.r,0.8):
		_fail("Transparency changed palette")
		return
	print("v1.91 PASS: ",checked," stable idle loops, continuous hand-locked rotation, preserved blade length and translucent effects")
	actor.free()
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
