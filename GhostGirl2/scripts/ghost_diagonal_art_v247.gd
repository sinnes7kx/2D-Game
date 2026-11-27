extends RefCounted
## Original-skin diagonal locomotion. Existing cardinal and equipped action
## animations remain the source of truth for weapon rigs and combat timing.
const ATLAS: String = "res://assets/ghost/skins/ghost_diagonal_v247.png"
const DIRECTIONS: Array[String] = ["front_right", "front_left", "back_left", "back_right"]
const CELL: Vector2i = Vector2i(256, 220)
const ACTION_ATLAS: String = "res://assets/ghost/skins/ghost_diagonal_actions_v248.png"
const REVISED_ATLAS: String = "res://assets/ghost/skins/ghost_diagonal_v249.png"
const REVISED_ACTIONS: String = "res://assets/ghost/skins/ghost_diagonal_actions_v249.png"
const WEAPON_PREFIXES: Array[String] = ["sword_modular_", "wand_", "forge_dagger_", "twinblade_", "rosemirror_twinblade_", "scythe_", "halberd_", "maul_", "ashglass_maul_", "forge_bow_", "dual_dagger_", "dual_sword_", "crossbow_", "spear_", "briarwake_spear_", "nocturne_dagger_"]
# Approximate visible wrist guides, visually sampled from the normalized atlas.
# Approximate initial per-frame wrist guides in full atlas-cell pixels.
const LEGACY_WRISTS: Dictionary = {
	"idle_front_right": [[107,151],[108,150],[108,151],[109,151],[109,152],[109,151],[108,150],[107,151]],
	"idle_front_left": [[150,149],[149,149],[149,150],[148,150],[148,151],[149,150],[150,149],[150,149]],
	"walk_front_right": [[96,151],[100,149],[104,146],[105,148],[98,150],[96,152],[101,150],[104,149]],
	"walk_front_left": [[151,150],[150,147],[149,146],[151,149],[153,151],[151,151],[150,149],[150,148]],
	"idle_back_left": [[76,144],[75,143],[70,143],[75,143],[69,140],[75,141],[71,144],[76,143]],
	"walk_back_left": [[79,142],[80,136],[73,124],[79,125],[78,143],[76,142],[78,137],[79,143]],
	"idle_back_right": [[162,150],[161,148],[167,144],[166,146],[163,146],[164,146],[164,147],[162,150]],
	"walk_back_right": [[174,150],[172,146],[183,142],[188,147],[199,157],[185,150],[190,150],[177,149]]
}

# Frame-specific far hand positions sampled from the actual v249 cells.
# Empty entries are genuinely obscured; rear views deliberately have no
# invented second wrist. Older v247 art retains its paired cardinal fallback.
# Calibrated against the reconstructed v249 locomotion atlas distributed in
# GhostGirl_Diagonal_Atlas_Repair.zip. Full-cell pixel coordinates, not
# bounding-box coordinates. Legacy v247 remains available for old installs.
const WRISTS: Dictionary = {
	"idle_front_right": [[125,139],[123,139],[124,140],[121,139],[123,139],[123,139],[125,139],[123,139]],
	"idle_front_left": [[126,138],[125,138],[125,138],[125,138],[123,138],[123,138],[123,138],[125,138]],
	"idle_back_left": [[74,133],[73,132],[69,132],[73,132],[69,131],[74,130],[70,133],[75,133]],
	"idle_back_right": [[176,137],[176,137],[175,138],[175,138],[176,138],[176,137],[177,138],[177,138]],
	"walk_front_right": [[128,144],[125,144],[122,140],[118,140],[117,138],[122,138],[124,145],[124,144]],
	"walk_front_left": [[129,143],[130,140],[123,138],[123,140],[125,141],[127,142],[128,142],[128,143]],
	"walk_back_left": [[76,137],[76,130],[73,111],[72,115],[75,139],[81,133],[77,130],[76,138]],
	"walk_back_right": [[177,143],[175,143],[180,143],[182,145],[181,144],[181,143],[176,142],[179,144]]
}

