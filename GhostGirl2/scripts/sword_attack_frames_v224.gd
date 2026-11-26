extends RefCounted
## v2.24: non-looping ground sword attack sampling. No source-art writes.
## Keep the original eight authored silhouettes and seven transition pairs.
## The final frame holds for its original weight; never interpolate to start.
const GUARD = preload("res://scripts/frame_guard_v186.gd")
const WALK = preload("res://scripts/walk_inbetweens_v223.gd")
const META: String = "v224_sword_attack_samples"
const KEY_COUNT: int = 8
const SUBSTEPS: int = 3
const SAMPLE_COUNT: int = 22
static var _cache: Dictionary = {}

static func matches_ground(name: String) -> bool:
	if not (name.begins_with("attack_sword_light_") or name.begins_with("attack_sword_heavy_")):
		return false
	return name in ["attack_sword_light_front", "attack_sword_light_back", "attack_sword_light_left", "attack_sword_light_right", "attack_sword_heavy_front", "attack_sword_heavy_back", "attack_sword_heavy_left", "attack_sword_heavy_right"]

static func has_samples(frames: SpriteFrames, name: String) -> bool:
	if frames == null:
		return false
	var expanded: Dictionary = frames.get_meta(META, {})
	return expanded.has(name)

static func source_pose_index(frames: SpriteFrames, name: String, frame: int) -> int:
	if not has_samples(frames, name):
		return frame
	# The first intermediate keeps the current silhouette; the second
	# uses the next one. The baked blade and its light share this choice.
	return clampi(floori(float(frame + 1) / SUBSTEPS), 0, KEY_COUNT - 1)

static func install(body: AnimatedSprite2D) -> void:
	if body == null or body.sprite_frames == null:
		return
	var frames: SpriteFrames = body.sprite_frames
	var expanded: Dictionary = frames.get_meta(META, {})
	for value in frames.get_animation_names():
		var name: String = str(value)
		if not matches_ground(name) or expanded.has(name) or frames.get_animation_loop(name):
			continue
		if frames.get_frame_count(name) != KEY_COUNT:
			continue
		var keys: Array[Texture2D] = []
		var weights: Array[float] = []
		for i in range(KEY_COUNT):
			keys.append(frames.get_frame_texture(name, i))
			weights.append(frames.get_frame_duration(name, i))
		var samples: Array[Texture2D] = _samples(keys)
		if samples.size() != SAMPLE_COUNT:
			continue # Missing or unreadable art leaves this clip untouched.
		var speed: float = frames.get_animation_speed(name)
		frames.remove_animation(name)
		frames.add_animation(name)
		frames.set_animation_speed(name, speed)
		frames.set_animation_loop(name, false)
		for i in range(KEY_COUNT - 1):
			for j in range(SUBSTEPS):
				frames.add_frame(name, samples[i * SUBSTEPS + j], weights[i] / float(SUBSTEPS))
		frames.add_frame(name, keys[KEY_COUNT - 1], weights[KEY_COUNT - 1])
		expanded[name] = true
	frames.set_meta(META, expanded)

static func _samples(keys: Array[Texture2D]) -> Array[Texture2D]:
	var result: Array[Texture2D] = []
	if keys.size() != KEY_COUNT:
		return result
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
	for i in range(KEY_COUNT - 1):
		result.append(keys[i])
		result.append(WALK._paint_step(images[i], images[i + 1]))
		result.append(WALK._paint_step(images[i + 1], images[i]))
	result.append(keys[KEY_COUNT - 1])
	# Heavy and light share the approved texture sequences wherever possible.
	# This cache is bounded; active SpriteFrames retain their own references.
	if _cache.size() >= 8:
		_cache.clear()
	_cache[key] = result
	return result

# Art-only continuous anticipation, strike and follow-through. All three
# return to rest at clip end; no collider, hand marker or hit timing changes.
# Result: directional lean (world pixels), lift (world pixels), roll (radians).
static func motion_at(progress: float, heavy: bool) -> Vector3:
	var t: float = clampf(progress, 0.0, 1.0)
	var anticipate: float = sin(PI * clampf(t / 0.32, 0.0, 1.0))
	var sweep: float = sin(PI * clampf((t - 0.22) / 0.56, 0.0, 1.0))
	var recover: float = sin(PI * clampf((t - 0.58) / 0.42, 0.0, 1.0))
	var strength: float = 1.15 if heavy else 1.0
	return Vector3(-1.6 * anticipate + 2.4 * sweep + 0.9 * recover, 1.8 * sweep + 0.8 * recover, -0.025 * anticipate + 0.055 * sweep - 0.018 * recover) * strength
