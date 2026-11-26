extends RefCounted
## Original-skin diagonal locomotion. Existing cardinal and equipped action
## animations remain the source of truth for weapon rigs and combat timing.
const ATLAS: String = "res://assets/ghost/skins/ghost_diagonal_v247.png"
const DIRECTIONS: Array[String] = ["front_right", "front_left", "back_left", "back_right"]
const CELL: Vector2i = Vector2i(256, 220)

static func available() -> bool:
	return ResourceLoader.exists(ATLAS, "Texture2D")

static func install(frames: SpriteFrames) -> bool:
	if frames == null or not available():
		return false
	var sheet: Texture2D = load(ATLAS) as Texture2D
	if sheet == null or sheet.get_size() != Vector2(2048, 1760):
		return false
	for row in range(8):
		var action: String = "idle" if row < 4 else "walk"
		var direction: String = DIRECTIONS[row % 4]
		var clip: String = action + "_" + direction
		if frames.has_animation(clip):
			continue
		var cardinal: String = "front" if direction.begins_with("front") else "back"
		var source: String = action + "_" + cardinal
		if not frames.has_animation(source):
			continue
		var total_seconds: float = 0.0
		for i in range(frames.get_frame_count(source)):
			total_seconds += frames.get_frame_duration(source, i) / maxf(0.01, frames.get_animation_speed(source))
		frames.add_animation(clip)
		frames.set_animation_loop(clip, true)
		frames.set_animation_speed(clip, 8.0 / maxf(0.2, total_seconds))
		for col in range(8):
			var cell: AtlasTexture = AtlasTexture.new()
			cell.atlas = sheet
			cell.region = Rect2(col * CELL.x, row * CELL.y, CELL.x, CELL.y)
			cell.filter_clip = true
			frames.add_frame(clip, cell)
	return true

static func resolve(requested: String, eight_facing: String, cardinal: String, armed: bool, frames: SpriteFrames) -> String:
	if armed or frames == null or not eight_facing in DIRECTIONS:
		return requested
	var action: String = ""
	if requested == "idle_" + cardinal or requested == "blink_" + cardinal:
		action = "idle"
	elif requested == "walk_" + cardinal:
		action = "walk"
	if action.is_empty():
		return requested
	var clip: String = action + "_" + eight_facing
	return clip if frames.has_animation(clip) else requested
