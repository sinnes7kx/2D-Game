extends RefCounted
## Optional presentation-only skin. No equipped items or saves are mutated.
const ATLAS: String = "res://assets/ghost/skins/rose_nocturne_v246.png"
const CONFIG: String = "user://ghost_girl_skin_v246.cfg"
const ORIGINAL: int = 0
const NOCTURNE: int = 1
const ROWS: Array[String] = ["idle_front", "idle_back", "idle_left", "idle_right", "walk_front_right", "walk_front_left", "walk_left", "walk_right"]
static var selected: int = ORIGINAL
static var loaded: bool = false

static func available() -> bool:
	return ResourceLoader.exists(ATLAS, "Texture2D")

static func current() -> int:
	if not loaded:
		loaded = true
		var config: ConfigFile = ConfigFile.new()
		if config.load(CONFIG) == OK:
			selected = clampi(int(config.get_value("appearance", "skin", ORIGINAL)), ORIGINAL, NOCTURNE)
	return selected if available() else ORIGINAL

static func choose(value: int) -> bool:
	var previous: int = current()
	if value < ORIGINAL or value > NOCTURNE or (value == NOCTURNE and not available()):
		return false
	var config: ConfigFile = ConfigFile.new()
	config.set_value("appearance", "skin", value)
	if config.save(CONFIG) != OK:
		selected = previous
		return false
	selected = value
	return true

static func install(frames: SpriteFrames) -> bool:
	if frames == null or not available():
		return false
	var sheet: Texture2D = load(ATLAS) as Texture2D
	if sheet == null or sheet.get_width() != 2048 or sheet.get_height() != 1760:
		return false
	for row in range(ROWS.size()):
		var name: String = "rose_nocturne_" + ROWS[row]
		if frames.has_animation(name):
			continue
		var base: String = "idle_front" if row < 4 else "walk_front"
		var duration: float = 0.0
		for i in range(frames.get_frame_count(base)):
			duration += frames.get_frame_duration(base, i) / maxf(0.01, frames.get_animation_speed(base))
		frames.add_animation(name)
		frames.set_animation_loop(name, true)
		frames.set_animation_speed(name, 8.0 / maxf(duration, 0.2))
		for col in range(8):
			var cell: AtlasTexture = AtlasTexture.new()
			cell.atlas = sheet
			cell.region = Rect2(col * 256, row * 220, 256, 220)
			cell.filter_clip = true
			frames.add_frame(name, cell)
	return true

static func resolve(requested: String, eight_facing: String, cardinal: String, armed: bool, frames: SpriteFrames) -> String:
	if current() != NOCTURNE or armed or frames == null:
		return requested
	var name: String = ""
	if requested == "idle_" + cardinal or requested == "blink_" + cardinal:
		name = "rose_nocturne_idle_" + cardinal
	elif requested == "walk_" + cardinal:
		# The supplied sheet contains four walking rows, but no true rear
		# walking view. Preserve original rear poses rather than mislabel art.
		var direction: String = eight_facing
		if direction == "front":
			direction = "front_right"
		name = "rose_nocturne_walk_" + direction
	return name if not name.is_empty() and frames.has_animation(name) else requested
