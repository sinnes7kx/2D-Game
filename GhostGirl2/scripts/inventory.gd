extends Node
## Diablo-II-inspired spatial backpack, plus separate equipment and socket crafting.
## Existing v1/v2 saves remain readable. Slots remain indexed in `contents`
## so combat, quests, equipment indices, and seeded rolls retain compatibility.
signal contents_changed
signal equipment_changed

const SAVE_FILE: String = "user://ghost_girl_treasures_v2.json"
const LEGACY_SAVE_FILE: String = "user://ghost_girl_treasures_v1.json"
const GRID_COLUMNS: int = 10
const GRID_ROWS: int = 6
const GRID_PAGES: int = 8
@export_range(6, 160, 1) var capacity: int = 72
const SPECIAL_JEWEL_MALADY: GhostItemData = preload("res://items/malady_jewel.tres")
const SPECIAL_JEWEL_DELIRIUM: GhostItemData = preload("res://items/delirium_jewel.tres")
const SPECIAL_JEWEL_EXILE: GhostItemData = preload("res://items/exile_jewel.tres")
const SPECIAL_JEWELS: Array[GhostItemData] = [SPECIAL_JEWEL_MALADY, SPECIAL_JEWEL_DELIRIUM, SPECIAL_JEWEL_EXILE]
var contents: Array[GhostItemInstance] = []
var grid_positions: Array[Vector2i] = []  # y = page * GRID_ROWS + local row
var equipment: Dictionary = {"dress": -1, "wings": -1, "trinket": -1, "charm": -1, "wand": -1, "sword": -1}
var collected_pickups: Dictionary = {}

func _ready() -> void:
	load_game()

func get_item_size(item: GhostItemInstance) -> Vector2i:
	if item == null or item.definition == null:
		return Vector2i.ONE
	var definition: GhostItemData = item.definition
	if definition.inventory_width > 0 and definition.inventory_height > 0:
		return Vector2i(definition.inventory_width, definition.inventory_height)
	if definition.item_class != "equipment":
		return Vector2i.ONE
	match definition.equip_slot:
		"dress": return Vector2i(2, 3)
		"wings": return Vector2i(2, 2)
		"wand": return Vector2i(1, 3)
		"sword": return Vector2i(2, 3)
		"trinket", "charm": return Vector2i.ONE
		_: return Vector2i(2, 2)

func get_position(index: int) -> Vector2i:
	return grid_positions[index] if index >= 0 and index < grid_positions.size() else Vector2i(-1, -1)

func get_grid_index(page: int, x: int, y: int) -> int:
	if page < 0 or page >= GRID_PAGES or x < 0 or x >= GRID_COLUMNS or y < 0 or y >= GRID_ROWS:
		return -1
	var absolute_y: int = page * GRID_ROWS + y
	for i in range(contents.size()):
		var pos: Vector2i = get_position(i)
		var size: Vector2i = get_item_size(contents[i])
		if pos.x <= x and x < pos.x + size.x and pos.y <= absolute_y and absolute_y < pos.y + size.y:
			return i
	return -1

func _fits(item: GhostItemInstance, place: Vector2i, ignore_index: int = -1) -> bool:
	var size: Vector2i = get_item_size(item)
	var page: int = int(floor(float(place.y) / float(GRID_ROWS)))
	if page < 0 or page >= GRID_PAGES or place.x < 0 or place.x + size.x > GRID_COLUMNS:
		return false
	if place.y < page * GRID_ROWS or place.y + size.y > (page + 1) * GRID_ROWS:
		return false
	for i in range(contents.size()):
		if i == ignore_index:
			continue
		var other: Vector2i = get_position(i)
		var other_size: Vector2i = get_item_size(contents[i])
		if place.x < other.x + other_size.x and place.x + size.x > other.x and place.y < other.y + other_size.y and place.y + size.y > other.y:
			return false
	return true

func _first_open(item: GhostItemInstance) -> Vector2i:
	for page in range(GRID_PAGES):
		for row in range(GRID_ROWS):
			for col in range(GRID_COLUMNS):
				var pos: Vector2i = Vector2i(col, page * GRID_ROWS + row)
				if _fits(item, pos):
					return pos
	return Vector2i(-1, -1)

