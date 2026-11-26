extends RefCounted
## v2.23: conservative procedural walking in-betweens.
## Only the four ordinary walk clips are expanded; weapon/attack frame
## indexes and every original source image stay unchanged.
const STEADY = preload("res://scripts/steady_weapon_idles_v195.gd")
const GUARD = preload("res://scripts/frame_guard_v186.gd")
const META: String = "v223_walk_subframes"
const SUBSTEPS: int = 3
const KEYFRAMES: int = 8
static var _cache: Dictionary = {}

static func source_pose_index(frames: SpriteFrames, name: String, frame: int) -> int:
	if frames == null:
		return frame
	# v2.25 uses explicit maps for nonuniform, nonlooping action samples.
	var actions: Dictionary = frames.get_meta("v225_action_sample_sources", {})
	if actions.has(name):
		var mapping: Array = actions[name]
		if not mapping.is_empty():
			return int(mapping[clampi(frame, 0, mapping.size() - 1)])
	var expanded: Dictionary = frames.get_meta(META, {})
	if not expanded.has(name):
		return frame
	# Intermediate 1 keeps the current contour; intermediate 2 uses the
	# next contour. Eye/accessory guides follow that same nearest keyframe.
	return posmod(floori(float(frame + 1) / SUBSTEPS), int(expanded[name]))

static func install(body: AnimatedSprite2D) -> void:
	if body == null or body.sprite_frames == null:
		return
	var frames: SpriteFrames = body.sprite_frames
	var expanded: Dictionary = frames.get_meta(META, {})
	for face in ["front", "back", "left", "right"]:
		var name: String = "walk_" + face
		if expanded.has(name) or not frames.has_animation(name) or not frames.get_animation_loop(name):
			continue
		if frames.get_frame_count(name) != KEYFRAMES:
			continue
		var keys: Array[Texture2D] = []
		var weights: Array[float] = []
		for i in range(KEYFRAMES):
			keys.append(frames.get_frame_texture(name, i))
			weights.append(frames.get_frame_duration(name, i))
		var generated: Array[Texture2D] = _intermediates(keys)
		if generated.size() != KEYFRAMES * SUBSTEPS:
			continue # A bad or missing image leaves the entire original clip intact.
		var speed: float = frames.get_animation_speed(name)
		frames.remove_animation(name)
		frames.add_animation(name)
		frames.set_animation_loop(name, true)
		frames.set_animation_speed(name, speed * SUBSTEPS)
		for i in range(KEYFRAMES):
			for j in range(SUBSTEPS):
				frames.add_frame(name, generated[i * SUBSTEPS + j], weights[i])
		expanded[name] = KEYFRAMES
	frames.set_meta(META, expanded)

static func _intermediates(keys: Array[Texture2D]) -> Array[Texture2D]:
	var result: Array[Texture2D] = []
	if keys.size() != KEYFRAMES:
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
		var image: Image = GUARD.frame_image(texture, atlases)
		if image == null or image.is_empty() or image.get_size() != Vector2i(keys[0].get_size()):
			return []
		if image.is_compressed():
			if image.decompress() != OK:
				return []
		image = image.duplicate()
		image.convert(Image.FORMAT_RGBA8)
		images.append(image)
	for i in range(KEYFRAMES):
		var next: int = (i + 1) % KEYFRAMES
		result.append(keys[i]) # The approved keyframe is preserved verbatim.
		result.append(_paint_step(images[i], images[next]))
		result.append(_paint_step(images[next], images[i]))
	# Keep at most four directional cycles. Never allocate textures per frame.
	if _cache.size() >= 4:
		_cache.clear()
	_cache[key] = result
	return result

static func _paint_step(base: Image, other: Image) -> Texture2D:
	# Borrow only overlapping opaque interior color. Alpha, silhouette and
	# exposed edges are taken wholly from one approved pose, never double-exposed.
	var overlap: Rect2i = base.get_used_rect().intersection(other.get_used_rect())
	var data: PackedByteArray = STEADY._mix_rgba(base.get_data(), other.get_data(), 0.18, base.get_width(), overlap)
	var image: Image = Image.create_from_data(base.get_width(), base.get_height(), false, Image.FORMAT_RGBA8, data)
	return ImageTexture.create_from_image(image)