# Only clearly visible opposite hands receive a guide. Do not draw a
# second weapon over hair or fabric where the hand is hidden.
const FAR_WRISTS: Dictionary = {
	"idle_front_right": [[178,131],[178,131],[178,131],[178,131],[178,131],[178,131],[178,131],[178,131]],
	"idle_front_left": [[75,130],[75,130],[75,130],[75,130],[75,130],[75,130],[75,130],[75,130]],
	"walk_front_right": [[188,135],[],[],[],[],[],[],[]],
	"walk_front_left": [[],[],[],[],[],[],[],[]]
}

static func available() -> bool:
	return ResourceLoader.exists(REVISED_ATLAS, "Texture2D") or ResourceLoader.exists(ATLAS, "Texture2D")

static func install(frames: SpriteFrames) -> bool:
	if frames == null or not available():
		return false
	var sheet: Texture2D = load(REVISED_ATLAS if ResourceLoader.exists(REVISED_ATLAS, "Texture2D") else ATLAS) as Texture2D
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
	_install_actions(frames)
	_install_armed_aliases(frames)
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

static func _install_actions(frames: SpriteFrames) -> void:
	var revised: bool = ResourceLoader.exists(REVISED_ACTIONS, "Texture2D")
	var path: String = REVISED_ACTIONS if revised else ACTION_ATLAS
	if not ResourceLoader.exists(path, "Texture2D"):
		return
	var sheet: Texture2D = load(path) as Texture2D
	if sheet == null or sheet.get_size() != Vector2(2048,1760):
		return
	for row in ([0,1,2,3,4,5,6,7] if revised else [0,1,3,4,5,7]):
		var action: String = "dodge" if row < 4 else "jump"
		var clip: String = action + "_" + DIRECTIONS[row % 4]
		if frames.has_animation(clip):
			continue
		frames.add_animation(clip)
		frames.set_animation_loop(clip, false)
		frames.set_animation_speed(clip, 8.0)
		for col in range(8):
			var cell: AtlasTexture = AtlasTexture.new()
			cell.atlas = sheet
			cell.region = Rect2(col * CELL.x, row * CELL.y, CELL.x, CELL.y)
			cell.filter_clip = true
			frames.add_frame(clip, cell)

static func _install_armed_aliases(frames: SpriteFrames) -> void:
	for source in WRISTS:
		if not frames.has_animation(source):
			continue
		if str(source).contains("back_") and not ResourceLoader.exists(REVISED_ATLAS, "Texture2D"):
			continue
		for prefix in WEAPON_PREFIXES:
			if prefix in ["dual_dagger_", "dual_sword_", "crossbow_"] and not ResourceLoader.exists(REVISED_ATLAS, "Texture2D"):
				continue
			var clip: String = prefix + str(source)
			if frames.has_animation(clip):
				continue
			frames.add_animation(clip)
			frames.set_animation_loop(clip,true)
			frames.set_animation_speed(clip,frames.get_animation_speed(source))
			for i in range(frames.get_frame_count(source)):
				frames.add_frame(clip,frames.get_frame_texture(source,i),frames.get_frame_duration(source,i))

static func wrist(clip: String, frame: int) -> Vector2:
	var key: String = clip
	for prefix in WEAPON_PREFIXES:
		if key.begins_with(prefix):
			key = key.trim_prefix(prefix)
			break
	if key.contains("back_") and not ResourceLoader.exists(REVISED_ATLAS, "Texture2D"):
		return Vector2.INF
	var table: Dictionary = WRISTS if ResourceLoader.exists(REVISED_ATLAS,"Texture2D") else LEGACY_WRISTS
	if not table.has(key):
		return Vector2.INF
	var guides: Array = table[key]
	var p: Array = guides[clampi(frame,0,7)]
	return Vector2(float(p[0])-128.0,float(p[1])-110.0)

static func armed_clip(requested: String, direction: String, cardinal: String, frames: SpriteFrames) -> String:
	if direction not in DIRECTIONS or frames == null:
		return requested
	for family in WEAPON_PREFIXES:
		for action in ["idle_", "walk_"]:
			var prefix: String = family + action
			if requested == prefix + cardinal:
				var clip: String = prefix + direction
				if frames.has_animation(clip):
					return clip
	return requested

static func action_clip(action: String, direction: String, fallback: String, frames: SpriteFrames) -> String:
	var clip: String = action + "_" + direction
	return clip if frames != null and direction in DIRECTIONS and frames.has_animation(clip) else fallback

