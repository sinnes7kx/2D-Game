extends RefCounted
## v2.25: preserve approved poses while increasing dodge and cast sampling.
## No gameplay timer, hitbox, save, or source image mutation.
const GUARD = preload("res://scripts/frame_guard_v186.gd")
const PAINT = preload("res://scripts/walk_inbetweens_v223.gd")
const META: String = "v225_action_sample_sources"
static var _cache: Dictionary = {}

static func target_count(name: String) -> int:
	for face in ["front", "back", "left", "right"]:
		if name == "dodge_" + face:
			return 24
		if name == "wand_cast_" + face:
			return 22
	return 0

static func source_map(count: int) -> Array[int]:
	var result: Array[int] = []
	for i in range(count):
		result.append(i)
		if i == count - 1:
			continue
		if count == 8:
			result.append(i)
			result.append(i + 1)
		elif count == 16 and i % 2 == 0:
			result.append(i + 1)
	return result

static func _substep_count(count: int, index: int) -> int:
	if index == count - 1:
		return 1
	if count == 8:
		return 3
	return 2 if count == 16 and index % 2 == 0 else 1

static func install(body: AnimatedSprite2D) -> void:
	if body == null or body.sprite_frames == null:
		return
	var frames: SpriteFrames = body.sprite_frames
	var expanded: Dictionary = frames.get_meta(META, {})
	for value in frames.get_animation_names():
		var name: String = str(value)
		var target: int = target_count(name)
		if target == 0 or expanded.has(name) or frames.get_animation_loop(name):
			continue
		var count: int = frames.get_frame_count(name)
		if count != (16 if target == 24 else 8):
			continue
		var keys: Array[Texture2D] = []
		var weights: Array[float] = []
		for i in range(count):
			keys.append(frames.get_frame_texture(name, i))
			weights.append(frames.get_frame_duration(name, i))
		var samples: Array[Texture2D] = _samples(keys)
		var mapping: Array[int] = source_map(count)
		if samples.size() != target or mapping.size() != target:
			continue
		var speed: float = frames.get_animation_speed(name)
		frames.remove_animation(name)
		frames.add_animation(name)
		frames.set_animation_speed(name, speed)
		frames.set_animation_loop(name, false)
		var slot: int = 0
		for i in range(count):
			var steps: int = _substep_count(count, i)
			for j in range(steps):
				frames.add_frame(name, samples[slot], weights[i] / float(steps))
				slot += 1
		expanded[name] = mapping
	frames.set_meta(META, expanded)

static func _samples(keys: Array[Texture2D]) -> Array[Texture2D]:
	var result: Array[Texture2D] = []
	var ids: PackedStringArray = []
	for texture in keys:
		if texture == null:
			return result
		ids.append(str(texture.get_instance_id()))
	var key: String = ":".join(ids)
	if _cache.has(key):
		var stored: Array[Texture2D] = _cache[key]
		return stored
	var images: Array[Image] = []
	var atlases: Dictionary = {}
	for texture in keys:
		var picture: Image = GUARD.frame_image(texture, atlases)
		if picture == null or picture.is_empty() or picture.get_size() != Vector2i(keys[0].get_size()):
			return []
		if picture.is_compressed() and picture.decompress() != OK:
			return []
		picture = picture.duplicate()
		picture.convert(Image.FORMAT_RGBA8)
		images.append(picture)
	for i in range(keys.size()):
		result.append(keys[i])
		var steps: int = _substep_count(keys.size(), i)
		if steps == 3:
			result.append(PAINT._paint_step(images[i], images[i + 1]))
		if steps >= 2:
			result.append(PAINT._paint_step(images[i + 1], images[i]))
	if _cache.size() >= 8:
		_cache.clear()
	_cache[key] = result
	return result

# Continuous render-only dodge anticipation and recovery, in world pixels
# and radians. The physical backstep and its invulnerability stay separate.
static func dodge_flow(progress: float) -> Vector3:
	var t: float = clampf(progress, 0.0, 1.0)
	var envelope: float = sin(PI * t)
	return Vector3(8.0 * envelope, 2.2 * envelope, 0.09 * envelope)

static func landing_weight(remaining: float) -> float:
	var t: float = clampf(remaining, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