func add_pickup(template: GhostItemData, pickup_id: String, item_seed: int) -> GhostItemInstance:
	if pickup_id.is_empty() or collected_pickups.has(pickup_id):
		return null
	var item: GhostItemInstance = add_loot(template, item_seed)
	if item != null:
		collected_pickups[pickup_id] = true
		save_game()
	return item

func _resolve_socketable_loot_template(template: GhostItemData, seed_value: int) -> GhostItemData:
	if template == null or template.unique or template.item_class not in ["gem", "rune"]:
		return template
	# About 1 in 29 socketable drops becomes a named unique jewel. The seed
	# deterministically selects which jewel so two identical world drops remain
	# reproducible, while duplicates gracefully fall back to the normal loot.
	if posmod(seed_value, 29) != 0:
		return template
	var start: int = posmod(int(seed_value / 29), SPECIAL_JEWELS.size())
	for step in range(SPECIAL_JEWELS.size()):
		var jewel: GhostItemData = SPECIAL_JEWELS[posmod(start + step, SPECIAL_JEWELS.size())]
		if jewel != null and not has_item(jewel.item_id):
			return jewel
	return template

func add_loot(template: GhostItemData, seed_value: int, forced_quality: String = "") -> GhostItemInstance:
	if template == null or contents.size() >= capacity:
		return null
	template = _resolve_socketable_loot_template(template, seed_value)
	if template.unique and has_item(template.item_id):
		return null
	var item: GhostItemInstance = GhostItemGenerator.create(template, seed_value, forced_quality)
	# New drops roll an independent, 128-bit cosmetic identity once, on pickup.
	# Do not change the item_seed that determines damage, affixes and sockets.
	if template.equip_slot != "none" and template.item_class == "equipment":
		item.apply_cosmetic_uid(GhostCosmeticRNGV152.fresh_uid())
	var pos: Vector2i = _first_open(item)
	if pos.x < 0:
		return null
	contents.append(item)
	grid_positions.append(pos)
	contents_changed.emit()
	save_game()
	return item

func has_collected(pickup_id: String) -> bool:
	return collected_pickups.has(pickup_id)

func has_item(item_id: String) -> bool:
	for item in contents:
		if item.definition != null and item.definition.item_id == item_id:
			return true
	return false

func get_item(index: int) -> GhostItemInstance:
	return contents[index] if index >= 0 and index < contents.size() else null

func equipped_index(slot: String) -> int:
	return int(equipment.get(slot, -1))

func get_equipped(slot: String) -> GhostItemInstance:
	return get_item(equipped_index(slot))

func equip_at(index: int) -> bool:
	var item: GhostItemInstance = get_item(index)
	if item == null or item.get_slot() == "none" or not equipment.has(item.get_slot()):
		return false
	# A sword and wand share the active hand; equipping either holsters the other.
	if item.get_slot() == "sword":
		equipment["wand"] = -1
	elif item.get_slot() == "wand":
		equipment["sword"] = -1
	equipment[item.get_slot()] = index
	equipment_changed.emit()
	contents_changed.emit()
	save_game()
	return true

func unequip(slot: String) -> void:
	if equipment.has(slot) and equipped_index(slot) >= 0:
		equipment[slot] = -1
		equipment_changed.emit()
		contents_changed.emit()
		save_game()

func move_item_at(index: int, page: int, col: int, row: int) -> bool:
	var item: GhostItemInstance = get_item(index)
	if item == null or page < 0 or page >= GRID_PAGES:
		return false
	var pos: Vector2i = Vector2i(col, page * GRID_ROWS + row)
	if not _fits(item, pos, index):
		return false
	grid_positions[index] = pos
	contents_changed.emit()
	save_game()
	return true

