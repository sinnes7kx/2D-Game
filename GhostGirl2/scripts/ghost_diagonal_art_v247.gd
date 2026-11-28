extends RefCounted
## Original-skin diagonal locomotion. Existing cardinal and equipped action
## animations remain the source of truth for weapon rigs and combat timing.
const ATLAS: String = "res://assets/ghost/skins/ghost_diagonal_v247.png"
const DIRECTIONS: Array[String] = ["front_right", "front_left", "back_left", "back_right"]
const CELL: Vector2i = Vector2i(256, 220)
const ACTION_ATLAS: String = "res://assets/ghost/skins/ghost_diagonal_actions_v248.png"
const REVISED_ATLAS: String = "res://assets/ghost/skins/ghost_diagonal_v249.png"
const REVISED_ACTIONS: String = "res://assets/ghost/skins/ghost_diagonal_actions_v249.png"
const WEAPON_PREFIXES: Array[String] = ["sword_modular_", "sword_", "dagger_", "thornrose_", "moonveil_", "wand_", "forge_dagger_", "twinblade_", "rosemirror_twinblade_", "scythe_", "halberd_", "maul_", "ashglass_maul_", "forge_bow_", "dual_dagger_", "dual_sword_", "crossbow_", "spear_", "briarwake_spear_", "nocturne_dagger_", "rapier_", "axe_", "seraph_scythe_"]
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

# Editor imports can lag behind a manually extracted PNG. Use the actual
# source image when the import is unavailable, and cache validated sheets.
static var _validated_sheets: Dictionary = {}

# Approximate hand centers sampled against the actual 2048x1760 repair
# action atlas. Full-cell pixel coordinates, one sample per authored pose.
const ACTION_WRISTS_V271: Dictionary = {
	"dodge_front_right": [[125,134],[129,134],[111,128],[115,118],[110,116],[113,115],[125,137],[119,130]],
	"dodge_front_left": [[144,130],[143,130],[134,130],[150,126],[143,105],[146,109],[140,126],[143,129]],
	"dodge_back_left": [[79,132],[86,132],[77,126],[72,124],[68,129],[77,128],[78,131],[78,133]],
	"dodge_back_right": [[182,130],[180,142],[195,130],[203,120],[203,131],[194,126],[190,140],[185,133]],
	"jump_front_right": [[127,164],[114,150],[116,117],[125,114],[115,113],[113,120],[121,148],[128,155]],
	"jump_front_left": [[126,157],[147,149],[143,116],[137,112],[143,110],[137,136],[135,151],[126,156]],
	"jump_back_left": [[78,133],[83,127],[80,114],[66,109],[70,134],[82,135],[88,134],[80,132]],
	"jump_back_right": [[180,145],[185,142],[199,119],[200,129],[197,132],[196,124],[184,144],[182,145]]
}

const ACTION_FAR_WRISTS_V271: Dictionary = {
	"dodge_front_right": [[183,132],[184,134],[188,129],[195,124],[196,128],[191,134],[181,139],[]],
	"dodge_front_left": [[80,132],[75,134],[69,140],[63,130],[54,135],[69,147],[74,132],[75,128]],
	"jump_front_right": [[],[181,151],[193,130],[188,129],[191,130],[193,127],[181,149],[183,147]],
	"jump_front_left": [[80,156],[69,148],[60,128],[58,130],[53,129],[62,137],[75,156],[]]
}

static func _valid_dimensions(texture: Texture2D) -> bool:
	return texture != null and texture.get_size()==Vector2(2048,1760)

static func _load_sheet(path: String) -> Texture2D:
	var cached: Texture2D = _validated_sheets.get(path) as Texture2D
	if _valid_dimensions(cached):
		return cached
	var texture: Texture2D
	if ResourceLoader.exists(path,"Texture2D"):
		texture=ResourceLoader.load(path,"Texture2D") as Texture2D
	if not _valid_dimensions(texture) and FileAccess.file_exists(path):
		var raw: Image = Image.new()
		if raw.load(path)==OK:
			if raw.get_size()==Vector2i(1024,880):
				# Recover the original half-resolution sheet cell by cell.
				var restored: Image = Image.create(2048,1760,false,Image.FORMAT_RGBA8)
				for row in range(8):
					for col in range(8):
						var cell: Image = raw.get_region(Rect2i(col*128,row*110,128,110))
						cell.convert(Image.FORMAT_RGBA8)
						cell.resize(256,220,Image.INTERPOLATE_LANCZOS)
						restored.blit_rect(cell,Rect2i(0,0,256,220),Vector2i(col*256,row*220))
				raw=restored
			if raw.get_size()==Vector2i(2048,1760):
				texture=ImageTexture.create_from_image(raw)
	if not _valid_dimensions(texture):
		return null
	_validated_sheets[path]=texture
	return texture

