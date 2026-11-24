extends RefCounted
## Preserve approved pixels. Never reconstruct a missing head or rescale
## the body. Repair known malformed baked heavy clips only when a clean
## matching light clip exists; leave attack speed and gameplay unchanged.
const META: String = "v186_heavy_fallbacks"

static func has_cut_or_fragment(image: Image) -> bool:
	if image == null or image.is_empty():
		return false
	var bounds: Rect2i = image.get_used_rect()
	if bounds.size == Vector2i.ZERO:
		return true
	# Older exported cells were cropped at y=0 or y=7. A wide, flat first
	# occupied scanline is not a natural rounded top of the character.
	if bounds.position.y <= 10:
		var top: Rect2i = image.get_region(Rect2i(0, bounds.position.y, image.get_width(), 1)).get_used_rect()
		if top.size.x >= 25:
			return true
	# A separated strip near the bottom is often the next row's hair/FX.
	# Require a genuinely empty six-pixel gap, a substantial main image
	# above it and a small detached island below it.
	var h: int = image.get_height()
	for y in range(maxi(0, h - 45), h - 10):
		if y < bounds.position.y + 95:
			continue
		if image.get_region(Rect2i(0, y, image.get_width(), 6)).get_used_rect().size == Vector2i.ZERO:
			var fragment: Rect2i = image.get_region(Rect2i(0, y + 6, image.get_width(), h - y - 6)).get_used_rect()
			if fragment.size.x >= 8 and fragment.size.y > 0 and fragment.size.y <= 20:
				return true
	return false

static func frame_image(texture: Texture2D, images: Dictionary) -> Image:
	if texture is AtlasTexture:
		var tile: AtlasTexture = texture
		if tile.atlas == null:
			return null
		var key: int = tile.atlas.get_instance_id()
		if not images.has(key):
			var source: Image = tile.atlas.get_image()
			if source != null and source.is_compressed():
				source.decompress()
			images[key] = source
		var atlas: Image = images[key]
		if atlas == null or atlas.is_empty():
			return null
		var region: Rect2i = Rect2i(tile.region)
		if not Rect2i(Vector2i.ZERO, atlas.get_size()).encloses(region):
			return null
		return atlas.get_region(region)
	if texture == null:
		return null
	var image: Image = texture.get_image()
	if image != null and image.is_compressed():
		image.decompress()
	return image

static func clip_is_clean(frames: SpriteFrames, name: String, images: Dictionary) -> bool:
	if not frames.has_animation(name) or frames.get_frame_count(name) < 1:
		return false
	for i in range(frames.get_frame_count(name)):
		var picture: Image = frame_image(frames.get_frame_texture(name, i), images)
		if picture == null or has_cut_or_fragment(picture):
			return false
	return true

static func install(sprite: AnimatedSprite2D) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	var frames: SpriteFrames = sprite.sprite_frames
	var images: Dictionary = {}
	var fallbacks: Dictionary = {}
	for name in frames.get_animation_names():
		var animation: String = str(name)
		for i in range(frames.get_frame_count(animation)):
			var texture: Texture2D = frames.get_frame_texture(animation, i)
			if texture is AtlasTexture:
				(texture as AtlasTexture).filter_clip = true
		# Core heavy PNGs were corrected in the manifest and editor resource.
		# Bows have a separate pose-synchronized mask; do not substitute them.
		if not animation.contains("_heavy_") or animation.contains("_pierce_") or animation.contains("thornrose") or animation.contains("moonveil"):
			continue
		if frames.get_frame_count(animation) == 0 or not frames.get_frame_texture(animation, 0) is AtlasTexture:
			continue
		var light: String = animation.replace("_heavy_", "_light_")
		if not frames.has_animation(light) or frames.get_frame_count(light) != frames.get_frame_count(animation):
			continue
		if clip_is_clean(frames, animation, images) or not clip_is_clean(frames, light, images):
			continue
		for i in range(frames.get_frame_count(animation)):
			var duration: float = frames.get_frame_duration(animation, i)
			frames.set_frame(animation, i, frames.get_frame_texture(light, i), duration)
		fallbacks[animation] = light
	frames.set_meta(META, fallbacks)