static func diagonal_name(clip: String) -> String:
	for direction in DIRECTIONS:
		if clip.ends_with("_" + direction):
			return direction
	return ""

static func cardinal_for_clip(clip: String, fallback: String = "front") -> String:
	var direction: String = diagonal_name(clip)
	if not direction.is_empty():
		return "back" if direction.begins_with("back") else "front"
	for face in ["front", "back", "left", "right"]:
		if clip.ends_with("_" + face):
			return face
	return fallback

# All single-grip rigs consume this same measured near-wrist coordinate.
# Keep the original cardinal span length and do not invent a hidden second hand.
static func carried_span(clip: String, frame: int, length: float, upright: bool = false) -> PackedVector2Array:
	var anchor: Vector2 = wrist(clip,frame)
	if anchor == Vector2.INF:
		return PackedVector2Array()
	var direction: String = diagonal_name(clip)
	var sign_x: float = 1.0 if direction.ends_with("right") else -1.0
	var rear: bool = direction.begins_with("back")
	var axis: Vector2 = Vector2(sign_x * (0.50 if upright else (-0.56 if not rear else 0.56)), -0.86 if upright else 0.83).normalized()
	if clip.begins_with("forge_bow_"):
		axis = Vector2(sign_x * 0.70, -0.45 if rear else 0.45).normalized()
	return PackedVector2Array([anchor,anchor+axis*length])

static func near_hand(clip: String) -> int:
	return 0 if diagonal_name(clip).ends_with("left") else 1

static func far_wrist(clip: String, frame: int) -> Vector2:
	if not ResourceLoader.exists(REVISED_ATLAS,"Texture2D"):
		return Vector2.INF
	var direction: String = diagonal_name(clip)
	if direction.is_empty() or direction.begins_with("back"):
		return Vector2.INF
	var action: String = "walk_" if clip.contains("_walk_") else "idle_"
	var samples: Array = FAR_WRISTS.get(action+direction,[])
	if samples.size()!=8:
		return Vector2.INF
	var sample: Array = samples[clampi(frame,0,7)]
	if sample.size()!=2:
		return Vector2.INF
	return Vector2(float(sample[0])-128.0,float(sample[1])-110.0)

static func hand_wrist(clip: String, frame: int, hand: int) -> Vector2:
	return wrist(clip,frame) if hand==near_hand(clip) else far_wrist(clip,frame)

# Keep the two hand slots even if one is hidden, so independent item
# colors and glow layers never switch hands as the character turns.
static func paired_spans(clip: String, frame: int, length: float) -> Array:
	var result: Array = []
	var direction: String = diagonal_name(clip)
	var facing_x: float = -1.0 if direction.ends_with("left") else 1.0
	for hand in range(2):
		var anchor: Vector2 = hand_wrist(clip,frame,hand)
		if anchor==Vector2.INF:
			result.append(PackedVector2Array())
			continue
		var lateral: float = -facing_x if hand==near_hand(clip) else facing_x
		var axis: Vector2 = Vector2(lateral*0.49,0.87).normalized()
		result.append(PackedVector2Array([anchor,anchor+axis*length]))
	return result

static func crossbow_span(clip: String, frame: int) -> PackedVector2Array:
	var anchor: Vector2 = wrist(clip,frame)
	if anchor==Vector2.INF:
		return PackedVector2Array()
	var direction: String = diagonal_name(clip)
	var axis: Vector2 = Vector2(-0.88 if direction.ends_with("left") else 0.88,-0.36 if direction.begins_with("back") else 0.47).normalized()
	return PackedVector2Array([anchor,anchor+axis*32.0])

# Diagonal spear carry uses the visible wrist and existing 74px attack span.
static func spear_span(clip: String, frame: int) -> PackedVector2Array:
	if not (clip.begins_with("spear_") or clip.begins_with("briarwake_spear_")):
		return PackedVector2Array()
	return carried_span(clip,frame,74.0,true)

static func armed_jump_carry(requested: String, direction: String, cardinal: String, frames: SpriteFrames) -> String:
	# The existing armed jump uses a locomotion clip. Preserve that policy.
	if not requested.contains("_walk_"):
		return requested
	return armed_clip(requested,direction,cardinal,frames)
