extends RefCounted
## Smooth display-only motion. Never changes attack or movement timing.
const IDLE_SWING: float = 0.085
const CYCLE_SECONDS: float = 3.2
const EFFECT_ALPHA: float = 0.48

static func modular_idle(name: String) -> bool:
	return name.contains("_idle_") and (name.contains("twinblade") or name.begins_with("dual_dagger_") or name.begins_with("dual_sword_") or name.begins_with("scythe_") or name.begins_with("halberd_") or name.begins_with("maul_") or name.begins_with("ashglass_maul_") or name.begins_with("wand_"))

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

# Build cumulative weights once after all runtime animation installers.
# Store on the SpriteFrames resource rather than holding a global resource
# reference. Invalidate on resource changes; unprepared clips use the
# original exact calculation (including editor and synthetic fixtures).
const TIMING_META: String = "v228_weighted_timing"

static func prepare_timing(frames: SpriteFrames) -> void:
	if frames == null:
		return
	var tables: Dictionary = {}
	for value in frames.get_animation_names():
		var name: String = str(value)
		var prefix: PackedFloat64Array = PackedFloat64Array([0.0])
		var sum: float = 0.0
		for i in range(frames.get_frame_count(name)):
			sum += frames.get_frame_duration(name, i)
			prefix.append(sum)
		tables[name] = prefix
	frames.set_meta(TIMING_META, tables)
	if not frames.has_meta("v228_timing_invalidation"):
		var weak: WeakRef = weakref(frames)
		frames.changed.connect(func():
			var resource: SpriteFrames = weak.get_ref() as SpriteFrames
			if resource != null and resource.has_meta(TIMING_META):
				resource.remove_meta(TIMING_META)
		)
		frames.set_meta("v228_timing_invalidation", true)

static func phase_of(body: AnimatedSprite2D) -> float:
	if body == null or body.sprite_frames == null:
		return 0.0
	var tables: Dictionary = body.sprite_frames.get_meta(TIMING_META, {})
	var prefix: PackedFloat64Array = tables.get(str(body.animation), PackedFloat64Array())
	var count: int = body.sprite_frames.get_frame_count(body.animation)
	if prefix.size() == count + 1 and body.frame >= 0 and body.frame < count:
		return (prefix[body.frame] + (prefix[body.frame + 1] - prefix[body.frame]) * body.frame_progress) / maxf(prefix[count], 0.001)
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


# Durations in SpriteFrames are relative weights, not necessarily one per
# frame. Match the existing action timer without changing its hit gate.
static func playback_rate(frames: SpriteFrames, name: String, seconds: float) -> float:
	if frames == null or not frames.has_animation(name):
		return 1.0
	var weight: float = 0.0
	for i in range(frames.get_frame_count(name)):
		weight += frames.get_frame_duration(name, i)
	return maxf(0.001, weight) / (maxf(0.08, seconds) * maxf(0.001, frames.get_animation_speed(name)))

# Only independently drawn weapons may move between body keyframes.
# Never move the wrist away from the current approved body pose.
static func attack_fraction(body: AnimatedSprite2D, name: String, frame: int) -> float:
	if body == null or body.sprite_frames == null or not name.begins_with("attack_"):
		return 0.0
	if str(body.animation).replace("_air_", "_") != name.replace("_air_", "_") or body.frame != frame:
		return 0.0
	if frame + 1 >= body.sprite_frames.get_frame_count(body.animation):
		return 0.0
	return clampf(body.frame_progress, 0.0, 1.0)

static func subframe_span(current: PackedVector2Array, upcoming: PackedVector2Array, progress: float) -> PackedVector2Array:
	if current.size() != 2 or upcoming.size() != 2 or progress <= 0.0:
		return current
	var a: Vector2 = current[1] - current[0]
	var b: Vector2 = upcoming[1] - upcoming[0]
	if a.length_squared() < 1.0 or b.length_squared() < 1.0:
		return current
	var t: float = clampf(progress, 0.0, 1.0)
	var angle: float = lerp_angle(a.angle(), b.angle(), t)
	var span_length: float = lerpf(a.length(), b.length(), t)
	return PackedVector2Array([current[0], current[0] + Vector2.from_angle(angle) * span_length])


# Preserve weighted animation phase when switching directional walk clips.
static func is_walk_clip(name: String) -> bool:
	return name.begins_with("walk_") or name.contains("_walk_")

static func same_walk_family(a: String, b: String) -> bool:
	if not is_walk_clip(a) or not is_walk_clip(b):
		return false
	return a.get_slice("_", a.get_slice_count("_") - 1) in ["front", "back", "left", "right"] and b.get_slice("_", b.get_slice_count("_") - 1) in ["front", "back", "left", "right"] and a.left(a.rfind("_")) == b.left(b.rfind("_"))

static func seek_phase(body: AnimatedSprite2D, phase: float) -> void:
	if body == null or body.sprite_frames == null:
		return
	var frames: SpriteFrames = body.sprite_frames
	var count: int = frames.get_frame_count(body.animation)
	if count <= 0:
		return
	var total: float = 0.0
	for i in range(count):
		total += frames.get_frame_duration(body.animation, i)
	var remaining: float = fposmod(phase, 1.0) * total
	for i in range(count):
		var weight: float = frames.get_frame_duration(body.animation, i)
		if remaining < weight or i == count - 1:
			body.set_frame_and_progress(i, clampf(remaining / maxf(0.001, weight), 0.0, 1.0))
			return
		remaining -= weight

# In-world pixel offset and radians; small enough to preserve the painted
# silhouette and keep each attached equipment layer in the same transform.
static func gait_motion(phase: float, speed_ratio: float) -> Vector2:
	var strength: float = clampf(speed_ratio, 0.0, 1.5)
	return Vector2(-0.65 * strength * (1.0 - cos(phase * TAU * 2.0)), 0.012 * strength * sin(phase * TAU))
