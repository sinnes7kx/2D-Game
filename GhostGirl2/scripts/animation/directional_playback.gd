extends RefCounted
## Presentation only: one entry point for selecting body clips and applying
## their timing. Combat clocks, input and weapon hit logic remain in player.
const ART = preload("res://scripts/ghost_diagonal_art_v247.gd")
const SKIN = preload("res://scripts/rose_nocturne_skin_v246.gd")
const MOTION = preload("res://scripts/gentle_weapon_motion_v191.gd")
const CARDINAL = preload("res://scripts/cardinal_refresh_v295.gd")

static func has_clip(frames: SpriteFrames, clip: String) -> bool:
	return frames!=null and frames.has_animation(clip) and frames.get_frame_count(clip)>0

static func locomotion_clip(requested: String,eight: String,cardinal: String,armed: bool,frames: SpriteFrames) -> String:
	if requested.begins_with("throw_empty_"):
		var empty: String = requested.trim_prefix("throw_empty_")
		var diagonal: String = ART.resolve(empty,eight,cardinal,false,frames)
		return diagonal if diagonal!=empty else requested
	if armed:
		return ART.armed_clip(requested,eight,cardinal,frames)
	if SKIN.current()==SKIN.NOCTURNE:
		var skin_clip: String = SKIN.resolve(requested,eight,cardinal,false,frames)
		if skin_clip!=requested and has_clip(frames,skin_clip):
			return skin_clip
		# Missing alternate skin rows fall back to the original angled art.
	var resolved: String = ART.resolve(requested,eight,cardinal,false,frames)
	return CARDINAL.resolve(resolved,eight,false,frames)

static func gesture_clip(action: String,fallback: String,eight: String,cardinal: String,walk_prefix: String,armed: bool,thrown: bool,frames: SpriteFrames) -> String:
	if thrown:
		return ART.action_clip(action,eight,fallback,frames)
	if not armed and SKIN.current()!=SKIN.ORIGINAL:
		return fallback
	if armed:
		var safe: String = ART.armed_jump_carry(fallback,eight,cardinal,frames) if action=="jump" else fallback
		return ART.armed_action_clip(action,walk_prefix,eight,safe,frames)
	return ART.action_clip(action,eight,fallback,frames)

static func action_clip(requested: String,eight: String,frames: SpriteFrames) -> String:
	var clip: String = ART.combat_clip_v294(requested,eight,frames)
	return clip if has_clip(frames,clip) else requested

# Only suffixes actually present are rewritten. Never replace a weapon
# family substring or choose a direction merely because its name is similar.
static func retarget_request(current: String,cardinal: String) -> String:
	var suffix: String = ART.diagonal_name(current)
	if suffix.is_empty():
		suffix = ART.cardinal_for_clip(current,"")
	if suffix.is_empty():
		return current
	return current.trim_suffix(suffix)+cardinal

static func play_locomotion(body: AnimatedSprite2D,clip: String) -> void:
	if body==null or not has_clip(body.sprite_frames,clip) or str(body.animation)==clip:
		return
	var phase: float = MOTION.phase_of(body) if MOTION.same_locomotion_family(str(body.animation),clip) else -1.0
	body.play(clip)
	if phase>=0.0:
		MOTION.seek_phase(body,phase)

# Return the exact custom playback rate for later hitstop/menu resume.
static func play_action(body: AnimatedSprite2D,requested: String,eight: String,cardinal: String,seconds: float) -> float:
	if body==null:
		return 1.0
	body.speed_scale=1.0
	var clip: String = action_clip(requested,eight,body.sprite_frames)
	if not has_clip(body.sprite_frames,clip):
		push_warning("Missing combat animation: "+clip)
		var idle: String = "idle_"+cardinal
		if has_clip(body.sprite_frames,idle):
			body.play(idle)
		return 1.0
	var rate: float = MOTION.playback_rate(body.sprite_frames,clip,seconds)
	body.play(clip,rate)
	return rate

static func resume_action(body: AnimatedSprite2D,rate: float) -> void:
	if body==null or not has_clip(body.sprite_frames,str(body.animation)):
		return
	var index: int = body.frame
	var progress: float = body.frame_progress
	body.play(body.animation,rate)
	body.set_frame_and_progress(index,progress)

# Stable weighted phase for a held action, including a completed charge.
# A missing directional variant leaves the current pose undisturbed.
static func retarget_action(body: AnimatedSprite2D,cardinal: String,eight: String,seconds: float,previous_rate: float) -> float:
	if body==null or not has_clip(body.sprite_frames,str(body.animation)):
		return previous_rate
	var requested: String = retarget_request(str(body.animation),cardinal)
	var resolved: String = action_clip(requested,eight,body.sprite_frames)
	if not has_clip(body.sprite_frames,resolved) or resolved==str(body.animation):
		return previous_rate
	var phase: float = MOTION.phase_of(body)
	var paused: bool = not body.is_playing()
	var rate: float = play_action(body,requested,eight,cardinal,seconds)
	MOTION.seek_phase(body,phase,false)
	if paused:
		body.pause()
	return rate

# Bows reserve the first six authored beats for draw and the next for
# release. Clamp for shorter fallback clips; do not sample nonexistent cells.
static func bow_draw_frame(fraction: float,count: int) -> int:
	return mini(maxi(0,count-1),mini(5,floori(clampf(fraction,0.0,1.0)*5.0)))

static func apply_bow_draw(body: AnimatedSprite2D,fraction: float) -> void:
	if body==null or not has_clip(body.sprite_frames,str(body.animation)):
		return
	body.set_frame_and_progress(bow_draw_frame(fraction,body.sprite_frames.get_frame_count(body.animation)),0.0)
	body.pause()

static func apply_bow_release(body: AnimatedSprite2D,rate: float) -> void:
	if body==null or not has_clip(body.sprite_frames,str(body.animation)):
		return
	body.set_frame_and_progress(mini(6,body.sprite_frames.get_frame_count(body.animation)-1),0.0)
	resume_action(body,rate)