# Compact items into the earliest fitting cells without changing their indices.
# Item indices are referenced by equipment slots, sockets, and older saves;
# sorting positions ONLY prevents accidentally changing equipped items.
func sort_backpack() -> bool:
	var ordered: Array[int] = []
	for i in range(contents.size()):
		ordered.append(i)
	# Large items first, stable item-index tie breaker: deterministic layout.
	ordered.sort_custom(func(a: int, b: int) -> bool:
		var size_a: Vector2i = get_item_size(contents[a])
		var size_b: Vector2i = get_item_size(contents[b])
		var area_a: int = size_a.x * size_a.y
		var area_b: int = size_b.x * size_b.y
		return area_a > area_b if area_a != area_b else a < b
	)
	var placed: Dictionary = {}
	for idx in ordered:
		var item_size: Vector2i = get_item_size(contents[idx])
		var found: bool = false
		for p in range(GRID_PAGES):
			if found:
				break
			for y in range(GRID_ROWS - item_size.y + 1):
				if found:
					break
				for x in range(GRID_COLUMNS - item_size.x + 1):
					var candidate: Vector2i = Vector2i(x, p * GRID_ROWS + y)
					if _sort_position_clear(candidate, item_size, placed):
						placed[idx] = candidate
						found = true
						break
		if not found:
			return false  # Leave the original layout unchanged if it cannot fit.
	for i in range(contents.size()):
		grid_positions[i] = placed[i]
	contents_changed.emit()
	save_game()
	return true

func _sort_position_clear(pos: Vector2i, size: Vector2i, placed: Dictionary) -> bool:
	for other_index in placed.keys():
		var other_pos: Vector2i = placed[other_index]
		var other_size: Vector2i = get_item_size(contents[int(other_index)])
		if pos.x < other_pos.x + other_size.x and pos.x + size.x > other_pos.x and pos.y < other_pos.y + other_size.y and pos.y + size.y > other_pos.y:
			return false
	return true

# Exact item transfer for click-to-ground. Preserve rolled affixes and sockets.
func can_drop(index: int) -> bool:
	var item: GhostItemInstance = get_item(index)
	return item != null and item.definition != null and item.definition.item_class != "quest"

func take_item_at(index: int) -> GhostItemInstance:
	if not can_drop(index):
		return null
	var item: GhostItemInstance = get_item(index)
	_remove_item_at(index)
	contents_changed.emit()
	equipment_changed.emit()
	save_game()
	return item

func add_existing_item(item: GhostItemInstance) -> GhostItemInstance:
	if item == null or item.definition == null or contents.size() >= capacity:
		return null
	var pos: Vector2i = _first_open(item)
	if pos.x < 0:
		return null
	contents.append(item)
	grid_positions.append(pos)
	contents_changed.emit()
	equipment_changed.emit()
	save_game()
	return item

func can_destroy(index: int) -> bool:
	var item: GhostItemInstance = get_item(index)
	if item == null or item.definition == null or item.definition.item_class == "quest":
		return false
	for slot in equipment.keys():
		if equipped_index(str(slot)) == index:
			return false
	return true

func destroy_item_at(index: int) -> bool:
	if not can_destroy(index):
		return false
	_remove_item_at(index)
	contents_changed.emit()
	equipment_changed.emit()
	save_game()
	return true

func socket_at(gear_index: int, component_index: int) -> bool:
	var gear: GhostItemInstance = get_item(gear_index)
	var component: GhostItemInstance = get_item(component_index)
	if gear == null or component == null or gear_index == component_index:
		return false
	if gear.get_slot() == "none" or gear.sockets <= gear.socketed.size():
		return false
	if component.definition == null or component.definition.item_class not in ["gem", "rune"]:
		return false
	gear.socketed.append({
		"id": component.definition.item_id, "name": component.definition.display_name,
		"stat": component.definition.socket_bonus_id, "value": component.definition.socket_bonus_value
	})
	_remove_item_at(component_index)
	contents_changed.emit()
	equipment_changed.emit()
	save_game()
	return true

func _remove_item_at(index: int) -> void:
	contents.remove_at(index)
	grid_positions.remove_at(index)
	for slot in equipment.keys():
		var old: int = equipped_index(str(slot))
		equipment[slot] = -1 if old == index else (old - 1 if old > index else old)

func get_stat_total(stat: String) -> float:
	var total: float = 0.0
	for slot in equipment.keys():
		var item: GhostItemInstance = get_equipped(str(slot))
		if item != null:
			total += float(item.all_stats().get(stat, 0.0))
	return total

