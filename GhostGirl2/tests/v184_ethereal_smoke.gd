extends SceneTree
const INV = preload("res://scripts/inventory.gd")
const MODEL = preload("res://scripts/collector_lens_model_v179.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var inv: Node = INV.new()
	var base: GhostItemData = load("res://items/rosemirror_twinblade_v170.tres") as GhostItemData
	var item: GhostItemInstance = GhostItemGenerator.create(base, 184001)
	item.cosmetic_uid = "0123456789abcdef0123456789abcdef"
	var damage: float = item.weapon_damage()
	var original: Dictionary = item.cosmetic_snapshot()
	item.make_ethereal()
	if not item.ethereal or item.weapon_opacity() >= 1.0 or item.durability < 80 or item.durability > 140 or absf(item.weapon_damage() - damage * 1.5) > 0.15:
		_fail("Ethereal power, opacity or initial durability invalid")
		return
	var stats: Dictionary = item.all_stats()
	item.durability = 2
	inv.contents.append(item)
	inv.grid_positions.append(Vector2i.ZERO)
	inv.equipment["sword"] = 0
	if inv.wear_ethereal(item, false) or item.durability != 1 or inv.get_equipped("sword") != item:
		_fail("First use incorrectly broke weapon")
		return
	var record: Dictionary = inv._serialize_item(item, Vector2i.ZERO)
	var restored: GhostItemInstance = inv._deserialize_item(JSON.parse_string(JSON.stringify(record)))
	if restored == null or not restored.ethereal or restored.durability != 1 or restored.max_durability != item.max_durability or restored.cosmetic_snapshot() != original or restored.all_stats() != stats:
		_fail("Save roundtrip lost actual rolls or durability")
		return
	if not inv.wear_ethereal(item, false) or not item.is_broken() or inv.get_equipped("sword") != null or not item.all_stats().is_empty() or inv.equip_at(0):
		_fail("Broken item remained usable")
		return
	item.make_ethereal()
	if item.durability != 0 or not inv.vault_store(0, false) or inv.vault[0] != item:
		_fail("Broken item repaired or disappeared")
		return
	var model: Node2D = MODEL.new()
	root.add_child(model)
	model.call("set_item", item)
	if not is_equal_approx(model.self_modulate.a, 0.28):
		_fail("Broken relic preview is not translucent")
		return
	var broken: GhostItemInstance = inv._deserialize_item(inv._serialize_item(item, Vector2i.ZERO))
	if broken == null or not broken.is_broken():
		_fail("Broken condition not persisted")
		return
	var normal: GhostItemInstance = GhostItemGenerator.create(base, 184001)
	if normal.ethereal or normal.is_broken() or normal.weapon_opacity() != 1.0:
		_fail("Old/normal item changed")
		return
	model.free()
	inv.free()
	print("v1.84 PASS: Ethereal power, translucency, finite uses, save roundtrip, auto unequip and collectible broken relic")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
