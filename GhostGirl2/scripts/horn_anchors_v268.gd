extends RefCounted
## Pixel-space horn roots on the actual approved body frames. The optional
## diagonal atlases are not required at parse time. Cache only the small
## measured results and at most one decoded atlas.
const CELL: Vector2i = Vector2i(256,220)
const DIAGONAL = preload("res://scripts/ghost_diagonal_art_v247.gd")
var roots_cache: Dictionary = {}
var cached_atlas: Texture2D
var cached_image: Image

static func direction(clip: String, fallback: String) -> String:
	var diagonal: String = DIAGONAL.diagonal_name(clip)
	if not diagonal.is_empty():
		return diagonal
	return DIAGONAL.cardinal_for_clip(clip,fallback)

static func fallback_roots(face: String) -> PackedVector2Array:
	# Observed upper hairline on the four original idle reference frames.
	# Coordinates are within the full 256 x 220 cell, before sprite centering.
	match face:
		"left": return PackedVector2Array([Vector2(106,35),Vector2(143,34)])
		"right": return PackedVector2Array([Vector2(111,34),Vector2(147,35)])
		"back", "back_left", "back_right": return PackedVector2Array([Vector2(104,35),Vector2(151,35)])
		"front_left": return PackedVector2Array([Vector2(105,35),Vector2(147,35)])
		"front_right": return PackedVector2Array([Vector2(110,35),Vector2(152,35)])
		_: return PackedVector2Array([Vector2(110,35),Vector2(160,35)])

static func _longest_run(img: Image, y: int) -> Vector2i:
	var left: int = -1
	var best: Vector2i = Vector2i(-1,-1)
	for x in range(40,216):
		var solid: bool = img.get_pixel(x,y).a>=0.60
		if solid and left<0:
			left=x
		if (not solid or x==215) and left>=0:
			var right: int = x if solid else x-1
			if best.x<0 or right-left>best.y-best.x:
				best=Vector2i(left,right)
			left=-1
	return best

static func measure(img: Image, face: String) -> PackedVector2Array:
	if img==null or img.get_size()!=CELL:
		return PackedVector2Array()
	if img.is_compressed() and img.decompress()!=OK:
		return PackedVector2Array()
	var top: int = -1
	for y in range(0,76):
		var run: Vector2i = _longest_run(img,y)
		# Reject thin stray strands and narrow weapon silhouettes.
		if run.x>=0 and run.y-run.x>=19:
			top=y
			break
	if top<0:
		return PackedVector2Array()
	var row: int = top+17
	var span: Vector2i = _longest_run(img,row)
	var width: float = float(span.y-span.x+1)
	if span.x<0 or width<34.0 or width>126.0:
		return PackedVector2Array()
	var center: float = (float(span.x)+float(span.y))*0.5
	var profile: bool = face in ["left","right"]
	var diagonal: bool = face.contains("_")
	var spread: float = width*(0.27 if profile else (0.32 if diagonal else 0.34))
	# Both roots stay inside the hair silhouette, rather than at its edges.
	return PackedVector2Array([Vector2(center-spread,row+1),Vector2(center+spread,row+1)])

func _frame_image(texture: Texture2D) -> Image:
	if texture is AtlasTexture:
		var frame: AtlasTexture = texture as AtlasTexture
		if frame.atlas==null or frame.margin!=Rect2() or frame.region.size!=Vector2(CELL):
			return null
		if cached_atlas!=frame.atlas or cached_image==null:
			cached_atlas=frame.atlas
			cached_image=frame.atlas.get_image()
		if cached_image==null:
			return null
		if cached_image.is_compressed() and cached_image.decompress()!=OK:
			cached_image=null
			return null
		var region: Rect2i = Rect2i(frame.region)
		if not Rect2i(Vector2i.ZERO,cached_image.get_size()).encloses(region):
			return null
		return cached_image.get_region(region)
	if texture.get_size()==Vector2(CELL):
		return texture.get_image()
	return null

func frame_roots(sprite: AnimatedSprite2D, face: String) -> PackedVector2Array:
	if sprite==null or sprite.sprite_frames==null:
		return fallback_roots(face)
	var clip: String = str(sprite.animation)
	if not sprite.sprite_frames.has_animation(clip) or sprite.sprite_frames.get_frame_count(clip)<=sprite.frame:
		return fallback_roots(face)
	var texture: Texture2D = sprite.sprite_frames.get_frame_texture(clip,sprite.frame)
	if texture==null:
		return fallback_roots(face)
	# Body art with large baked attack arcs is not a reliable silhouette
	# scan. Retain the directional reference for those clips.
	if not (clip.contains("idle_") or clip.contains("walk_") or clip.begins_with("blink_") or clip.begins_with("dodge_") or clip.begins_with("jump_")):
		return fallback_roots(face)
	var key: String = "%d:%s" % [texture.get_instance_id(),face]
	if not roots_cache.has(key):
		if roots_cache.size()>=512:
			roots_cache.clear()
		var result: PackedVector2Array = measure(_frame_image(texture),face)
		roots_cache[key]=result if result.size()==2 else fallback_roots(face)
	return roots_cache[key]

static func pixel_to_local(pixel: Vector2, sprite: AnimatedSprite2D) -> Vector2:
	# Full cell coordinates, then account for the sprite's real draw offset.
	var p: Vector2 = pixel
	if sprite.flip_h:
		p.x=float(CELL.x)-p.x
	if sprite.flip_v:
		p.y=float(CELL.y)-p.y
	if sprite.centered:
		p-=Vector2(CELL)*0.5
	return p+sprite.offset

static func far_side(face: String) -> int:
	if face.ends_with("left"):
		return 0
	if face.ends_with("right"):
		return 1
	return -1

# Drawing units preserve the existing accessory scale, while a shared
# transform applies the animated body's real translation, lean and stretch.
const ART_SCALE: float = 0.52

static func head_center(roots: PackedVector2Array,sprite: AnimatedSprite2D) -> Vector2:
	if roots.size()!=2 or sprite==null:
		return Vector2.ZERO
	return pixel_to_local((roots[0]+roots[1])*0.5,sprite)*ART_SCALE

static func crown_width(roots: PackedVector2Array) -> float:
	return clampf(roots[0].distance_to(roots[1])*ART_SCALE*0.67,13.0,23.0) if roots.size()==2 else 17.0

static func halo_lift(crown: bool,horns: bool) -> float:
	return 35.0 if horns else (25.0 if crown else 16.0)

static func accessory_transform(sprite: AnimatedSprite2D,layer: Node2D) -> Transform2D:
	var unscale: Transform2D = Transform2D(Vector2(1.0/ART_SCALE,0),Vector2(0,1.0/ART_SCALE),Vector2.ZERO)
	return layer.global_transform.affine_inverse()*sprite.global_transform*unscale

static func horn_index(step: int,far: int) -> int:
	# Draw the far horn first without allocating or coercing typed arrays.
	return 1-step if far==1 else step