func save_game() -> void:
	var saved_items: Array[Dictionary] = []
	for i in range(contents.size()):
		var item: GhostItemInstance = contents[i]
		if item.definition == null or item.definition.resource_path.is_empty():
			continue
		var pos: Vector2i = get_position(i)
		saved_items.append({
			"resource": item.definition.resource_path, "seed": item.item_seed,
			"quality": item.quality, "socketed": item.socketed.duplicate(true),
			"grid_x": pos.x, "grid_y": pos.y,
			"palette_index": item.palette_index,
			"decoration_index": item.decoration_index,
			"weapon_base_index": item.weapon_base_index,
			"weapon_gradient_index": item.weapon_gradient_index,
			"weapon_detail_a_index": item.weapon_detail_a_index,
			"weapon_detail_b_index": item.weapon_detail_b_index,
			"weapon_fx_style_index": item.weapon_fx_style_index,
			"weapon_fx_color_index": item.weapon_fx_color_index,
			"weapon_fx_accent_index": item.weapon_fx_accent_index,
			"weapon_fx_trail_index": item.weapon_fx_trail_index,
			"wand_cast_style_index": item.wand_cast_style_index,
			"weapon_impact_style_index": item.weapon_impact_style_index,
			"wand_lance_index": item.wand_lance_index,
			"bow_element_index": item.bow_element_index,
			"bow_formation_index": item.bow_formation_index,
			"bow_glow_index": item.bow_glow_index,
			"bow_trail_index": item.bow_trail_index,
			"bow_detail_index": item.bow_detail_index,
			"cosmetic_seed": item.cosmetic_seed,
			"cosmetic_uid": item.cosmetic_uid,
			"rare_visual_mod": item.rare_visual_mod,
			"saved_cosmetic_looks": item.saved_cosmetic_looks.duplicate(true)
		})
	var data: Dictionary = {"items": saved_items, "equipment": equipment.duplicate(true), "collected": collected_pickups.duplicate(true), "grid_rows": GRID_ROWS}
	var file: FileAccess = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))