static func _revised_available() -> bool:
	return _load_sheet(REVISED_ATLAS)!=null

static func available() -> bool:
	return _revised_available() or _load_sheet(ATLAS)!=null

static func diagnostic() -> String:
	if available():
		return "Diagonal locomotion atlas available."
	var absolute: String = ProjectSettings.globalize_path(REVISED_ATLAS)
	if not FileAccess.file_exists(REVISED_ATLAS) and not ResourceLoader.exists(REVISED_ATLAS,"Texture2D"):
		return "Diagonal PNG missing at "+absolute+" (extract the repair ZIP into the repository root)."
	var raw: Image = Image.new()
	if FileAccess.file_exists(REVISED_ATLAS) and raw.load(REVISED_ATLAS)==OK:
		return "Diagonal PNG at "+absolute+" has size "+str(raw.get_size())+"; required (2048,1760)."
	return "Diagonal PNG cannot be decoded/imported at "+absolute+". Re-extract the original repair ZIP."

static func install(frames: SpriteFrames) -> bool:
	if frames == null or not available():
		return false
	if bool(frames.get_meta("v270_diagonal_loaded",false)):
		_install_modular_combat_v294(frames)
		return true
	var sheet: Texture2D = _load_sheet(REVISED_ATLAS)
	if sheet==null:
		sheet=_load_sheet(ATLAS)
	if not _valid_dimensions(sheet):
		return false
	for row in range(8):
		var action: String = "idle" if row < 4 else "walk"
		var direction: String = DIRECTIONS[row % 4]
		var clip: String = action + "_" + direction
		if frames.has_animation(clip):
			frames.remove_animation(clip)
		var cardinal: String = "front" if direction.begins_with("front") else "back"
		var source: String = action + "_" + cardinal
		if not frames.has_animation(source):
			continue
		var total_seconds: float = 0.0
		for i in range(frames.get_frame_count(source)):
			total_seconds += frames.get_frame_duration(source, i) / maxf(0.01, frames.get_animation_speed(source))
		frames.add_animation(clip)
		_set_loop_v293(frames,clip,true)
		frames.set_animation_speed(clip, 8.0 / maxf(0.2, total_seconds))
		for col in range(8):
			var cell: AtlasTexture = AtlasTexture.new()
			cell.atlas = sheet
			cell.region = Rect2(col * CELL.x, row * CELL.y, CELL.x, CELL.y)
			cell.filter_clip = true
			frames.add_frame(clip, cell)
	_install_actions(frames)
	_install_armed_aliases(frames)
	_install_modular_combat_v294(frames)
	frames.set_meta("v270_diagonal_loaded",true)
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
	var sheet: Texture2D = _load_sheet(REVISED_ACTIONS)
	var revised: bool = sheet!=null
	if sheet==null:
		sheet=_load_sheet(ACTION_ATLAS)
	if not _valid_dimensions(sheet):
		return
	for row in ([0,1,2,3,4,5,6,7] if revised else [0,1,3,4,5,7]):
		var action: String = "dodge" if row < 4 else "jump"
		var clip: String = action + "_" + DIRECTIONS[row % 4]
		if frames.has_animation(clip):
			continue
		frames.add_animation(clip)
		_set_loop_v293(frames,clip,false)
		frames.set_animation_speed(clip, 8.0)
		for col in range(8):
			var cell: AtlasTexture = AtlasTexture.new()
			cell.atlas = sheet
			cell.region = Rect2(col * CELL.x, row * CELL.y, CELL.x, CELL.y)
			cell.filter_clip = true
			frames.add_frame(clip, cell)

static func _install_armed_aliases(frames: SpriteFrames) -> void:
	var sources: Array = WRISTS.keys()
	# Older action art has different silhouettes; only the revised action
	# atlas has measured action wrist guides.
	if _load_sheet(REVISED_ACTIONS)!=null:
		sources.append_array(ACTION_WRISTS_V271.keys())
	for source in sources:
		if not frames.has_animation(source):
			continue
		if str(source).contains("back_") and not _revised_available() and not ACTION_WRISTS_V271.has(source):
			continue
		for prefix in WEAPON_PREFIXES:
			if prefix in ["dual_dagger_", "dual_sword_", "crossbow_"] and not _revised_available() and not ACTION_WRISTS_V271.has(source):
				continue
			var clip: String = prefix + str(source)
			if frames.has_animation(clip):
				frames.remove_animation(clip)
			frames.add_animation(clip)
			_set_loop_v293(frames,clip,_loops_v293(frames,source))
			frames.set_animation_speed(clip,frames.get_animation_speed(source))
			for i in range(frames.get_frame_count(source)):
				frames.add_frame(clip,frames.get_frame_texture(source,i),frames.get_frame_duration(source,i))

