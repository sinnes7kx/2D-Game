extends SceneTree
## v2.08 presentation filters must never mutate stored order or item identity.
const INV = preload("res://scripts/inventory.gd")
const VAULT = preload("res://scripts/collection_vault_v181.gd")
const FILTERS = preload("res://scripts/v208_vault_filters.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var inv: Node = INV.new()
	var definitions: Array[String] = ["res://items/v202_luminous_eyes.tres", "res://items/v202_moonlit_tiara.tres", "res://items/rosemirror_twinblade_v170.tres", "res://items/thornrose_bow.tres"]
	for i in range(definitions.size()):
		var data: GhostItemData = load(definitions[i]) as GhostItemData
		if data == null:
			_fail("Fixture definition missing")
			return
		var quality: String = "rare" if i < 2 else "magic"
		var item: GhostItemInstance = GhostItemGenerator.create(data, 208010 + i, quality)
		item.collector_favorite = i == 0
		inv.vault.append(item)
	var owned: Array[GhostItemInstance] = inv.vault.duplicate()
	var before: Dictionary = inv._build_save_data()
	var eyes: Array[GhostItemInstance] = FILTERS.filtered(inv.vault, "wings")
	if eyes.size() != 1 or eyes[0] != owned[0]:
		_fail("Eyes missing from head accessory family")
		return
	var rares: Array[GhostItemInstance] = FILTERS.filtered(inv.vault, "all", "rare")
	if rares.size() != 2 or rares[0] != owned[0] or rares[1] != owned[1]:
		_fail("Rarity filter reorders or drops matching items")
		return
	var favorites: Array[GhostItemInstance] = FILTERS.filtered(inv.vault, "all", "all", 0, true)
	if favorites.size() != 1 or favorites[0] != owned[0]:
		_fail("Favorites filter did not use the saved collector flag")
		return
	var names: Array[GhostItemInstance] = FILTERS.filtered(inv.vault, "all", "all", 2)
	if names.size() != 4 or names[0].display_name().to_lower() > names[1].display_name().to_lower():
		_fail("Name sorting is incorrect")
		return
	var sorted: Array[GhostItemInstance] = FILTERS.filtered(inv.vault, "all", "all", 1)
	if sorted.size() != 4 or sorted[0] != owned[0] or sorted[1] != owned[1]:
		_fail("Rarity sorting must keep equal-quality items stable")
		return
	if FILTERS.filtered(inv.vault, "wings", "unique").size() != 0:
		_fail("Combined filters returned nonmatching items")
		return
	var ui: Control = VAULT.new()
	root.add_child(ui)
	ui.open_vault(inv, null)
	var family: OptionButton = ui.get("family_filter") as OptionButton
	var quality: OptionButton = ui.get("quality_filter") as OptionButton
	var order: OptionButton = ui.get("order_filter") as OptionButton
	if family == null or quality == null or order == null:
		_fail("Vault UI filter controls are missing")
		return
	ui.set("selected_item", owned[0])
	family.select(5) # Helm only, hides selected eyes
	ui.refresh()
	if ui.get("shown").size() != 1 or ui.get("selected_item") != null:
		_fail("Hidden selection remained actionable")
		return
	family.select(0)
	quality.select(3)
	order.select(1)
	ui.refresh()
	if ui.get("shown").size() != 2:
		_fail("Actual UI failed combined family/quality controls")
		return
	if inv.vault != owned or inv._build_save_data() != before:
		_fail("Sorting or filtering mutated owned items or save records")
		return
	ui.free()
	inv.free()
	print("v2.08 PASS: stable family/quality/favorite/search sorting and immutable vault collection")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