func load_game() -> void:
	var source: String = SAVE_FILE if FileAccess.file_exists(SAVE_FILE) else LEGACY_SAVE_FILE
	if not FileAccess.file_exists(source):
		return
	var file: FileAccess = FileAccess.open(source, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	var data: Dictionary = parsed as Dictionary
	contents.clear()
	grid_positions.clear()
	var restored_indices: Dictionary = {}
	var saved_items: Array = data.get("items", []) if data.get("items", []) is Array else []
	# Pre-v1.68 layouts used 4 rows per page. Preserve the page and local row
	# when importing their absolute grid_y positions, without moving equipment.
	var saved_grid_rows: int = maxi(1, int(data.get("grid_rows", 4)))
	for saved_index in range(saved_items.size()):
		var saved: Variant = saved_items[saved_index]
		if not saved is Dictionary or contents.size() >= capacity:
			continue
		var path: String = str(saved.get("resource", ""))
		if not path.begins_with("res://") or not ResourceLoader.exists(path):
			continue
		var definition: GhostItemData = load(path) as GhostItemData
		if definition != null:
			var item: GhostItemInstance = GhostItemGenerator.create(definition, int(saved.get("seed", 0)), str(saved.get("quality", "normal")))
			# v1/v2 saves lack these keys: retain deterministic roll defaults.
			item.palette_index = clampi(int(saved.get("palette_index", item.palette_index)), 0, 5)
			item.decoration_index = clampi(int(saved.get("decoration_index", item.decoration_index)), 0, 3)
			item.weapon_base_index = clampi(int(saved.get("weapon_base_index", item.weapon_base_index)), 0, 5)
			item.weapon_gradient_index = clampi(int(saved.get("weapon_gradient_index", item.weapon_gradient_index)), 0, 5)
			item.weapon_detail_a_index = clampi(int(saved.get("weapon_detail_a_index", item.weapon_detail_a_index)), 0, 3)
			item.weapon_detail_b_index = clampi(int(saved.get("weapon_detail_b_index", item.weapon_detail_b_index)), 0, 3)
			# A v1.12 save has no effect keys; seeded fallback remains stable.
			item.weapon_fx_style_index = clampi(int(saved.get("weapon_fx_style_index", item.weapon_fx_style_index)), 0, GhostWeaponFXLibrary.motif_limit(item.quality) - 1)
			item.weapon_fx_color_index = clampi(int(saved.get("weapon_fx_color_index", item.weapon_fx_color_index)), 0, GhostWeaponFXLibrary.PAINT.size() - 1)
			item.weapon_fx_accent_index = clampi(int(saved.get("weapon_fx_accent_index", item.weapon_fx_accent_index)), 0, GhostWeaponFXLibrary.PAINT.size() - 1)
			item.weapon_fx_trail_index = clampi(int(saved.get("weapon_fx_trail_index", item.weapon_fx_trail_index)), 0, GhostWeaponFXLibrary.trail_limit(item.quality) - 1)
			item.wand_cast_style_index = clampi(int(saved.get("wand_cast_style_index", item.wand_cast_style_index)), 0, GhostWeaponFXLibrary.form_limit(item.quality) - 1)
			item.weapon_impact_style_index = clampi(int(saved.get("weapon_impact_style_index", item.weapon_impact_style_index)), 0, GhostWeaponFXLibrary.impact_limit(item.quality) - 1)
			item.wand_lance_index = clampi(int(saved.get("wand_lance_index", item.wand_lance_index)), 0, 1)
			# For pre-v1.38 saves, generator rolls the same stable bow imprint.
			item.bow_element_index = clampi(int(saved.get("bow_element_index", item.bow_element_index)), 0, 3)
			item.bow_formation_index = clampi(int(saved.get("bow_formation_index", item.bow_formation_index)), 0, 1)
			item.bow_glow_index = clampi(int(saved.get("bow_glow_index", item.bow_glow_index)), 0, 9)
			item.bow_trail_index = clampi(int(saved.get("bow_trail_index", item.bow_trail_index)), 0, 5)
			item.bow_detail_index = clampi(int(saved.get("bow_detail_index", item.bow_detail_index)), 0, 4)
			# These keys are optional: old saves preserve their exact appearance.
			item.cosmetic_seed = int(saved.get("cosmetic_seed", -1))
			# Old saves without an ID retain their original seed-derived visual look.
			item.cosmetic_uid = str(saved.get("cosmetic_uid", ""))
			item.rare_visual_mod = int(saved.get("rare_visual_mod", -1))
			item.saved_cosmetic_looks.clear()
			var saved_looks: Variant = saved.get("saved_cosmetic_looks", [])
			if saved_looks is Array:
				for look in saved_looks:
					if look is Dictionary and look.has("seed") and item.saved_cosmetic_looks.size() < 16:
						item.saved_cosmetic_looks.append((look as Dictionary).duplicate(true))
			for jewel in saved.get("socketed", []):
				if jewel is Dictionary and item.socketed.size() < item.sockets:
					item.socketed.append(jewel.duplicate(true))
			var wanted: Vector2i = Vector2i(int(saved.get("grid_x", -1)), int(saved.get("grid_y", -1)))
			if wanted.y >= 0 and saved_grid_rows != GRID_ROWS:
				var old_page: int = int(floor(float(wanted.y) / float(saved_grid_rows)))
				wanted.y = old_page * GRID_ROWS + posmod(wanted.y, saved_grid_rows)
			var pos: Vector2i = wanted if _fits(item, wanted) else _first_open(item)
			if pos.x >= 0:
				restored_indices[saved_index] = contents.size()
				contents.append(item)
				grid_positions.append(pos)
	collected_pickups.clear()
	for key in (data.get("collected", {}) as Dictionary).keys():
		collected_pickups[str(key)] = true
	for slot in equipment.keys():
		equipment[slot] = -1
	var equipped_saved: Dictionary = data.get("equipment", {}) as Dictionary
	for slot in equipment.keys():
		var saved_idx: int = int(equipped_saved.get(slot, -1))
		var idx: int = int(restored_indices.get(saved_idx, -1))
		var chosen: GhostItemInstance = get_item(idx)
		if chosen != null and chosen.get_slot() == str(slot):
			equipment[slot] = idx
	contents_changed.emit()
	equipment_changed.emit()
	if source == LEGACY_SAVE_FILE or saved_grid_rows != GRID_ROWS:
		save_game()
