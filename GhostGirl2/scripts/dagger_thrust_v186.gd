extends RefCounted
## Eight-frame dagger thrusts use intact, original character poses.
## No frame four's baked slash arc, no head reconstruction or mirrored body.
const SINGLE_LENGTH: float = 54.0
const PAIRED_LENGTH: float = 50.0

static func sequence(heavy: bool) -> Array[int]:
	# Explicit typed array construction avoids Godot 4.7's ternary Array
	# coercion problem when this mapping is assigned to another typed array.
	var frames: Array[int] = [0, 1, 2, 3, 3, 5, 6, 7]
	if heavy:
		frames[1]=2
	return frames

static func install(sprite: AnimatedSprite2D) -> void:
	var frames: SpriteFrames = sprite.sprite_frames
	if frames == null:
		return
	for art in ["dagger", "nocturne_dagger", "dual_dagger"]:
		for action in ["pierce", "heavy_pierce"]:
			for face in ["front", "back", "left", "right"]:
				var source: String = "attack_unarmed_light_" + face
				if not frames.has_animation(source) or frames.get_frame_count(source) < 8:
					continue
				var target: String = "attack_" + art + "_" + action + "_" + face
				if frames.has_animation(target):
					frames.remove_animation(target)
				frames.add_animation(target)
				frames.set_animation_loop(target, false)
				frames.set_animation_speed(target, 16.0 if action == "pierce" else 12.0)
				for index in sequence(action == "heavy_pierce"):
					frames.add_frame(target, frames.get_frame_texture(source, index))

static func direction(face: String) -> Vector2:
	match face:
		"left": return Vector2.LEFT
		"right": return Vector2.RIGHT
		"back": return Vector2.UP
		_: return Vector2.DOWN

static func span(face: String, frame: int, hand: int, heavy: bool, paired: bool) -> PackedVector2Array:
	var n: int = clampi(frame, 0, 7)
	var anchor: Vector2 = hand_anchor(face, sequence(heavy)[n], hand)
	if anchor == Vector2.INF:
		return PackedVector2Array()
	var forward: Vector2 = direction(face)
	var lateral: Vector2 = Vector2(-forward.y, forward.x)
	# Pull the knife in, extend the point along the attack heading, then recover.
	# The grip never slides away from the hand. A rear/guard dagger remains
	# closer to the body while the lead dagger thrusts.
	var lead: bool = not paired or (hand == 0 if face == "left" else hand == 1)
	var angles: Array[float] = [-0.75, -0.95, -0.40, 0.0, 0.0, 0.17, -0.45, -0.75]
	var aim: Vector2 = (forward + lateral * angles[n] * (-1.0 if hand == 0 else 1.0)).normalized()
	if not lead and n in [2, 3, 4]:
		aim = (forward * 0.5 - lateral * 0.85).normalized()
	var length: float = SINGLE_LENGTH if not paired else PAIRED_LENGTH
	if face in ["front", "back"]:
		length *= 0.82
	return PackedVector2Array([anchor, anchor + aim * length])

static func single_span(face: String, frame: int, heavy: bool) -> PackedVector2Array:
	var hand: int = 0 if face == "left" else 1
	return span(face, frame, hand, heavy, false)

static func hand_anchor(face: String, frame: int, hand: int) -> Vector2:
	var near: Array[Vector2] = []
	var far: Array[Vector2] = []
	match face:
		"front":
			near = [Vector2(111,141),Vector2(118,129),Vector2(143,121),Vector2(119,118),Vector2(172,120),Vector2(183,128),Vector2(145,129),Vector2(113,141)]
			far = [Vector2(179,137),Vector2(178,124),Vector2(194,114),Vector2(205,107),Vector2(187,105),Vector2(208,129),Vector2(190,145),Vector2(179,137)]
		"left":
			near = [Vector2(93,134),Vector2(97,117),Vector2(98,107),Vector2(83,106),Vector2(76,102),Vector2(80,103),Vector2(101,134),Vector2(96,137)]
			far = [Vector2.INF,Vector2.INF,Vector2.INF,Vector2.INF,Vector2.INF,Vector2.INF,Vector2.INF,Vector2.INF]
		"right":
			far = [Vector2(177,135),Vector2(178,114),Vector2(180,91),Vector2(204,97),Vector2(191,104),Vector2(201,99),Vector2(185,129),Vector2(177,135)]
			near = [Vector2.INF,Vector2.INF,Vector2.INF,Vector2.INF,Vector2.INF,Vector2.INF,Vector2.INF,Vector2.INF]
		"back":
			near = [Vector2.INF,Vector2.INF,Vector2.INF,Vector2.INF,Vector2.INF,Vector2.INF,Vector2.INF,Vector2.INF]
			far = [Vector2.INF,Vector2(192,136),Vector2(203,87),Vector2(214,82),Vector2(202,103),Vector2(210,112),Vector2(191,150),Vector2.INF]
		_:
			return Vector2.INF
	var point: Vector2 = (near if hand == 0 else far)[clampi(frame, 0, 7)]
	return point if point == Vector2.INF else point - Vector2(128, 110)
