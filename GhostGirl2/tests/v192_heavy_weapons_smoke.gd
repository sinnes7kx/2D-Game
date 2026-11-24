extends SceneTree
const HEAVY = preload("res://scripts/heavy_weapon_art_v192.gd")
const GENTLE = preload("res://scripts/gentle_weapon_motion_v191.gd")
const ART = preload("res://scripts/modular_weapon_art_v178.gd")
const LIBRARY = preload("res://scripts/ghost_animation_library.gd")
const MODEL = preload("res://scripts/collector_lens_model_v179.gd")
const INV = preload("res://scripts/inventory.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.sprite_frames = (load("res://resources/ghost_girl_frames.tres") as SpriteFrames).duplicate(true)
	root.add_child(sprite)
	LIBRARY.install(sprite)
	var frames: SpriteFrames = sprite.sprite_frames
	var speeds: Dictionary = {}
	for value in frames.get_animation_names():
		if HEAVY.matches(str(value)):
			speeds[value] = frames.get_animation_speed(value)
	HEAVY.install(sprite)
	if speeds.size() != 48:
		_fail("Expected 48 heavy-weapon directional clips")
		return
	var guides: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/long_weapon_glow_axes_v143.json"))
	guides.merge(JSON.parse_string(FileAccess.get_file_as_string("res://resources/new_weapon_axes_v170.json")),false)
	for value in speeds:
		var name: String = str(value)
		var face: String = name.get_slice("_",name.get_slice_count("_")-1)
		var source: String = "attack_unarmed_light_" + face
		if frames.get_animation_speed(name) != speeds[value] or frames.get_frame_count(name) != 8:
			_fail("Heavy weapon attack timing or frame count changed")
			return
		for i in range(8):
			if frames.get_frame_texture(name,i) != frames.get_frame_texture(source,HEAVY.source_frame(name,i)):
				_fail("Baked weapon still present")
				return
			var points: PackedVector2Array = HEAVY.span(name,i,guides)
			if points.size() != 2 or not is_equal_approx(points[0].distance_to(points[1]),82.0 if name.contains("halberd") else 54.0):
				_fail("Invalid grip or shaft span: "+name)
				return
	GENTLE.install(sprite)
	var inv: Node = INV.new()
	var model: Node2D = MODEL.new()
	root.add_child(model)
	for path in ["res://items/lunar_vigil_halberd.tres","res://items/gravebell_maul_v170.tres","res://items/ashglass_warmaul_v170.tres"]:
		var item: GhostItemInstance = GhostItemGenerator.create(load(path) as GhostItemData,192001,"rare")
		item.cosmetic_uid = "123456789abcdef0123456789abcdef0"
		var look: Dictionary = item.collector_appearance()
		var profile: Dictionary = ART.weapon_profile(look,item.definition.item_id)
		profile["heavy_head_span"] = look["heavy_head_span"]
		profile["heavy_head_flare"] = look["heavy_head_flare"]
		var outline: PackedVector2Array = HEAVY.halberd_outline(Vector2.ZERO,Vector2.UP,profile) if item.weapon_style()=="halberd" else HEAVY.maul_outline(Vector2.ZERO,Vector2.UP,profile,str(item.definition.item_id)=="ashglass_warmaul_v170")
		if outline.size() < 6 or Geometry2D.triangulate_polygon(outline).is_empty():
			_fail("Invalid head polygon")
			return
		var changed: Dictionary = profile.duplicate()
		changed["heavy_head_span"] = float(profile["heavy_head_span"])*1.15
		var other: PackedVector2Array = HEAVY.halberd_outline(Vector2.ZERO,Vector2.UP,changed) if item.weapon_style()=="halberd" else HEAVY.maul_outline(Vector2.ZERO,Vector2.UP,changed,str(item.definition.item_id)=="ashglass_warmaul_v170")
		if other == outline:
			_fail("Head RNG did not alter geometry")
			return
		var stats: Dictionary = item.all_stats()
		model.call("set_item",item)
		if not model.call("is_modular") or not item.supports_ethereal():
			_fail("Inspection or Ethereal support missing")
			return
		await process_frame
		var restored: GhostItemInstance = inv._deserialize_item(inv._serialize_item(item,Vector2i.ZERO))
		if restored == null or restored.collector_appearance()!=look or restored.all_stats()!=stats:
			_fail("Save roundtrip changed heavy weapon")
			return
	model.free()
	sprite.free()
	inv.free()
	print("v1.92 PASS: 48 directional clips, intact body poses, grip spans, heavy head variation, inspection and save fidelity")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