static func wrist(clip: String, frame: int) -> Vector2:
	if _authored_guides.has(clip):
		return authored_wrist(clip,frame,int(_authored_guides[clip]["near_hand"]))
	if is_guard_clip(clip):
		return guard_wrist(clip,frame)
	var key: String = combat_body_source_v294(clip) if is_modular_combat_v294(clip) else clip
	for prefix in WEAPON_PREFIXES:
		if key.begins_with(prefix):
			key = key.trim_prefix(prefix)
			break
	if ACTION_WRISTS_V271.has(key):
		if _load_sheet(REVISED_ACTIONS)==null:
			return Vector2.INF
		var sample: Array = ACTION_WRISTS_V271[key][clampi(frame,0,7)]
		return Vector2(float(sample[0])-128.0,float(sample[1])-110.0)
	if key.contains("back_") and not _revised_available():
		return Vector2.INF
	var table: Dictionary = WRISTS if _revised_available() else LEGACY_WRISTS
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
	if _authored_guides.has(clip):
		return int(_authored_guides[clip]["near_hand"])
	return 0 if diagonal_name(clip).ends_with("left") else 1

static func far_wrist(clip: String, frame: int) -> Vector2:
	if _authored_guides.has(clip):
		return authored_wrist(clip,frame,1-int(_authored_guides[clip]["near_hand"]))
	if is_guard_clip(clip):
		return guard_wrist(clip,frame,1-guard_near_hand(clip))
	var direction: String = diagonal_name(clip)
	if direction.is_empty() or direction.begins_with("back"):
		return Vector2.INF
	var action: String = "idle_"
	if is_modular_combat_v294(clip):
		action=combat_body_source_v294(clip).trim_suffix(direction)
	for name in ["walk_","jump_","dodge_"]:
		if clip.contains("_"+name) or clip.begins_with(name):
			action=name
			break
	var table: Dictionary = FAR_WRISTS
	if action in ["jump_","dodge_"]:
		if _load_sheet(REVISED_ACTIONS)==null:
			return Vector2.INF
		table=ACTION_FAR_WRISTS_V271
	elif not _revised_available():
		return Vector2.INF
	var samples: Array = table.get(action+direction,[])
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

# Preserve separate left/right slots and never invent an occluded wrist.
static func paired_dagger_attack_spans(clip: String, frame: int, length: float) -> Array:
	return paired_attack_spans(clip,frame,length)

static func paired_attack_spans(clip: String, frame: int, length: float) -> Array:
	var result: Array = []
	var direction: String = diagonal_name(clip)
	var forward: Vector2 = heading_v294(direction)
	var near: int = near_hand(clip)
	var n: int = clampi(frame,0,7)
	var thrust: bool = clip.contains("_pierce_")
	var lead: int = 0 if clip.contains("_light_a_") else (1 if clip.contains("_light_b_") else near)
	var both: bool = clip.contains("_light_c_") or clip.contains("_riposte_") or (clip.contains("_heavy_") and not thrust)
	var swing: Array[float] = [-1.25,-1.55,-0.75,0.0,0.34,1.05,0.64,-0.38]
	if clip.contains("_dual_sword_") and clip.contains("_heavy_"):
		swing.assign([-1.45,-1.70,-1.10,-0.30,0.0,1.18,0.72,-0.45])
	var stab: Array[float] = [-0.65,-0.85,-0.42,0.0,0.0,0.10,-0.38,-0.65]
	for hand in range(2):
		var anchor: Vector2 = hand_wrist(clip,frame,hand)
		if anchor==Vector2.INF or forward.is_zero_approx():
			result.append(PackedVector2Array())
			continue
		var side: float = -1.0 if hand==0 else 1.0
		var angle: float = (stab[n] if thrust else swing[n])*side
		if not both and hand!=lead:
			angle = side*0.95
		result.append(PackedVector2Array([anchor,anchor+forward.rotated(angle)*length]))
	return result

