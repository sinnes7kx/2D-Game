extends RefCounted
## Smooth display-only motion. Never changes attack or movement timing.
const IDLE_SWING: float = 0.085
const CYCLE_SECONDS: float = 3.2
const EFFECT_ALPHA: float = 0.48

static func modular_idle(name: String) -> bool:
	return name.contains("_idle_") and (name.contains("twinblade") or name.begins_with("dual_dagger_") or name.begins_with("dual_sword_") or name.begins_with("scythe_") or name.begins_with("wand_"))

static func install(body: AnimatedSprite2D) -> void:
	var frames: SpriteFrames = body.sprite_frames
	if frames == null:
		return
	for value in frames.get_animation_names():
		var name: String = str(value)
		if not modular_idle(name) or not frames.get_animation_loop(name) or frames.get_frame_count(name) == 0:
			continue
		# The old modular idle cycles jump among attack-ready body poses.
		# Preserve the intact neutral pose and its hand; the separate weapon
		# layer supplies a continuous breathing rotation.
		var neutral: Texture2D = frames.get_frame_texture(name, 0)
		var duration_sum: float = 0.0
		for i in range(frames.get_frame_count(name)):
			var duration: float = frames.get_frame_duration(name, i)
			duration_sum += duration
			frames.set_frame(name, i, neutral, duration)
		frames.set_animation_speed(name, duration_sum / CYCLE_SECONDS)

static func angle_at(phase: float, hand: int = 0) -> float:
	return sin(phase * TAU + float(hand) * PI) * IDLE_SWING

static func phase_of(body: AnimatedSprite2D) -> float:
	if body == null or body.sprite_frames == null:
		return 0.0
	var duration_sum: float = 0.0
	var current: float = 0.0
	for i in range(body.sprite_frames.get_frame_count(body.animation)):
		var d: float = body.sprite_frames.get_frame_duration(body.animation, i)
		duration_sum += d
		if i < body.frame:
			current += d
		elif i == body.frame:
			current += d * body.frame_progress
	return current / maxf(duration_sum, 0.001)

static func rotate_span(neutral: PackedVector2Array, phase: float, hand: int = 0) -> PackedVector2Array:
	if neutral.size() != 2:
		return neutral
	return PackedVector2Array([neutral[0], neutral[0] + (neutral[1] - neutral[0]).rotated(angle_at(phase, hand))])

static func smooth(body: AnimatedSprite2D, animation: String, neutral: PackedVector2Array, hand: int = 0) -> PackedVector2Array:
	if body == null or animation != str(body.animation) or not modular_idle(animation):
		return neutral
	return rotate_span(neutral, phase_of(body), hand)

static func softened(ink: Color, multiplier: float = EFFECT_ALPHA) -> Color:
	ink.a = clampf(ink.a * multiplier, 0.0, 1.0)
	return ink
