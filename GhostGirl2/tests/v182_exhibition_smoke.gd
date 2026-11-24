extends SceneTree
const INV = preload("res://scripts/inventory.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var inv: Node = INV.new()
	var template: GhostItemData = load("res://items/rosemirror_twinblade_v170.tres") as GhostItemData
	var first: GhostItemInstance = GhostItemGenerator.create(template, 182001, "rare")
	var second: GhostItemInstance = GhostItemGenerator.create(template, 182002, "rare")
	# Identical appearance IDs must not make two actual items interchangeable.
	first.cosmetic_uid = "0123456789abcdef0123456789abcdef"
	second.cosmetic_uid = first.cosmetic_uid
	first.collector_locked = true
	inv.vault.append(first)
	inv.vault.append(second)
	if not inv.set_exhibition(first, 0, false) or not inv.set_exhibition(second, 1, false):
		_fail("Display assignment failed")
		return
	if inv.exhibition_item(0) != first or inv.exhibition_item(1) != second:
		_fail("Display identity mismatch")
		return
	if not inv.set_exhibition(second, 0, false) or first.exhibition_slot != -1 or inv.exhibition_item(1) != null:
		_fail("Replacing or moving a display left a duplicate")
		return
	var stored: Dictionary = inv._serialize_item(second, Vector2i(-1,-1))
	var restored: GhostItemInstance = inv._deserialize_item(JSON.parse_string(JSON.stringify(stored)))
	if restored == null or restored.exhibition_slot != 0 or restored.cosmetic_snapshot() != second.cosmetic_snapshot():
		_fail("Exhibition save roundtrip changed item")
		return
	var room: Node2D = (load("res://scenes/rooms/sanctum.tscn") as PackedScene).instantiate()
	root.add_child(room)
	var displays: Node = room.get_node("Gameplay/CollectionExhibition")
	if displays.get_child_count() != 6:
		_fail("Six physical displays are required")
		return
	for display in displays.get_children():
		display.call("bind_inventory", inv)
	var stand: Node = displays.get_child(0)
	if stand.call("get_displayed_item") != second or not stand.is_in_group("v182_exhibition"):
		_fail("Physical stand not bound to exact vault item")
		return
	var model: Node2D = stand.get("model")
	var view: GhostItemInstance = model.get("item")
	if view == null or view.cosmetic_snapshot() != second.cosmetic_snapshot():
		_fail("Display view not using actual appearance")
		return
	if not inv.vault_withdraw(1, false) or inv.exhibition_item(0) != null or model.get("item") != null or second.exhibition_slot != -1:
		_fail("Withdrawal left phantom weapon in exhibition")
		return
	await process_frame
	room.free()
	inv.free()
	print("v1.82 PASS: six displays, unique item ownership, saved slots, actual model, withdrawal cleanup")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