static func crossbow_span(clip: String, frame: int) -> PackedVector2Array:
	var anchor: Vector2 = wrist(clip,frame)
	if anchor==Vector2.INF:
		return PackedVector2Array()
	var direction: String = diagonal_name(clip)
	var axis: Vector2 = Vector2(-0.88 if direction.ends_with("left") else 0.88,-0.36 if direction.begins_with("back") else 0.47).normalized()
	if clip.begins_with("attack_"):
		axis=heading_v294(direction)
		if clip.contains("_reload_"):
			axis=axis.rotated((-1.0 if direction.ends_with("right") else 1.0)*sin(PI*float(clampi(frame,0,7))/7.0)*0.75)
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

# All equipped locomotion aliases use the authored diagonal cells directly.
static func is_carried_clip(clip: String) -> bool:
	if is_guard_clip(clip):
		return true
	if diagonal_name(clip).is_empty():
		return false
	for family in WEAPON_PREFIXES:
		for motion in ["idle_","walk_","jump_","dodge_"]:
			if clip.begins_with(family+motion):
				return true
	return false

# Diagonal shooting uses the existing hook-free body and extracted painted
# bow, not cardinal full-body shooting art pasted onto an angled character.
static func is_painted_bow_combat(clip: String) -> bool:
	return not diagonal_name(clip).is_empty() and (clip.begins_with("attack_thornrose_") or clip.begins_with("attack_moonveil_"))

static func painted_bow_assets_available(style: String) -> bool:
	return ResourceLoader.exists("res://assets/equipment/bows_v166/%s_carry_only_2048x1760.png" % style) and ResourceLoader.exists("res://assets/ghost/bows_v139/%s_locomotion_mask_2048x1760.png" % style)

static func is_painted_bow_carry(clip: String) -> bool:
	return is_carried_clip(clip) and (clip.begins_with("thornrose_") or clip.begins_with("moonveil_"))

static func hand_local(body: AnimatedSprite2D) -> Vector2:
	if body==null:
		return Vector2.INF
	var point: Vector2 = wrist(str(body.animation),body.frame)
	if point==Vector2.INF:
		return point
	if body.flip_h:
		point.x=-point.x
	if body.flip_v:
		point.y=-point.y
	return point+body.offset

# Action aliases keep the actual jump/dodge body pose and use its own
# wrist samples. A missing atlas must preserve the older safe fallback.
static func armed_action_clip(action: String, carry_prefix: String, direction: String, fallback: String, frames: SpriteFrames) -> String:
	if frames==null or direction not in DIRECTIONS or action not in ["jump","dodge"]:
		return fallback
	for family in WEAPON_PREFIXES:
		if carry_prefix==family+"walk_" or carry_prefix==family+"idle_":
			var clip: String = family+action+"_"+direction
			if frames.has_animation(clip):
				return clip
	return fallback

# Godot 4.7 and previous releases use different loop APIs.
static func _set_loop_v293(frames: SpriteFrames,clip: String,loops: bool) -> void:
	if frames.has_method("set_animation_loop_mode"):
		frames.call("set_animation_loop_mode",clip,1 if loops else 0)
	else:
		frames.call("set_animation_loop",clip,loops)

static func _loops_v293(frames: SpriteFrames,clip: String) -> bool:
	if frames.has_method("get_animation_loop_mode"):
		return int(frames.call("get_animation_loop_mode",clip))!=0
	return bool(frames.call("get_animation_loop",clip))

# Report missing authored combat artwork rather than passing aliases as complete.
static func missing_combat_clips_v293(frames: SpriteFrames) -> PackedStringArray:
	var missing: PackedStringArray = PackedStringArray()
	if frames==null:
		return missing
	for clip in frames.get_animation_names():
		if not clip.begins_with("attack_") and not clip.begins_with("wand_cast_"):
			continue
		if not diagonal_name(clip).is_empty():
			continue
		if not clip.ends_with("_front"):
			continue
		var stem: String = clip.trim_suffix("front")
		for face in DIRECTIONS:
			if not frames.has_animation(stem+face) or bool(frames.get_meta("v294_reused_"+stem+face,false)):
				missing.append(stem+face)
	return missing

