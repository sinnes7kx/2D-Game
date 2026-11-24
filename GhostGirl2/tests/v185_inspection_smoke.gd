extends SceneTree
const INV = preload("res://scripts/inventory.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var hud: CanvasLayer = (load("res://scenes/hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	var inv: Node = INV.new()
	hud.call("bind_inventory", inv)
	var lens: Control = hud.get_node("Overlay/CollectorLensV179")
	var panel: Control = hud.get_node("Overlay/InventoryPanel")
	var count: int = 0
	var nonweapon: GhostItemInstance = null
	for filename in DirAccess.get_files_at("res://items"):
		if not filename.ends_with(".tres"):
			continue
		var template: GhostItemData = load("res://items/" + filename) as GhostItemData
		if template == null:
			continue
		var item: GhostItemInstance = GhostItemGenerator.create(template, 185001, "normal")
		var before: Dictionary = item.cosmetic_snapshot()
		lens.call("open_item", item)
		var model: Node2D = lens.get("model")
		if not lens.visible or model.get("item") != item or lens.get("glow_button").disabled or lens.get("motion_button").disabled:
			_fail("Inspection failed for " + filename)
			return
		await process_frame
		lens.call("close_lens")
		if item.cosmetic_snapshot() != before:
			_fail("Inspection mutated " + filename)
			return
		if item.get_slot() == "none":
			nonweapon = item
		count += 1
	if count < 10 or nonweapon == null:
		_fail("Not enough templates checked")
		return
	inv.contents.append(nonweapon)
	inv.grid_positions.append(Vector2i.ZERO)
	panel.show()
	panel.call("_on_slot_pressed", 0)
	var dropdown: OptionButton = panel.get_node("Layout/DetailsHeader/TestMythic")
	var button: Button = panel.get_node("Layout/Actions/InspectSelected")
	if not dropdown.visible or not button.visible:
		_fail("Nonweapon inspection or dropdown missing")
		return
	var snapshot: Dictionary = nonweapon.cosmetic_snapshot()
	var index: int = dropdown.get_item_index(23)
	if index < 0:
		_fail("Specific Mythic variant missing")
		return
	dropdown.item_selected.emit(index)
	if nonweapon.visual_signature() != 4 or nonweapon.mythic_layer_variant() != 3 or nonweapon.cosmetic_snapshot() != snapshot:
		_fail("Debug choice changed persistent item or did not select effect")
		return
	button.pressed.emit()
	if not lens.visible or lens.get("inspected") != nonweapon:
		_fail("Actual inventory button failed for nonweapon")
		return
	lens.call("close_lens")
	dropdown.item_selected.emit(dropdown.get_item_index(1))
	if nonweapon.debug_visual_override != -1 or nonweapon.debug_mythic_variant != -1:
		_fail("Clear preview failed")
		return
	var weapon: GhostItemData = load("res://items/rosemirror_twinblade_v170.tres") as GhostItemData
	var found: GhostItemInstance = inv.generate_find(weapon, 185002, "normal", "moonwake_crypt")
	var genuine: String = found.discovery_label()
	found.debug_visual_override = 5
	found.debug_collector_tier = 6
	if found.discovery_label() != genuine:
		_fail("Debug override affected genuine discovery")
		return
	hud.free()
	inv.free()
	print("v1.85 PASS: inspected ", count, " item templates; direct effect menu and genuine discovery isolation")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
