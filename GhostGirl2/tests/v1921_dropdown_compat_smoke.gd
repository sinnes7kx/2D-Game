extends SceneTree
const INV = preload("res://scripts/inventory.gd")
const PANEL = preload("res://scenes/inventory_panel.tscn")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var inventory: Node = INV.new()
	var template: GhostItemData = load("res://items/rosemirror_twinblade_v170.tres") as GhostItemData
	var item: GhostItemInstance = GhostItemGenerator.create(template, 192101, "rare")
	inventory.contents.append(item)
	inventory.grid_positions.append(Vector2i.ZERO)
	for mode in ["current", "legacy", "missing"]:
		var panel: Control = PANEL.instantiate()
		var header: Control = panel.get_node("Layout/DetailsHeader")
		var original: Node = header.get_node("TestMythic")
		var original_index: int = original.get_index()
		if mode != "current":
			header.remove_child(original)
			original.free()
			original = null
			if mode == "legacy":
				var legacy: Button = Button.new()
				legacy.name = "TestMythic"
				legacy.text = "MYTHIC"
				header.add_child(legacy)
				header.move_child(legacy, original_index)
		root.add_child(panel)
		var dropdown: OptionButton = header.get_node_or_null("TestMythic") as OptionButton
		if dropdown == null or panel.get("test_mythic") != dropdown:
			_fail("No compatible dropdown for " + mode)
			return
		if mode == "current" and dropdown != original:
			_fail("Existing compatible control was replaced")
			return
		if mode == "legacy" and dropdown.get_index() != original_index:
			_fail("Legacy layout order changed")
			return
		if dropdown.visible:
			_fail("Tester visible before selection")
			return
		panel.call("bind_inventory", inventory)
		panel.show()
		panel.call("_on_slot_pressed", 0)
		if OS.is_debug_build():
			var index: int = dropdown.get_item_index(36)
			if index < 0 or not dropdown.visible:
				_fail("Anomaly option missing for " + mode)
				return
			dropdown.item_selected.emit(index)
			if item.debug_collector_tier != 6:
				_fail("Effect selection disconnected")
				return
			dropdown.item_selected.emit(dropdown.get_item_index(1))
			if item.debug_collector_tier != -1:
				_fail("Reset disconnected")
				return
		panel.free()
	inventory.free()
	print("v1.92.1 PASS: current, legacy Button and missing dropdown scenes; Anomaly and reset signals")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