# Initial modular combat pass: genuinely angled existing body cells, with
# weapon motion drawn separately. These are NOT new painted attack poses.
# Mark each reused body clip so the authored-art audit remains truthful.
const MODULAR_COMBAT_V294: Array[String] = [
	"attack_sword_modular_light_", "attack_sword_modular_heavy_", "attack_sword_modular_counter_",
	"attack_sword_light_", "attack_sword_heavy_",
	"attack_unarmed_light_", "attack_unarmed_heavy_",
	"attack_scythe_light_", "attack_scythe_heavy_",
	"attack_halberd_light_", "attack_halberd_heavy_",
	"attack_maul_light_", "attack_maul_heavy_",
	"attack_ashglass_maul_light_", "attack_ashglass_maul_heavy_",
	"attack_dual_sword_light_a_", "attack_dual_sword_light_b_", "attack_dual_sword_light_c_", "attack_dual_sword_heavy_", "attack_dual_sword_riposte_",
	"attack_twinblade_light_", "attack_twinblade_heavy_",
	"attack_rosemirror_twinblade_light_", "attack_rosemirror_twinblade_heavy_",
	"attack_spear_pierce_", "attack_spear_heavy_pierce_",
	"attack_briarwake_spear_pierce_", "attack_briarwake_spear_heavy_pierce_",
	"attack_dagger_pierce_", "attack_dagger_heavy_pierce_",
	"attack_nocturne_dagger_pierce_", "attack_nocturne_dagger_heavy_pierce_",
	"attack_dual_dagger_pierce_", "attack_dual_dagger_heavy_pierce_",
	"attack_dual_dagger_light_a_", "attack_dual_dagger_light_b_", "attack_dual_dagger_light_c_", "attack_dual_dagger_heavy_",
	"attack_rapier_pierce_", "attack_rapier_heavy_pierce_",
	"attack_axe_light_", "attack_axe_heavy_",
	"attack_seraph_scythe_light_", "attack_seraph_scythe_heavy_",
	"attack_thornrose_light_", "attack_thornrose_heavy_",
	"attack_moonveil_light_", "attack_moonveil_heavy_",
	"attack_forge_bow_light_", "attack_forge_bow_heavy_",
	"attack_crossbow_fire_", "attack_crossbow_reload_",
	"attack_forge_dagger_pierce_", "attack_forge_dagger_heavy_pierce_",
	"wand_cast_", "attack_wand_heavy_"
]

static func is_modular_combat_v294(clip: String) -> bool:
	if diagonal_name(clip).is_empty():
		return false
	for stem in MODULAR_COMBAT_V294:
		if clip.begins_with(stem):
			return true
	return false

# Single-grip modular melee actions use measured wrists from the existing
# angled body atlas. This is a staged pose, not a newly painted attack.
static func melee_span(clip: String, frame: int, length: float) -> PackedVector2Array:
	var anchor: Vector2 = wrist(clip,frame)
	var direction: String = diagonal_name(clip)
	if anchor==Vector2.INF or direction.is_empty():
		return PackedVector2Array()
	var i: int = clampi(frame,0,7)
	var angles: Array[float] = [-1.25,-1.55,-0.75,0.0,0.34,1.05,0.64,-0.38]
	if clip.contains("_pierce_"):
		angles.assign([-0.65,-0.85,-0.42,0.0,0.0,0.10,-0.38,-0.65])
	elif clip.contains("_heavy_"):
		angles.assign([-1.35,-1.65,-1.20,-0.35,0.0,1.25,0.80,-0.38])
	var axis: Vector2 = heading_v294(direction).rotated(angles[i]*(-1.0 if direction.ends_with("left") else 1.0))
	return PackedVector2Array([anchor,anchor+axis*length])

# Weighted weapon-head arcs. Heavy recovery poses are deliberately distinct
# from the shorter light sweep; only the rendered geometry is affected.
static func heavy_attack_span(clip: String, frame: int, length: float) -> PackedVector2Array:
	var anchor: Vector2 = wrist(clip,frame)
	var direction: String = diagonal_name(clip)
	if anchor==Vector2.INF or direction.is_empty():
		return PackedVector2Array()
	var n: int = clampi(frame,0,7)
	var side: float = -1.0 if direction.ends_with("left") else 1.0
	var angles: Array[float] = [-1.1,-1.65,-0.95,0.0,0.52,1.08,0.78,-0.50]
	if clip.contains("_heavy_"):
		angles.assign([-1.25,-2.05,-1.55,-0.58,0.0,1.40,0.92,-0.50])
	if clip.contains("maul_"):
		# Overhead hammer windup travels across the target axis at impact.
		angles.assign([-1.4,-2.10,-1.70,-0.75,0.0,0.65,0.85,-0.50] if clip.contains("_heavy_") else [-1.20,-1.60,-0.80,0.0,0.35,0.70,0.52,-0.45])
	var heading: Vector2 = heading_v294(direction).rotated(side*angles[n])
	return PackedVector2Array([anchor,anchor+heading*length])

