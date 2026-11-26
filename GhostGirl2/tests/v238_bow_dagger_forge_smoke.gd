extends SceneTree
const FORGE = preload("res://scripts/bow_dagger_forge_v238.gd")
const HAND = preload("res://scripts/dagger_thrust_v186.gd")
func _initialize() -> void:
	var frames: SpriteFrames = SpriteFrames.new()
	var image: Image = Image.create_empty(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture: Texture2D = ImageTexture.create_from_image(image)
	for face in ["front", "back", "left", "right"]:
		var name: String = "attack_unarmed_light_" + face
		frames.add_animation(name)
		for i in range(8):
			frames.add_frame(name, texture)
	FORGE.install(frames)
	for face in ["front", "back", "left", "right"]:
		for name in ["forge_bow_idle_"+face, "forge_bow_walk_"+face, "attack_forge_bow_light_"+face, "attack_forge_bow_heavy_"+face, "forge_dagger_idle_"+face, "forge_dagger_walk_"+face, "attack_forge_dagger_pierce_"+face, "attack_forge_dagger_heavy_pierce_"+face]:
			if not frames.has_animation(name) or frames.get_frame_count(name) != 8:
				_fail("Missing forge clip")
				return
			for i in range(8):
				var wrist: Vector2 = HAND.hand_anchor(face, FORGE.sequence(name, face)[i], 0 if face == "left" else 1)
				var points: PackedVector2Array = FORGE.span(name, face, i)
				if frames.get_frame_texture(name, i) != texture or (wrist == Vector2.INF and not points.is_empty()) or (wrist != Vector2.INF and (points.size() != 2 or points[0] != wrist)):
					_fail("Body reference or wrist drift")
					return
	var tall: Array[PackedVector2Array] = FORGE.limbs(Vector2.ZERO, Vector2.RIGHT, "mourning_yew_bow_v238", 1.0)
	var recurve: Array[PackedVector2Array] = FORGE.limbs(Vector2.ZERO, Vector2.RIGHT, "vesper_recurve_bow_v238", 1.0)
	if tall[0][4].distance_to(tall[1][4]) <= recurve[0][4].distance_to(recurve[1][4]) or tall[0][0] != Vector2.ZERO or recurve[0][0] != Vector2.ZERO:
		_fail("Bow silhouette not distinct or grip shifted")
		return
	for id in ["mourning_yew_bow_v238", "vesper_recurve_bow_v238", "cinderveil_dirk_v238", "reliquary_knife_v238"]:
		var definition: GhostItemData = load("res://items/" + id + ".tres") as GhostItemData
		if definition == null or definition.icon == null:
			_fail("Missing base or icon")
			return
	print("v2.38 PASS: clean frame references, wrist mapping, distinct bow silhouettes and item definitions")
	quit(0)
func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
