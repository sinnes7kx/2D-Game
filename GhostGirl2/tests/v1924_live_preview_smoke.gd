extends SceneTree
const INV = preload("res://scripts/inventory.gd")
const FX = preload("res://scripts/fx_intensity_v1924.gd")
const EQUIP = preload("res://scenes/equipment_panel.tscn")
const PANEL = preload("res://scenes/inventory_panel.tscn")
const GENTLE = preload("res://scripts/gentle_weapon_motion_v191.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	# No inventory is added to the tree: do not load or write real player saves.
	var inv: Node = INV.new()
	var twin: GhostItemInstance = GhostItemGenerator.create(load("res://items/rosemirror_twinblade_v170.tres") as GhostItemData, 192401, "rare")
	var bow: GhostItemInstance = GhostItemGenerator.create(load("res://items/thornrose_bow.tres") as GhostItemData, 192402, "rare")
	inv.contents.append(twin)
	inv.contents.append(bow)
	inv.grid_positions.append(Vector2i.ZERO)
	inv.grid_positions.append(Vector2i(4, 0))
	inv.equipment["sword"] = 0
	var twin_before: Dictionary = twin.cosmetic_snapshot()
	var bow_before: Dictionary = bow.cosmetic_snapshot()
	var stats: Dictionary = twin.all_stats()
	var slots_before: Array = inv.contents.duplicate()
	var panel: Control = EQUIP.instantiate()
	root.add_child(panel)
	panel.call("bind_inventory", inv)
	panel.show()
	await process_frame
	var preview: SubViewportContainer = panel.get_node("Layout/EquipmentSlots/LiveEquipmentPreview")
	var actor: CharacterBody2D = preview.get("actor")
	if actor == null or not actor.is_inside_tree() or actor.is_in_group("ghost_girl_player") or actor.collision_layer != 0 or actor.collision_mask != 0 or actor.is_physics_processing() or actor.is_processing_unhandled_input():
		_fail("Preview is not isolated from gameplay")
		return
	var body: AnimatedSprite2D = actor.get_node("Ghost")
	var vp: SubViewport = preview.get("viewport")
	if vp.world_2d == root.world_2d or actor.get_node("Camera2D").enabled or not str(body.animation).contains("twinblade"):
		_fail("Preview did not use independent world and actual held weapon animation")
		return
	var facing: OptionButton = panel.get_node("Layout/PreviewControls/Facing")
	facing.item_selected.emit(3)
	if not str(body.animation).ends_with("_left"):
		_fail("Directional preview did not switch sprite")
		return
	var fx: HSlider = panel.get_node("Layout/PreviewControls/FXIntensity")
	fx.value = 0.5
	await process_frame
	if not is_equal_approx(FX.intensity, 0.5) or not is_equal_approx(actor.get_node("Ghost/EquippedPrestigeFX").self_modulate.a, GENTLE.EFFECT_ALPHA * 0.5):
		_fail("Slider did not change actual held effect opacity")
		return
	var inventory_panel: Control = PANEL.instantiate()
	root.add_child(inventory_panel)
	inventory_panel.call("bind_inventory", inv)
	inventory_panel.show()
	inventory_panel.call("_on_slot_pressed", 0)
	var dropdown: OptionButton = inventory_panel.get_node("Layout/DetailsHeader/TestMythic")
	if OS.is_debug_build():
		if dropdown.is_item_disabled(dropdown.get_item_index(70)):
			_fail("Twinblade guard was incorrectly disabled")
			return
		dropdown.item_selected.emit(dropdown.get_item_index(36))
		var preset: Dictionary = actor.get_node("Ghost/EquippedPrestigeFX").get("collector_look")
		if int(preset.get("material", -1)) != 6:
			_fail("Live character did not receive actual preview selection")
			return
		dropdown.item_selected.emit(dropdown.get_item_index(1))
	inv.equipment["sword"] = 1
	inv.equipment_changed.emit()
	await process_frame
	if not str(body.animation).begins_with("thornrose_"):
		_fail("Equipped bow did not update animated character")
		return
	inventory_panel.call("_on_slot_pressed", 1)
	if OS.is_debug_build():
		if not dropdown.is_item_disabled(dropdown.get_item_index(70)) or dropdown.is_item_disabled(dropdown.get_item_index(62)):
			_fail("Bow compatibility rules incorrect")
			return
	fx.value = 1.5
	await process_frame
	await process_frame
	var material: ShaderMaterial = actor.get_node("Ghost/BowPaletteV139").material as ShaderMaterial
	if not is_equal_approx(float(material.get_shader_parameter("fx_intensity")), 1.5):
		_fail("Bow material intensity not updated")
		return
	if twin.cosmetic_snapshot() != twin_before or bow.cosmetic_snapshot() != bow_before or twin.all_stats() != stats or inv.contents != slots_before or inv.equipment["sword"] != 1:
		_fail("Read-only preview changed item ownership or identity")
		return
	panel.hide()
	if actor.process_mode != Node.PROCESS_MODE_DISABLED or vp.render_target_update_mode != SubViewport.UPDATE_DISABLED:
		_fail("Hidden preview still rendering")
		return
	FX.set_intensity(1.0)
	inventory_panel.free()
	panel.free()
	inv.free()
	print("v1.92.4 PASS: isolated live rig, directions, equipped debug effect, slider, bow compatibility, hidden preview, item invariants")
	quit(0)

func _fail(message: String) -> void:
	FX.set_intensity(1.0)
	push_error(message)
	quit(1)
