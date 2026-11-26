extends SceneTree
const POSE = preload("res://scripts/v172_weapon_pose.gd")
const HAND = preload("res://scripts/dagger_thrust_v186.gd")
const GAME = preload("res://scripts/game.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var frames: SpriteFrames = SpriteFrames.new()
	var image: Image = Image.create_empty(8, 8, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	var texture: Texture2D = ImageTexture.create_from_image(image)
	for face in ["front", "back", "left", "right"]:
		var source: String = "attack_unarmed_light_" + face
		frames.add_animation(source)
		for i in range(8):
			frames.add_frame(source, texture)
	POSE.install_single_swords(frames)
	for face in ["front", "back", "left", "right"]:
		for name in ["sword_modular_idle_" + face, "sword_modular_walk_" + face, "attack_sword_modular_light_" + face, "attack_sword_modular_heavy_" + face, "attack_sword_modular_counter_" + face]:
			if not frames.has_animation(name) or frames.get_frame_count(name) != 8:
				_fail("Missing modular clip")
				return
			for i in range(8):
				var source_index: int = POSE.single_sword_sequence(name, face)[i]
				var wrist: Vector2 = HAND.hand_anchor(face, source_index, 0 if face == "left" else 1)
				var span: PackedVector2Array = POSE.single_sword_span(name, face, i)
				if frames.get_frame_texture(name, i) != texture:
					_fail("Source texture replaced")
					return
				if wrist == Vector2.INF:
					if not span.is_empty():
						_fail("Detached hidden sword")
						return
				elif span.size() != 2 or span[0] != wrist or not is_equal_approx(span[0].distance_to(span[1]), 60.0):
					_fail("Sword grip or length drift")
					return
	var game: Node = GAME.new()
	var original: GhostItemData = load("res://items/dusk_needle.tres") as GhostItemData
	var seen: Dictionary = {}
	for seed in range(1, 8000):
		var definition: GhostItemData = game.call("_roll_sword_drop", original, seed) as GhostItemData
		if definition != null and str(definition.item_id).ends_with("_v235"):
			var item: GhostItemInstance = GhostItemGenerator.create(definition, 1234, "rare")
			if not item.uses_modular_single_sword() or item.weapon_style() != "blade" or definition.icon == null:
				_fail("Invalid new single sword")
				return
			seen[definition.item_id] = true
	if seen.size() != 3:
		_fail("New swords missing from loot")
		return
	game.free()
	print("v2.35 PASS: shared source frames and wrist spans, three single sword bases")
	quit(0)

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
