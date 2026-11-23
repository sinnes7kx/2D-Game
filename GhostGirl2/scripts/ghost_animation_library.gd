extends RefCounted
## Ghost Girl: attach optional post-v1.0 combat animations after the core scene loads.
## This keeps a malformed/missing optional PNG from breaking main.tscn.
const MANIFEST_PATH = "res://resources/ghost_extra_animations.json"

static func install(sprite: AnimatedSprite2D) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	if not FileAccess.file_exists(MANIFEST_PATH):
		push_warning("Ghost Girl extra animation manifest missing; using core animations.")
		return
	var payload: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	if not (payload is Array):
		push_warning("Ghost Girl animation manifest is invalid; using core animations.")
		return
	var frames: SpriteFrames = sprite.sprite_frames.duplicate(true) as SpriteFrames
	if frames == null:
		return
	for entry in payload:
		if not (entry is Dictionary):
			continue
		var animation_name: String = str(entry.get("name", ""))
		if animation_name.is_empty():
			continue
		var loaded: Array[Texture2D] = []
		if entry.has("atlas"):
			var atlas_path: String = "res://" + str(entry.get("atlas", ""))
			var atlas: Texture2D = (load(atlas_path) as Texture2D) if ResourceLoader.exists(atlas_path) else null
			if atlas != null:
				var frame_width: int = int(entry.get("frame_width", 256))
				var frame_height: int = int(entry.get("frame_height", 220))
				var row: int = int(entry.get("row", 0))
				var frame_count: int = int(entry.get("frame_count", 8))
				if atlas.get_width() >= frame_count * frame_width and atlas.get_height() >= (row + 1) * frame_height:
					for i in range(frame_count):
						var tile: AtlasTexture = AtlasTexture.new()
						tile.atlas = atlas
						tile.region = Rect2(i * frame_width, row * frame_height, frame_width, frame_height)
						loaded.append(tile)
				else:
					push_warning("Weapon atlas size/row invalid: " + atlas_path)
			else:
				push_warning("Missing weapon atlas: " + atlas_path)
		for path in entry.get("textures", []):
			var full_path: String = "res://" + str(path)
			if not ResourceLoader.exists(full_path):
				push_warning("Animation texture not found: " + full_path)
				continue
			var texture: Texture2D = load(full_path) as Texture2D
			if texture != null:
				loaded.append(texture)
		if loaded.is_empty():
			push_warning("No frames available for: " + animation_name)
			continue
		if frames.has_animation(animation_name):
			frames.remove_animation(animation_name)
		frames.add_animation(animation_name)
		frames.set_animation_speed(animation_name, float(entry.get("speed", 12.0)))
		frames.set_animation_loop(animation_name, bool(entry.get("loop", false)))
		for texture in loaded:
			frames.add_frame(animation_name, texture)
	sprite.sprite_frames = frames
