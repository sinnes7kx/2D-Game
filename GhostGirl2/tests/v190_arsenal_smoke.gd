extends SceneTree
const SCYTHE = preload("res://scripts/scythe_art_v190.gd")
const PAINT = preload("res://scripts/weapon_surface_v190.gd")
const ART = preload("res://scripts/modular_weapon_art_v178.gd")
const LIBRARY = preload("res://scripts/ghost_animation_library.gd")
const MODEL = preload("res://scripts/collector_lens_model_v179.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var body: AnimatedSprite2D = AnimatedSprite2D.new()
	body.sprite_frames = (load("res://resources/ghost_girl_frames.tres") as SpriteFrames).duplicate(true)
	root.add_child(body)
	LIBRARY.install(body)
	var frames: SpriteFrames = body.sprite_frames
	var speeds: Dictionary = {}
	for name in frames.get_animation_names():
		if SCYTHE.matches(str(name)):
			speeds[name] = frames.get_animation_speed(name)
	SCYTHE.install(body)
	if speeds.size() != 16:
		_fail("Expected 16 scythe motion clips")
		return
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://resources/long_weapon_glow_axes_v143.json"))
	var guides: Dictionary = raw
	for name in speeds:
		var face: String = str(name).get_slice("_", str(name).get_slice_count("_") - 1)
		var source: String = "attack_unarmed_light_" + face
		if frames.get_animation_speed(name) != speeds[name] or frames.get_frame_count(name) != 8:
			_fail("Scythe timing changed")
			return
		for i in range(8):
			if frames.get_frame_texture(name, i) != frames.get_frame_texture(source, SCYTHE.source_frame(str(name), i)):
				_fail("Old baked scythe remains in body")
				return
			var span: PackedVector2Array = SCYTHE.span(str(name), i, guides)
			if span.size() != 2 or not is_equal_approx(span[0].distance_to(span[1]), SCYTHE.REAPER_SPAN):
				_fail("Invalid scythe pose span")
				return
	var item: GhostItemInstance = GhostItemGenerator.create(load("res://items/rose_reaper_scythe.tres") as GhostItemData,190001,"rare")
	item.cosmetic_uid = "123456789abcdef0123456789abcdef0"
	var look: Dictionary = item.collector_appearance()
	var p: Dictionary = ART.weapon_profile(look,item.definition.item_id)
	p["scythe_span"] = look["scythe_span"]
	p["scythe_curve"] = look["scythe_curve"]
	var edges: Array[PackedVector2Array] = SCYTHE.contours(Vector2.ZERO,Vector2.UP,p)
	if edges.size() != 2 or edges[0].size() != 13 or edges[0][-1] != edges[1][-1]:
		_fail("Scythe has no exact pointed tip")
		return
	p["scythe_curve"] = 0.99
	if SCYTHE.contours(Vector2.ZERO,Vector2.UP,p)[0] == edges[0]:
		_fail("Curve roll has no geometric effect")
		return
	var model: Node2D = MODEL.new()
	root.add_child(model)
	model.call("set_item",item)
	if not model.call("is_modular") or not item.supports_ethereal():
		_fail("Scythe inspection or Ethereal support missing")
		return
	await process_frame
	for path in ["res://items/thornrose_bow.tres","res://items/moonveil_bow.tres","res://items/briar_wand.tres"]:
		var painted: GhostItemInstance = GhostItemGenerator.create(load(path) as GhostItemData,190002,"rare")
		painted.cosmetic_uid = item.cosmetic_uid
		var stats: Dictionary = painted.all_stats()
		painted.debug_surface_mode = 6
		model.call("set_item",painted)
		var preview: Sprite2D = model.get_node_or_null("PaintedMaterialPreviewV190")
		if preview == null or not preview.visible or preview.texture != painted.definition.icon:
			_fail("Original painted item preview missing")
			return
		var mat: ShaderMaterial = preview.material as ShaderMaterial
		if mat == null or mat.shader != PAINT.SHADER or (OS.is_debug_build() and int(mat.get_shader_parameter("surface_mode")) != 6):
			_fail("Painted surface not bound")
			return
		if not bool(mat.get_shader_parameter("refined_finish")):
			_fail("Painted bow/wand refined finish not bound")
			return
		var ramp: GradientTexture1D = mat.get_shader_parameter("pigment_ramp")
		if ramp == null or ramp.gradient.colors.size() < 3 or painted.all_stats() != stats:
			_fail("Painted pigment or stat preservation failed")
			return
		await process_frame
	model.call("set_item",null)
	if model.get_node("PaintedMaterialPreviewV190").visible:
		_fail("Stale painted weapon preview")
		return
	model.free()
	body.free()
	print("v1.90 PASS: 16 preserved scythe motions, curved pointed blade, Ethereal eligibility and three painted weapon material previews")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