static func combat_body_source_v294(clip: String) -> String:
	var action: String = "jump_" if clip.contains("_air_") else "dodge_"
	if not clip.contains("_air_") and (clip.contains("forge_bow_") or clip.contains("crossbow_") or is_painted_bow_combat(clip)):
		action="idle_"
	return action+diagonal_name(clip)

static func _install_modular_combat_v294(frames: SpriteFrames) -> void:
	if _load_sheet(REVISED_ACTIONS)==null:
		return # Never draw against unmatched legacy hand coordinates.
	for stem in MODULAR_COMBAT_V294:
		for air in ["","air_"]:
			var prefix: String = stem+air
			for direction in DIRECTIONS:
				var target: String = prefix+direction
				var cardinal: String = "front" if direction.begins_with("front") else "back"
				var timing: String = prefix+cardinal
				var source: String = combat_body_source_v294(target)
				if is_painted_bow_combat(target) and not painted_bow_assets_available("thornrose" if stem.contains("thornrose") else "moonveil"):
					continue
				if frames.has_animation(target) or not frames.has_animation(timing) or not frames.has_animation(source):
					continue
				if frames.get_frame_count(source)!=8 or frames.get_frame_count(timing)<8:
					continue
				frames.add_animation(target)
				_set_loop_v293(frames,target,false)
				frames.set_animation_speed(target,frames.get_animation_speed(timing))
				var count: int = frames.get_frame_count(timing)
				for i in range(8):
					# Preserve total authored duration, including denser sword clips.
					var start: int = floori(float(i*count)/8.0)
					var stop: int = floori(float((i+1)*count)/8.0)
					var duration: float = 0.0
					for sample in range(start,stop):
						duration += frames.get_frame_duration(timing,sample)
					frames.add_frame(target,frames.get_frame_texture(source,i),duration)
				frames.set_meta("v294_reused_"+target,true)

static func combat_clip_v294(requested: String,direction: String,frames: SpriteFrames) -> String:
	if frames==null or direction not in DIRECTIONS or (not requested.begins_with("attack_") and not requested.begins_with("wand_cast_")):
		return requested
	if not diagonal_name(requested).is_empty():
		return requested
	for face in ["front","back","left","right"]:
		if requested.ends_with("_"+face):
			var target: String = requested.trim_suffix(face)+direction
			return target if frames.has_animation(target) else requested
	return requested

static func heading_v294(direction: String) -> Vector2:
	match direction:
		"front_left": return Vector2(-1,1).normalized()
		"front_right": return Vector2(1,1).normalized()
		"back_left": return Vector2(-1,-1).normalized()
		"back_right": return Vector2(1,-1).normalized()
	return Vector2.ZERO

# Eight ordered guard beats use existing approved clean-body cells.
# This is a staged guard animation, not newly painted guard artwork.
const GUARD_FACES: Array[String] = ["front","back","left","right","front_right","front_left","back_left","back_right"]
const GUARD_SEQUENCE: Array[int] = [0,1,2,2,2,2,1,0]
const GUARD_DIAGONAL_SEQUENCE: Array[int] = [0,1,2,3,3,2,1,0]

static func is_guard_clip(clip: String) -> bool:
	return clip.begins_with("parry_") or clip.contains("_parry_")

static func guard_source(clip: String) -> String:
	var face: String = diagonal_name(clip)
	if not face.is_empty():
		return "dodge_"+face
	return "attack_unarmed_light_"+cardinal_for_clip(clip)

static func guard_source_frame(clip: String, frame: int) -> int:
	var i: int = clampi(frame,0,7)
	if not diagonal_name(clip).is_empty():
		return GUARD_DIAGONAL_SEQUENCE[i]
	var sample: int = GUARD_SEQUENCE[i]
	return maxi(1,sample) if cardinal_for_clip(clip)=="back" else sample

static func guard_near_hand(clip: String) -> int:
	if _authored_guides.has(clip):
		return int(_authored_guides[clip]["near_hand"])
	var face: String = diagonal_name(clip)
	if not face.is_empty():
		return near_hand(clip)
	return 0 if cardinal_for_clip(clip)=="left" else 1

static func guard_wrist(clip: String, frame: int, hand: int = -1) -> Vector2:
	var chosen: int = guard_near_hand(clip) if hand<0 else hand
	if _authored_guides.has(clip):
		return authored_wrist(clip,frame,chosen)
	var source: String = guard_source(clip)
	var index: int = guard_source_frame(clip,frame)
	if not diagonal_name(clip).is_empty():
		return hand_wrist(source,index,chosen)
	return preload("res://scripts/dagger_thrust_v186.gd").hand_anchor(cardinal_for_clip(clip),index,chosen)

