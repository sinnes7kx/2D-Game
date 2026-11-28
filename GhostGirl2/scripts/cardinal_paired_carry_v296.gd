extends RefCounted
## Body-only original v110 art with frame-specific, visually estimated grips.
## Only paired weapon locomotion is replaced; combat and guard remain on
## their existing measured body sources. Never modify diagonal art.
const ROOT: String = "res://assets/ghost/weapon_body_v110/"
const FACES: Array[String] = ["front","back","left","right"]
const FAMILIES: Array[String] = ["dual_sword_","dual_dagger_"]
const META: String = "v296_clean_pair_carry"
# Full 256x220 cell coordinates, slots 0/1 as in the paired render rigs.
# Empty entries denote an occluded hand; do not attach a floating blade.
# These guides are visual estimates and require in-engine alignment review.
const GUIDES: Dictionary = {
	"idle_front": [
		[[105,146],[170,143]],[[105,146],[170,143]],[[103,146],[170,143]],[[102,146],[170,143]],
		[[103,146],[170,143]],[[103,147],[169,144]],[[106,146],[171,143]],[[107,145],[171,143]]],
	"walk_front": [
		[[103,146],[165,143]],[[100,146],[168,144]],[[98,144],[169,142]],[[95,141],[171,140]],
		[[99,143],[170,142]],[[101,145],[168,144]],[[103,145],[167,144]],[[103,146],[165,143]]],
	"idle_back": [
		[[],[169,144]],[[],[169,145]],[[],[168,145]],[[],[169,145]],
		[[],[170,145]],[[],[170,145]],[[],[169,145]],[[],[170,145]]],
	"walk_back": [
		[[],[165,140]],[[],[163,141]],[[],[162,141]],[[],[163,141]],
		[[],[163,141]],[[],[165,139]],[[],[166,137]],[[],[165,139]]],
	"idle_left": [
		[[90,137],[108,148]],[[90,137],[108,148]],[[90,138],[108,148]],[[90,138],[108,148]],
		[[88,138],[106,148]],[[86,138],[106,148]],[[85,138],[104,149]],[[85,138],[104,149]]],
	"walk_left": [
		[[88,140],[114,152]],[[88,137],[105,150]],[[87,135],[95,141]],[[82,131],[92,138]],
		[[82,137],[92,145]],[[83,139],[95,148]],[[84,140],[103,151]],[[86,141],[112,152]]],
	"idle_right": [
		[[146,149],[166,138]],[[146,149],[167,138]],[[146,149],[168,139]],[[146,150],[168,139]],
		[[147,150],[169,139]],[[148,150],[169,139]],[[148,150],[168,139]],[[148,150],[168,139]]],
	"walk_right": [
		[[140,152],[165,142]],[[151,150],[165,138]],[[164,140],[171,136]],[[169,140],[175,133]],
		[[169,146],[175,138]],[[163,150],[171,142]],[[154,152],[170,146]],[[150,153],[169,145]]]
}

static func source_key(clip: String) -> String:
	for family in FAMILIES:
		if clip.begins_with(family):
			var key: String = clip.trim_prefix(family)
			return key if GUIDES.has(key) else ""
	return ""

static func install(frames: SpriteFrames) -> int:
	if frames==null:
		return 0
	var installed: Dictionary = frames.get_meta(META,{})
	var count: int = 0
	for key in GUIDES:
		var tiles: Array[Texture2D] = []
		for i in range(8):
			var path: String = ROOT+"%s_%02d.png" % [key,i]
			if not ResourceLoader.exists(path,"Texture2D"):
				break
			var tile: Texture2D = load(path) as Texture2D
			if tile==null or tile.get_size()!=Vector2(256,220):
				break
			tiles.append(tile)
		if tiles.size()!=8:
			continue
		for family in FAMILIES:
			var clip: String = family+key
			if not frames.has_animation(clip) or frames.get_frame_count(clip)!=8 or installed.has(clip):
				continue
			var duration_sum: float = 0.0
			for i in range(8):
				duration_sum+=frames.get_frame_duration(clip,i)
			# Preserve the cycle duration. Blinks are short instead of holding
			# closed eyes for a large portion of the slow equipped idle loop.
			var weights: Array[float] = [1,1,1,1,1,1,1,1]
			if key=="idle_front":
				weights.assign([1,1,1,0.24,0.16,0.24,1,1])
			elif key in ["idle_left","idle_right"]:
				weights.assign([1,1,1,1,0.18,0.18,1,1])
			var total: float = 0.0
			for weight in weights:
				total+=weight
			for i in range(8):
				frames.set_frame(clip,i,tiles[i],weights[i]*duration_sum/total)
			installed[clip]=true
			count+=1
	frames.set_meta(META,installed)
	return count

static func applies(body: AnimatedSprite2D, clip: String) -> bool:
	if not is_instance_valid(body) or body.sprite_frames==null or source_key(clip).is_empty():
		return false
	var installed: Dictionary = body.sprite_frames.get_meta(META,{})
	if not installed.has(clip) or not body.sprite_frames.has_animation(clip) or body.sprite_frames.get_frame_count(clip)!=8:
		return false
	var tile: Texture2D = body.sprite_frames.get_frame_texture(clip,0)
	return tile!=null and tile.resource_path==ROOT+source_key(clip)+"_00.png"

static func grip(clip: String, frame: int, hand: int) -> Vector2:
	var key: String = source_key(clip)
	if key.is_empty() or hand not in [0,1]:
		return Vector2.INF
	var p: Array = GUIDES[key][clampi(frame,0,7)][hand]
	return Vector2.INF if p.is_empty() else Vector2(float(p[0])-128.0,float(p[1])-110.0)

static func spans(clip: String, frame: int, length: float) -> Array:
	var result: Array = []
	var key: String = source_key(clip)
	if key.is_empty():
		return result
	for hand in range(2):
		var anchor: Vector2 = grip(clip,frame,hand)
		if anchor==Vector2.INF:
			result.append(PackedVector2Array())
			continue
		var side: float = -1.0 if hand==0 else 1.0
		# Match the downward, relaxed silhouette of the diagonal carry.
		var axis: Vector2 = Vector2(side*0.49,0.87).normalized()
		result.append(PackedVector2Array([anchor,anchor+axis*length]))
	return result
