extends SceneTree
const INVENTORY = preload("res://scripts/inventory.gd")
const ART = preload("res://scripts/modular_weapon_art_v178.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var hud: CanvasLayer = (load("res://scenes/hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	# Inventory stays outside tree: do not load or write any real save.
	var inv: Node = INVENTORY.new()
	var item: GhostItemInstance = GhostItemInstance.new()
	item.definition = load("res://items/rosemirror_twinblade_v170.tres") as GhostItemData
	item.cosmetic_uid = "0123456789abcdef0123456789abcdef"
	inv.contents.append(item)
	inv.grid_positions.append(Vector2i.ZERO)
	hud.call("bind_inventory", inv)
	var panel: Control = hud.get_node("Overlay/InventoryPanel")
	panel.show()
	panel.call("_on_slot_pressed", 0)
	var button: Button = panel.get_node("Layout/Actions/InspectSelected")
	if not button.visible:
		push_error("Inspect button not visible for selected twinblade")
		quit(1)
		return
	button.pressed.emit()
	var lens: Control = hud.get_node("Overlay/CollectorLensV179")
	if not lens.visible or lens.get("inspected") != item:
		push_error("Actual inventory button did not open selected weapon")
		quit(1)
		return
	lens.call("close_lens")
	var entries: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://resources/ghost_extra_animations.json"))
	var count: int = 0
	for entry in entries:
		if not str(entry["name"]).contains("twinblade"):
			continue
		count += 1
		if entry.has("atlas") or entry["textures"].size() != 8:
			push_error("Old baked twinblade art still referenced")
			quit(1)
			return
		for path in entry["textures"]:
			if not str(path).contains("combat_v14/attack_unarmed_light_"):
				push_error("Twinblade animation contains wrong body art")
				quit(1)
				return
	var spans: Array[PackedVector2Array] = ART.twinblade_spans(Vector2.ZERO, Vector2(0,-68))
	if count != 32 or spans.size() != 2 or spans[0][0].distance_to(spans[0][1]) < 55.0:
		push_error("Double sword geometry or manifest incomplete")
		quit(1)
		return
	if not item.definition.icon.resource_path.ends_with("_v1801.svg"):
		push_error("Stale stone-headed icon")
		quit(1)
		return
	hud.free()
	inv.free()
	print("v1.80.1 PASS: actual inventory inspect button, 32 clean clips and new double sword icon")
	quit(0)
