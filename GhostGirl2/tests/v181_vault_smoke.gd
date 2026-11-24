extends SceneTree
const INV = preload("res://scripts/inventory.gd")
func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var inv: Node = INV.new()
	var template: GhostItemData = load("res://items/rosemirror_twinblade_v170.tres") as GhostItemData
	var item: GhostItemInstance = GhostItemGenerator.create(template, 181001, "rare")
	item.collector_favorite = true
	item.collector_locked = true
	var snapshot: Dictionary = item.cosmetic_snapshot()
	var damage: float = item.weapon_damage()
	var stats: Dictionary = item.all_stats()
	inv.contents.append(item)
	inv.grid_positions.append(Vector2i.ZERO)
	if inv.can_drop(0) or inv.can_destroy(0):
		_fail("Protected item may be lost")
		return
	inv.equipment["sword"] = 0
	if inv.vault_store(0, false):
		_fail("Equipped weapon stored without unequipping")
		return
	inv.equipment["sword"] = -1
	if not inv.vault_store(0, false) or inv.vault[0] != item or not inv.contents.is_empty():
		_fail("Deposit did not move exact item")
		return
	var stored: Dictionary = inv._serialize_item(item, Vector2i(-1, -1))
	var restored: GhostItemInstance = inv._deserialize_item(JSON.parse_string(JSON.stringify(stored)))
	if restored == null or restored.cosmetic_snapshot() != snapshot or restored.weapon_damage() != damage or restored.all_stats() != stats or not restored.collector_favorite or not restored.collector_locked:
		if restored != null:
			for key in snapshot:
				if snapshot[key] != restored.cosmetic_snapshot().get(key):
					print("Roundtrip mismatch: ", key, ": ", snapshot[key], " -> ", restored.cosmetic_snapshot().get(key))
		_fail("Save round trip lost appearance, stats or protection")
		return
	inv.capacity = 0
	if inv.vault_withdraw(0, false) or inv.vault[0] != item:
		_fail("Full backpack lost stored item")
		return
	inv.capacity = 72
	if not inv.vault_withdraw(0, false) or inv.contents[0] != item or not inv.vault.is_empty():
		_fail("Withdrawal did not preserve exact instance")
		return
	var hud: CanvasLayer = (load("res://scenes/hud.tscn") as PackedScene).instantiate()
	root.add_child(hud)
	hud.call("bind_inventory", inv)
	var panel: Control = hud.get_node("Overlay/InventoryPanel")
	panel.show()
	panel.call("_on_slot_pressed", 0)
	var button: Button = panel.get_node("Layout/Header/VaultButton")
	button.pressed.emit()
	var modal: Control = hud.get_node("Overlay/CollectionVaultV181")
	if not modal.visible or modal.get("selected_item") != item:
		_fail("Vault button did not open selected weapon")
		return
	hud.free()
	inv.free()
	print("v1.81 PASS: protected weapon, exact transfer, saved roll roundtrip, full backpack, actual vault button")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
