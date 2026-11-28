extends RefCounted
## Conservative render-only restoration of ORIGINAL cardinal poses.
## No substitute atlases, source image edits, new wrist coordinates or saves.
## The diagonal art is never processed by this pass.
const FACES: Array[String] = ["front","back","left","right"]
const DIAGONALS: Array[String] = ["front_right","front_left","back_left","back_right"]
const STRENGTH: float = 0.65
const MATERIAL_PATH: String = "res://assets/equipment/dress_palette.gdshader"

static func supports(name: String) -> bool:
	if name.begins_with("rose_nocturne_") or name.begins_with("cardinal_refresh_"):
		return false
	for face in DIAGONALS:
		if name.ends_with("_"+face):
			return false
	for face in FACES:
		if name.ends_with("_"+face):
			return true
	return false

static func strength_for(name: String, size: Vector2, centered: bool, offset: Vector2, flipped: bool) -> float:
	return STRENGTH if supports(name) and size==Vector2(256,220) and centered and offset==Vector2.ZERO and not flipped else 0.0

static func apply(body: AnimatedSprite2D) -> void:
	if not is_instance_valid(body) or not body.material is ShaderMaterial:
		return
	var material: ShaderMaterial = body.material as ShaderMaterial
	if material.shader==null or material.shader.resource_path!=MATERIAL_PATH:
		return
	var strength: float = 0.0
	var frames: SpriteFrames = body.sprite_frames
	var clip: String = str(body.animation)
	if frames!=null and frames.has_animation(clip) and body.frame<frames.get_frame_count(clip):
		var tile: Texture2D = frames.get_frame_texture(clip,body.frame)
		if tile!=null:
			strength=strength_for(clip,tile.get_size(),body.centered,body.offset,body.flip_h or body.flip_v)
	if float(material.get_shader_parameter("cardinal_finish"))!=strength:
		material.set_shader_parameter("cardinal_finish",strength)

static func attach(body: AnimatedSprite2D) -> void:
	if not is_instance_valid(body):
		return
	# Signals also run on the equipment-preview actor, which has no gameplay
	# process. Existing scene-local material and other uniforms stay intact.
	var refresh: Callable = func(): apply(body)
	body.animation_changed.connect(refresh)
	body.frame_changed.connect(refresh)
	apply(body)
