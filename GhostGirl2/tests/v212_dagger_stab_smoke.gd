extends SceneTree
## v2.12 actual atlas-based thrust clips + source and save invariants.
## No player save files are opened or modified.
const PLAYER = preload("res://scripts/player.gd")
const THRUST = preload("res://scripts/dagger_thrust_v186.gd")
const LIBRARY = preload("res://scripts/ghost_animation_library.gd")
const INV = preload("res://scripts/inventory.gd")

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var actor: CharacterBody2D = PLAYER.new()
	actor.set("equipment_preview_only", true)
	var inv: Node = INV.new()
	var resource: GhostItemData = load("res://items/roseglass_dagger_v169.tres") as GhostItemData
	if resource == null:
		_fail("Dagger item resource missing")
		return
	var dagger: GhostItemInstance = GhostItemGenerator.create(resource, 212031, "rare")
	var before: Dictionary = inv._serialize_item(dagger, Vector2i.ZERO)
	var frames: SpriteFrames = (load("res://resources/ghost_girl_frames.tres") as SpriteFrames).duplicate(true)
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	root.add_child(sprite)
	LIBRARY.install(sprite)
	THRUST.install(sprite)
	for face in ["front", "back", "left", "right"]:
		for action in ["pierce", "heavy_pierce"]:
			var name: String = "attack_dagger_" + action + "_" + face
			if not frames.has_animation(name) or frames.get_frame_count(name) != 8:
				_fail("Missing 8-frame stab: " + name)
				return
			var span: PackedVector2Array = THRUST.single_span(face, 3, action == "heavy_pierce")
			if span.size() != 2 or (span[1] - span[0]).normalized().dot(THRUST.direction(face)) < 0.99:
				_fail("Blade tip isn't thrusting along facing: " + name)
				return
	var code: String = FileAccess.get_file_as_string("res://scripts/player.gd")
	if not code.contains('if active_attack_style == "dagger":') or not code.contains('"_pierce_"') or not code.contains('attack_duration = 0.94 if heavy') or not code.contains('dagger_charge_active = heavy and active_attack_style == "dagger"') or not code.contains('DAGGER_CHARGE_MAX'):
		_fail("Single dagger did not route both attack inputs through separate thrusts")
		return
	if not code.contains('if active_attack_style != "dagger":\n\t\t\t\t_spawn_rose_slash'):
		_fail("Contact still spawns unrelated dagger slash sprite")
		return
	var vault_code: String = FileAccess.get_file_as_string("res://scripts/collection_vault_v181.gd")
	if vault_code.contains("if not query.is_empty()"):
		_fail("Obsolete vault query parser regression returned")
		return
	if inv._serialize_item(dagger, Vector2i.ZERO) != before:
		_fail("Dagger animation change mutated serialized item")
		return
	sprite.free()
	actor.free()
	inv.free()
	print("v2.12 PASS: light/charged dagger stab clips, no crescent on contact, item unchanged")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
