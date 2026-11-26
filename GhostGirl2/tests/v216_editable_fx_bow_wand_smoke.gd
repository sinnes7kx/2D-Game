extends SceneTree
## v2.16 local Godot smoke. Synthetic objects only; user:// is never written.
const INV = preload("res://scripts/inventory.gd")
const CHOICES = preload("res://scripts/visual_choices_v216.gd")
const AURA = preload("res://scripts/scythe_glow_layer_v211.gd")
const WAND = preload("res://scripts/wand_anchors_v216.gd")
const PANEL = preload("res://scenes/inventory_panel.tscn")
const MODEL = preload("res://scripts/collector_lens_model_v179.gd")
const LENS = preload("res://scripts/collector_lens_v179.gd")
const PROJECTILE = preload("res://scripts/bow_arrow_v126.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var inv: Node = INV.new()
	var scythe_data: GhostItemData = load("res://items/rose_reaper_scythe.tres") as GhostItemData
	var bow_data: GhostItemData = load("res://items/thornrose_bow.tres") as GhostItemData
	var wand_data: GhostItemData = load("res://items/briar_wand.tres") as GhostItemData
	if scythe_data == null or bow_data == null or wand_data == null:
		_fail("Missing original scythe, bow or wand")
		return
	var scythe: GhostItemInstance = GhostItemGenerator.create(scythe_data, 216001, "rare")
	var bow: GhostItemInstance = GhostItemGenerator.create(bow_data, 216002, "rare")
	var wand: GhostItemInstance = GhostItemGenerator.create(wand_data, 216003, "magic")
	for item in [scythe, bow, wand]:
		inv.contents.append(item)
		inv.grid_positions.append(Vector2i(inv.contents.size() - 1, 0))
	var original_stats: Dictionary = bow.all_stats()
	var original_seed: int = bow.item_seed
	var original_uid: String = bow.cosmetic_uid
	if CHOICES.chosen_glow_level(scythe) != -1 or CHOICES.effect_scale(bow) != 1.0:
		_fail("Older items must keep Natural effect defaults")
		return
	scythe.glow_level_override = 5
	if AURA.rolled_level(scythe) != 5 or not is_equal_approx(AURA.opacity(5), 0.5):
		_fail("User-selected scythe 50% aura not applied")
		return
	scythe.glow_level_override = 0
	if AURA.rolled_level(scythe) != 0 or CHOICES.effect_scale(scythe) != 0.0:
		_fail("Saved Off did not remove optional aura")
		return
	scythe.glow_level_override = -1
	if AURA.rolled_level(scythe) != AURA.rolled_level(scythe):
		_fail("Natural seed aura is not stable")
		return
	bow.apply_cosmetic_uid("abcdef0123456789abcdef0123456789")
	var seeded_style: int = CHOICES.projectile_style(bow)
	if CHOICES.projectile_style(bow) != seeded_style or seeded_style < 0 or seeded_style > 8:
		_fail("Bow projectile appearance is not reproducible from its UID")
		return
	bow.glow_level_override = 3
	if not is_equal_approx(CHOICES.effect_scale(bow), 0.30) or not is_equal_approx(CHOICES.opacity(bow), 0.30):
		_fail("Manual 30% glow must be literal 0.30 opacity, not 60%")
		return
	bow.bow_glow_mode_override = 3
	bow.bow_projectile_style_override = 8
	if CHOICES.projectile_style(bow) != 8 or CHOICES.bow_mode(bow) != 3:
		_fail("Manual bow body/projectile selections failed")
		return
	if not CHOICES.bow_body_visible(bow) or not CHOICES.bow_string_visible(bow):
		_fail("Full bow must retain both body and string light")
		return
	# v2.17: independently selectable limb/string modes must not leak light.
	for case in [
		{"mode": -1, "body": true, "string": true},
		{"mode": 0, "body": false, "string": false},
		{"mode": 1, "body": true, "string": false},
		{"mode": 2, "body": true, "string": true},
		{"mode": 3, "body": true, "string": true}
	]:
		bow.bow_glow_mode_override = int(case["mode"])
		if CHOICES.bow_body_visible(bow) != bool(case["body"]) or CHOICES.bow_string_visible(bow) != bool(case["string"]):
			_fail("Bow body/string visibility does not match selected mode")
			return
	bow.glow_level_override = 0
	if CHOICES.bow_body_visible(bow) or CHOICES.bow_string_visible(bow):
		_fail("Glow Off overrides bow body and string glow regardless of mode")
		return
	bow.glow_level_override = 3
	bow.bow_glow_mode_override = 3
	var fx_source: String = FileAccess.get_file_as_string("res://scripts/weapon_prestige_fx.gd")
	if not fx_source.contains('style == "bow" and not CHOICES_V216.bow_body_visible(item)') or not fx_source.contains('if CHOICES_V216.bow_string_visible(item) else Vector2.ZERO'):
		_fail("World bow FX can still draw seeded light with an explicitly disabled bow body/string")
		return
	var serialized: Dictionary = inv._serialize_item(bow, Vector2i(1, 0))
	var restored_data: Variant = JSON.parse_string(JSON.stringify(serialized))
	if not restored_data is Dictionary:
		_fail("Saved bow JSON cannot be parsed")
		return
	var restored: GhostItemInstance = inv._deserialize_item(restored_data as Dictionary)
	if restored == null or restored.glow_level_override != 3 or restored.bow_glow_mode_override != 3 or restored.bow_projectile_style_override != 8:
		_fail("Saved bow cosmetic controls did not survive reload")
		return
	if restored.item_seed != original_seed or restored.cosmetic_uid != bow.cosmetic_uid or restored.all_stats() != original_stats:
		_fail("Personalization altered stats, seed or cosmetic identity")
		return
	var legacy: Dictionary = serialized.duplicate(true)
	legacy.erase("glow_level_override")
	legacy.erase("bow_glow_mode_override")
	legacy.erase("bow_projectile_style_override")
	var old: GhostItemInstance = inv._deserialize_item(legacy)
	if old == null or old.glow_level_override != -1 or old.bow_glow_mode_override != -1 or old.bow_projectile_style_override != -1:
		_fail("Legacy save without optional fields failed to retain Natural defaults")
		return
	var first_arrow: Node2D = PROJECTILE.new() as Node2D
	first_arrow.set("projectile_style", CHOICES.projectile_style(bow))
	first_arrow.set("visual_glow_scale", CHOICES.effect_scale(bow))
	if first_arrow.get("projectile_style") != 8 or float(first_arrow.get("damage")) != 15.0:
		_fail("Visual bow style unexpectedly altered physical arrow damage")
		return
	first_arrow.free()
	var missing: int = 0
	var decorated: int = 0
	for i in range(256):
		var candidate: GhostItemInstance = GhostItemGenerator.create(bow_data, i + 216100, "rare")
		candidate.apply_cosmetic_uid("%032x" % i)
		var choice: int = CHOICES.projectile_style(candidate)
		if choice == 0:
			missing += 1
		elif choice >= 1 and choice <= 8:
			decorated += 1
	if missing < 100 or decorated < 20:
		_fail("Seed-derived special bows should be less common but discoverable")
		return
	for face in ["front", "back", "left", "right"]:
		for clip in ["wand_idle_", "wand_walk_", "wand_cast_"]:
			var animation_name: String = clip + face
			var raw: PackedVector2Array = WAND.span(animation_name, 0, face)
			if raw.size() != 2:
				_fail("Missing authored wand guide: " + animation_name)
				return
			var actual: Vector2 = raw[0] + WAND.alignment_offset(animation_name, 0, face)
			if actual.distance_to(WAND.target_grip(face)) > 0.02:
				_fail("Shared wand guide does not land at player wrist: " + animation_name)
				return
	var panel: Control = PANEL.instantiate() as Control
	root.add_child(panel)
	panel.call("bind_inventory", inv)
	panel.show()
	panel.call("_on_slot_pressed", 1)
	var controls: ScrollContainer = panel.get("glow_editor") as ScrollContainer
	var choices: Array[Dictionary] = panel.get("glow_choices")
	if controls == null or not controls.visible or choices.size() != 22:
		_fail("Editable glow/bow/arrow groups missing in live inventory")
		return
	var before_blocked: Dictionary = inv._serialize_item(bow, Vector2i(1, 0))
	inv.save_block_reason = "fixture: do not write test items"
	panel.call("_set_glow_choice", true, "glow", 5)
	if inv._serialize_item(bow, Vector2i(1, 0)) != before_blocked:
		_fail("Failed save did not roll back glow edit")
		return
	var lens: Control = LENS.new()
	root.add_child(lens)
	lens.call("bind_inventory", inv)
	lens.call("open_item", scythe)
	lens.call("_select_scythe_glow", 6)
	if scythe.glow_level_override != -1:
		_fail("Lens changed owned item after rejected save")
		return
	lens.call("close_lens")
	lens.free()
	inv.save_block_reason = ""
	var model: Node2D = MODEL.new()
	root.add_child(model)
	model.call("set_item", bow)
	var layer: Sprite2D = model.get_node_or_null("BowGlowLayerV216") as Sprite2D
	if layer == null or not layer.visible:
		_fail("Inspect bow has no separate physical-mask glow layer")
		return
	model.free()
	panel.free()
	inv.free()
	print("v2.16 PASS: saved glow and legacy defaults, rollback, bow masks, rare seeded arrow motifs, shared wand anchors and no stat changes")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
