extends SceneTree
## v2.15 in-memory item/GUI regression; no user:// save writes.
const INV = preload("res://scripts/inventory.gd")
const EYES = preload("res://scripts/head_cosmetics_v202.gd")
const PLAYER = preload("res://scenes/player.tscn")
const MODEL = preload("res://scripts/collector_lens_model_v179.gd")
const BOW = preload("res://scripts/bow_palette_overlay_v139.gd")
const PANEL = preload("res://scenes/inventory_panel.tscn")
const HUD = preload("res://scripts/hud.gd")

func _initialize() -> void:
	call_deferred("_check")

func _check() -> void:
	var inv: Node = INV.new()
	var eye_data: GhostItemData = load("res://items/v202_luminous_eyes.tres") as GhostItemData
	var bow_data: GhostItemData = load("res://items/thornrose_bow.tres") as GhostItemData
	if eye_data == null or bow_data == null:
		_fail("Required original eye/bow items are missing")
		return
	var eyes: GhostItemInstance = GhostItemGenerator.create(eye_data, 215001, "rare")
	var bow: GhostItemInstance = GhostItemGenerator.create(bow_data, 215002, "magic")
	inv.contents.append(eyes)
	inv.grid_positions.append(Vector2i.ZERO)
	inv.contents.append(bow)
	inv.grid_positions.append(Vector2i(1, 0))
	inv.equipment["wings"] = 0
	inv.equipment["sword"] = 1
	var base_eyes: Dictionary = inv._serialize_item(eyes, Vector2i.ZERO)
	if eyes.eye_style_override != -1 or eyes.eye_palette_override != -1:
		_fail("Legacy eyes should keep their originally seeded look")
		return
	var front: Array[Vector2] = EYES.pose_eye_centers("idle_front", 0, "front")
	var walk: Array[Vector2] = EYES.pose_eye_centers("walk_front", 3, "front")
	var stab: Array[Vector2] = EYES.pose_eye_centers("attack_unarmed_light_front", 3, "front")
	if front.size() != 2 or walk.size() != 2 or stab.size() != 2:
		_fail("Front eyes disappeared during idle/walk/attack")
		return
	if front[0] == walk[0] or front[0] == stab[0] or front[0].y > -38.0:
		_fail("Eye overlay is not following the approved head region")
		return
	for face in ["left", "right"]:
		for clip in ["idle_", "walk_", "attack_unarmed_light_", "dodge_"]:
			if EYES.pose_eye_centers(clip + face, 5, face).size() != 1:
				_fail("Side-facing animated eye position missing")
				return
	if not EYES.pose_eye_centers("idle_back", 4, "back").is_empty():
		_fail("Back view should conceal pupils")
		return
	var item_record: Dictionary = inv._serialize_item(eyes, Vector2i.ZERO)
	eyes.eye_style_override = 2
	eyes.eye_palette_override = 3
	var edited: Dictionary = inv._serialize_item(eyes, Vector2i.ZERO)
	if edited["seed"] != base_eyes["seed"] or edited["cosmetic_uid"] != base_eyes["cosmetic_uid"] or edited["rare_visual_mod"] != base_eyes["rare_visual_mod"]:
		_fail("Eye styling altered intrinsic loot or collector identity")
		return
	var saved: Variant = JSON.parse_string(JSON.stringify(edited))
	if not saved is Dictionary:
		_fail("Serialized eye record could not be parsed as a Dictionary")
		return
	var restored: GhostItemInstance = inv._deserialize_item(saved as Dictionary)
	if restored == null or restored.eye_style_override != 2 or restored.eye_palette_override != 3:
		_fail("New eye options did not survive JSON reload")
		return
	eyes.eye_style_override = -1
	eyes.eye_palette_override = -1
	var legacy: Dictionary = item_record.duplicate(true)
	legacy.erase("eye_style_override")
	legacy.erase("eye_palette_override")
	var old: GhostItemInstance = inv._deserialize_item(legacy)
	if old == null or old.eye_style_override != -1 or old.eye_palette_override != -1:
		_fail("Old eye save does not preserve natural seeded appearance")
		return
	var panel: Control = PANEL.instantiate() as Control
	root.add_child(panel)
	panel.call("bind_inventory", inv)
	panel.show()
	panel.call("focus_eye_item", eyes)
	var editor: ScrollContainer = panel.get("eye_editor") as ScrollContainer
	var choices: Array[Dictionary] = panel.get("eye_choices")
	if editor == null or not editor.visible or choices.size() != 12:
		_fail("Actual inventory does not expose grouped eye style + color controls")
		return
	# Intentionally simulate a blocked save; never write test items into user://.
	inv.save_block_reason = "fixture: prevent save writes"
	panel.call("_set_eye_choice", true, "shape", 2)
	if eyes.eye_style_override != -1 or inv._serialize_item(eyes, Vector2i.ZERO) != item_record:
		_fail("Eye editor failed to roll back a blocked save")
		return
	var model: Node2D = MODEL.new()
	root.add_child(model)
	model.call("set_item", bow)
	var mask: Sprite2D = model.get_node_or_null("ActualBowPaletteMaskV215") as Sprite2D
	var paint: Sprite2D = model.get("painted_preview") as Sprite2D
	if mask == null or paint == null or not mask.visible or not paint.visible:
		_fail("Bow Inspector still uses icon-only art instead of the carried bow")
		return
	if not paint.texture is AtlasTexture or not mask.texture is AtlasTexture or not mask.material is ShaderMaterial:
		_fail("Bow inspection is not sharing the carried atlas and palette mask")
		return
	var pose: Dictionary = BOW.idle_hold_pose("front")
	if not is_equal_approx(paint.rotation_degrees, float(pose["rotation_deg"])) or mask.position != paint.position:
		_fail("Bow inspect physical art/palette pose mismatch")
		return
	if inv._serialize_item(bow, Vector2i(1, 0))["seed"] != 215002:
		_fail("Bow appearance preview modified the actual item")
		return
	var hud_source: String = FileAccess.get_file_as_string("res://scripts/hud.gd")
	var project_source: String = FileAccess.get_file_as_string("res://project.godot")
	if not hud_source.contains("KEY_B") or not project_source.contains("inventory={"):
		_fail("B inventory shortcut is missing")
		return
	var fx_source: String = FileAccess.get_file_as_string("res://scripts/weapon_prestige_fx.gd")
	if not fx_source.contains("mask.visible") or not fx_source.contains("carry.visible"):
		_fail("Bow special FX can still become children of a hidden mask")
		return
	model.free()
	panel.free()
	inv.free()
	print("v2.15 PASS: pose-aware eyes, editable eye persistence and failed-save rollback, carried bow art parity, B input and visible FX parent")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