static func guard_base_span(clip: String, frame: int, length: float, hand: int = -1) -> PackedVector2Array:
	var anchor: Vector2 = guard_wrist(clip,frame,hand)
	if anchor==Vector2.INF:
		return PackedVector2Array()
	var side: float = -1.0 if anchor.x<0.0 else 1.0
	return PackedVector2Array([anchor,anchor+Vector2(side*0.55,0.83).normalized()*length])

static func guard_pair_spans(clip: String, frame: int, length: float) -> Array:
	return [guard_base_span(clip,frame,length,0),guard_base_span(clip,frame,length,1)]

static func install_guards(frames: SpriteFrames) -> void:
	if frames==null:
		return
	var families: Array[String] = [""]
	families.append_array(WEAPON_PREFIXES)
	for face in GUARD_FACES:
		var base: String = "parry_"+face
		if not diagonal_name(base).is_empty() and _load_sheet(REVISED_ACTIONS)==null:
			continue
		var source: String = guard_source(base)
		if not frames.has_animation(source) or frames.get_frame_count(source)<8:
			continue
		for prefix in families:
			var clip: String = prefix+base
			if frames.has_animation(clip):
				if not bool(frames.get_meta("reused_guard_"+clip,false)):
					continue # A dedicated authored replacement takes precedence.
				if frames.get_frame_count(clip)==8:
					for i in range(8):
						frames.set_frame(clip,i,frames.get_frame_texture(source,guard_source_frame(clip,i)))
					continue
				frames.remove_animation(clip)
			frames.add_animation(clip)
			_set_loop_v293(frames,clip,false)
			frames.set_animation_speed(clip,8.0)
			for i in range(8):
				frames.add_frame(clip,frames.get_frame_texture(source,guard_source_frame(clip,i)))
			frames.set_meta("reused_guard_"+clip,true)

static func guard_clip(idle_prefix: String, eight: String, cardinal: String, frames: SpriteFrames) -> String:
	var prefix: String = idle_prefix.trim_suffix("idle_")
	for face in [eight,cardinal]:
		var clip: String = prefix+"parry_"+face
		if frames!=null and frames.has_animation(clip) and frames.get_frame_count(clip)==8:
			return clip
	return ""

# Physics clock controls the pose even during an early confirmed parry.
static func guard_frame(age: float, remaining: float, confirmed: bool = false) -> int:
	if remaining<=0.0:
		return 7
	# A confirmed early contact must visibly catch the weapon in the guard.
	# Only the presentation changes: the existing recovery timer is unchanged.
	if confirmed:
		if remaining>=0.10:
			return 4
		return clampi(5+floori((0.10-remaining)/0.033333),5,7)
	if remaining<0.12:
		return clampi(5+floori((0.12-remaining)/0.04),5,7)
	return clampi(floori(age/0.035),0,4)

# Dedicated art is opt-in. No missing/invalid row is promoted to authored.
# All coordinates are full-cell pixels; [] means deliberately hidden.
const AUTHORED_MANIFEST: String = "res://resources/authored_combat_atlases.json"
static var _authored_guides: Dictionary = {}

static func authored_wrist(clip: String, frame: int, hand: int) -> Vector2:
	if not _authored_guides.has(clip) or hand not in [0,1]:
		return Vector2.INF
	var record: Dictionary = _authored_guides[clip]
	var samples: Array = record["left" if hand==0 else "right"]
	var point: Array = samples[clampi(frame,0,7)]
	if point.is_empty():
		return Vector2.INF
	return Vector2(float(point[0])-128.0,float(point[1])-110.0)

static func _valid_authored_guides(record: Dictionary) -> bool:
	var near: Variant = record.get("near_hand",-1)
	if not (near is int or near is float) or float(near) not in [0.0,1.0]:
		return false
	for key in ["left","right"]:
		var samples: Variant = record.get(key,[])
		if not samples is Array or samples.size()!=8:
			return false
		for point in samples:
			if not point is Array or point.size() not in [0,2]:
				return false
			if point.is_empty():
				continue
			for axis in range(2):
				if not (point[axis] is float or point[axis] is int) or not is_finite(float(point[axis])):
					return false
				if float(point[axis])<0.0 or float(point[axis])>=float(CELL[axis]):
					return false
	return true

