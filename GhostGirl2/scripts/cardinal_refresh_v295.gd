extends RefCounted
## Candidate cardinal idle/walk art. Isolated names protect existing baked
## weapon bodies, original diagonal art, and old saves. No gameplay changes.
const ATLAS: String = "res://assets/ghost/skins/ghost_cardinal_refresh_candidate.png"
const PREFIX: String = "cardinal_refresh_"
const FACES: Array[String] = ["front","back","left","right"]
const CELL: Vector2i = Vector2i(256,220)
const ROWS: Array[String] = ["idle_front","idle_back","idle_left","idle_right","walk_front","walk_back","walk_left","walk_right"]

static func install(frames: SpriteFrames) -> bool:
	if frames==null or not ResourceLoader.exists(ATLAS,"Texture2D"):
		return false
	return install_sheet(frames,load(ATLAS) as Texture2D)

static func install_sheet(frames: SpriteFrames,sheet: Texture2D) -> bool:
	if frames==null or sheet==null or sheet.get_width()!=2048 or sheet.get_height()!=1760:
		return false
	# All rows must have timing sources. Do not mix partial refreshes with
	# original cardinals, or touch the approved diagonal frames.
	var times: Array[float] = []
	for name in ROWS:
		if not frames.has_animation(name) or frames.get_frame_count(name)==0:
			return false
		var duration: float = 0.0
		for i in range(frames.get_frame_count(name)):
			duration+=frames.get_frame_duration(name,i)/maxf(0.001,frames.get_animation_speed(name))
		if duration<=0.0:
			return false
		times.append(duration)
	for row in range(8):
		var clip: String = PREFIX+ROWS[row]
		if frames.has_animation(clip):
			frames.remove_animation(clip)
		frames.add_animation(clip)
		if frames.has_method("set_animation_loop_mode"):
			frames.call("set_animation_loop_mode",clip,1)
		else:
			frames.call("set_animation_loop",clip,true)
		frames.set_animation_speed(clip,8.0/times[row])
		for col in range(8):
			var cell: AtlasTexture = AtlasTexture.new()
			cell.atlas=sheet
			cell.region=Rect2(col*CELL.x,row*CELL.y,CELL.x,CELL.y)
			cell.filter_clip=true
			frames.add_frame(clip,cell)
	return true

static func resolve(requested: String,eight: String,armed: bool,frames: SpriteFrames) -> String:
	# Baked or modular weapon art must keep its matching wrist guides until
	# the new equipped body art is calibrated, including rear occlusion.
	if armed or frames==null or eight not in FACES:
		return requested
	if requested not in ROWS or not requested.ends_with("_"+eight):
		return requested
	var candidate: String = PREFIX+requested
	return candidate if frames.has_animation(candidate) and frames.get_frame_count(candidate)==8 else requested

static func logical_name(clip: String) -> String:
	return clip.trim_prefix(PREFIX)
