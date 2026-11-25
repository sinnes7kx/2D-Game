extends RefCounted
## Pure, presentation-only vault filter/sort helpers.
## Never changes item order in inventory.contents/inventory.vault.
const QUALITY_ORDER := {"normal": 0, "magic": 1, "rare": 2, "set": 3, "unique": 4}
const FAMILIES: Array[String] = ["all", "sword", "wand", "dress", "wings", "helm", "trinket", "charm"]
const QUALITIES: Array[String] = ["all", "normal", "magic", "rare", "set", "unique"]

static func filtered(items: Array, family: String = "all", quality: String = "all", order: int = 0, favorites_only: bool = false, query: String = "") -> Array[GhostItemInstance]:
	var result: Array[Dictionary] = []
	var wanted: String = query.strip_edges().to_lower()
	for i in range(items.size()):
		var item: GhostItemInstance = items[i] as GhostItemInstance
		if item == null or item.definition == null or not FAMILIES.has(item.get_slot()):
			continue
		if family != "all" and item.get_slot() != family:
			continue
		if quality != "all" and item.quality != quality:
			continue
		if favorites_only and not item.collector_favorite:
			continue
		var text: String = " ".join([item.display_name(), item.collector_material_label(), item.regional_imprint_label(), item.origin_label(), item.get_slot(), item.quality])
		if not wanted.is_empty() and not text.to_lower().contains(wanted):
			continue
		result.append({"item": item, "index": i})
	if order != 0:
		result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			var x: GhostItemInstance = a["item"]
			var y: GhostItemInstance = b["item"]
			match order:
				1: # Intrinsic item quality, not invented rarity odds.
					var rank_x: int = int(QUALITY_ORDER.get(x.quality, -1))
					var rank_y: int = int(QUALITY_ORDER.get(y.quality, -1))
					if rank_x != rank_y:
						return rank_x > rank_y
				2: # Item names, case insensitive.
					var label_x: String = x.display_name().to_lower()
					var label_y: String = y.display_name().to_lower()
					if label_x != label_y:
						return label_x < label_y
				3: # Equipment family.
					var family_x: String = x.get_slot()
					var family_y: String = y.get_slot()
					if family_x != family_y:
						return family_x < family_y
			return int(a["index"]) < int(b["index"])
		)
	var filtered_items: Array[GhostItemInstance] = []
	for entry in result:
		filtered_items.append(entry["item"])
	return filtered_items