static func _authored_clip_allowed(clip: String) -> bool:
	if is_guard_clip(clip):
		var families: Array[String] = [""]
		families.append_array(WEAPON_PREFIXES)
		for family in families:
			for face in GUARD_FACES:
				if clip==family+"parry_"+face:
					return true
		return false
	for stem in MODULAR_COMBAT_V294:
		for face in DIRECTIONS:
			if clip==stem+face or clip==stem+"air_"+face:
				return true
	return false

# Validate every input before replacing any existing frame or guide.
# Preserve the existing weighted timing even when a cardinal source has >8 frames.
static func install_authored_row(frames: SpriteFrames, sheet: Texture2D, row: int, clip: String, record: Dictionary) -> bool:
	if frames==null or not _valid_dimensions(sheet) or row<0 or row>=8 or not _authored_clip_allowed(clip) or not _valid_authored_guides(record):
		return false
	var timing: String = clip
	if not frames.has_animation(timing) or frames.get_frame_count(timing)<8:
		if is_guard_clip(clip):
			timing=clip.trim_suffix(diagonal_name(clip))+cardinal_for_clip(clip) if not diagonal_name(clip).is_empty() else clip
		else:
			timing=clip.trim_suffix(diagonal_name(clip))+cardinal_for_clip(clip)
	if not frames.has_animation(timing) or frames.get_frame_count(timing)<8:
		return false
	var speed: float = frames.get_animation_speed(timing)
	var count: int = frames.get_frame_count(timing)
	var durations: Array[float] = []
	for i in range(8):
		var duration: float = 0.0
		for source in range(floori(float(i*count)/8.0),floori(float((i+1)*count)/8.0)):
			duration+=frames.get_frame_duration(timing,source)
		durations.append(duration)
	if frames.has_animation(clip):
		frames.remove_animation(clip)
	frames.add_animation(clip)
	_set_loop_v293(frames,clip,false)
	frames.set_animation_speed(clip,speed)
	for i in range(8):
		var tile: AtlasTexture = AtlasTexture.new()
		tile.atlas=sheet
		tile.region=Rect2(i*CELL.x,row*CELL.y,CELL.x,CELL.y)
		tile.filter_clip=true
		frames.add_frame(clip,tile,durations[i])
	_authored_guides[clip]=record.duplicate(true)
	frames.set_meta("v294_reused_"+clip,false)
	frames.set_meta("reused_guard_"+clip,false)
	frames.set_meta("authored_combat_"+clip,true)
	return true

static func install_authored_combat(frames: SpriteFrames) -> int:
	if frames==null or not FileAccess.file_exists(AUTHORED_MANIFEST):
		return 0
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string(AUTHORED_MANIFEST))
	if not raw is Dictionary or int(raw.get("version",0))!=1 or not raw.get("rows") is Array:
		push_warning("Invalid authored combat manifest; keeping original animations.")
		return 0
	var count: int = 0
	var seen: Dictionary = {}
	for entry in raw["rows"]:
		if not entry is Dictionary:
			continue
		var path: String = str(entry.get("atlas",""))
		var clip: String = str(entry.get("clip",""))
		var row: Variant = entry.get("row",-1)
		if not path.begins_with("res://assets/ghost/authored_combat/") or path.contains("..") or not path.ends_with(".png") or not (row is float or row is int) or not is_finite(float(row)) or float(row)!=floorf(float(row)) or float(row)<0.0 or float(row)>=8.0:
			push_warning("Invalid authored combat row: "+clip)
			continue
		if seen.has(clip):
			push_warning("Duplicate authored combat clip: "+clip)
			continue
		var sheet: Texture2D = null
		if ResourceLoader.exists(path,"Texture2D"):
			sheet=load(path) as Texture2D
		if install_authored_row(frames,sheet,int(row),clip,entry):
			seen[clip]=true
			count+=1
		else:
			push_warning("Unusable authored combat row: "+clip+"; keeping fallback.")
	return count

static func missing_authored_guards(frames: SpriteFrames) -> PackedStringArray:
	var missing: PackedStringArray = PackedStringArray()
	var families: Array[String] = [""]
	families.append_array(WEAPON_PREFIXES)
	for family in families:
		for face in GUARD_FACES:
			var clip: String = family+"parry_"+face
			if frames==null or not frames.has_animation(clip) or not bool(frames.get_meta("authored_combat_"+clip,false)):
				missing.append(clip)
	return missing

# An explicitly guided pose may deliberately hide either hand.
static func has_guided_pose(clip: String) -> bool:
	return _authored_guides.has(clip)
