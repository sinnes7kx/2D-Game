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
const VAULT_CAPACITY: int = 240
const EXHIBITION_CAPACITY: int = 6
var vault: Array[GhostItemInstance] = []
var unresolved_vault: Array[Dictionary] = []
# Unavailable or overflow backpack records remain recoverable, not playable.
var unresolved_backpack: Array[Dictionary] = []
var save_block_reason: String = ""
var migration_backup_source: String = ""

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

func add_pickup(template: GhostItemData, pickup_id: String, item_seed: int, origin: String = "") -> GhostItemInstance:
	if pickup_id.is_empty() or collected_pickups.has(pickup_id):
		return null
	var item: GhostItemInstance = add_loot(template, item_seed, "", origin)
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

func add_loot(template: GhostItemData, seed_value: int, forced_quality: String = "", origin: String = "") -> GhostItemInstance:
	if template == null or contents.size() >= capacity:
		return null
	template = _resolve_socketable_loot_template(template, seed_value)
	if template.unique and has_item(template.item_id):
		return null
	var item: GhostItemInstance = generate_find(template, seed_value, forced_quality, origin)
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
	if item == null or item.is_broken() or item.get_slot() == "none" or not equipment.has(item.get_slot()):
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
	return item != null and item.definition != null and item.definition.item_class != "quest" and not item.collector_locked

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
	if item == null or item.definition == null or item.definition.item_class == "quest" or item.collector_locked:
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
	if component.definition == null or component.collector_locked or component.definition.item_class not in ["gem", "rune"]:
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

func _build_save_data() -> Dictionary:
	var saved_items: Array[Dictionary] = []
	for i in range(contents.size()):
		var item: GhostItemInstance = contents[i]
		if item.definition == null or item.definition.resource_path.is_empty():
			continue
		var pos: Vector2i = get_position(i)
		saved_items.append(_serialize_item(item, pos))
	var saved_vault: Array[Dictionary] = unresolved_vault.duplicate(true)
	for item in vault:
		saved_vault.append(_serialize_item(item, Vector2i(-1, -1)))
	return {"items": saved_items, "equipment": equipment.duplicate(true), "collected": collected_pickups.duplicate(true), "grid_rows": GRID_ROWS, "vault": saved_vault, "unresolved_backpack": unresolved_backpack.duplicate(true)}

func save_game() -> bool:
	if not save_block_reason.is_empty():
		return false
	if not _backup_migration_source():
		save_block_reason = "Could not back up old inventory; original save preserved."
		push_warning(save_block_reason)
		return false
	var data: Dictionary = _build_save_data()
	var temporary: String = SAVE_FILE + ".tmp"
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		return false
	# Backpack and vault share one atomic save, so moving an item cannot
	# save only one side of the transfer.
	return DirAccess.rename_absolute(temporary, SAVE_FILE) == OK

func _serialize_item(item: GhostItemInstance, pos: Vector2i) -> Dictionary:
	return {
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
		"saved_cosmetic_looks": item.saved_cosmetic_looks.duplicate(true),
		"collector_favorite": item.collector_favorite, "collector_locked": item.collector_locked, "exhibition_slot": item.exhibition_slot, "origin_room": item.origin_room, "regional_rank": item.regional_rank,
		"ethereal": item.ethereal, "durability": item.durability, "max_durability": item.max_durability,
		"rolled_stat": item.stat_value, "rolled_affixes": item.affixes.duplicate(true), "rolled_sockets": item.sockets
	}

# Preserve the pre-migration file before writing a changed grid format.
# Use a new backup name rather than replacing an older recovery copy.
func _backup_migration_source() -> bool:
	if migration_backup_source.is_empty():
		return true
	var backup: String = migration_backup_source + ".pre-grid6.bak"
	var suffix: int = 0
	while FileAccess.file_exists(backup):
		suffix += 1
		backup = migration_backup_source + ".pre-grid6.%d.bak" % suffix
		if suffix >= 1000:
			return false
	if DirAccess.copy_absolute(migration_backup_source, backup) != OK:
		return false
	migration_backup_source = ""
	return true

func load_game() -> void:
	var source: String = SAVE_FILE if FileAccess.file_exists(SAVE_FILE) else LEGACY_SAVE_FILE
	if not FileAccess.file_exists(source):
		return
	var file: FileAccess = FileAccess.open(source, FileAccess.READ)
	if file == null:
		save_block_reason = "Inventory save could not be opened; saving disabled."
		push_warning(save_block_reason)
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary or not _restore_save_data(parsed):
		save_block_reason = "Inventory save is invalid; original file preserved. Saving disabled."
		push_warning(save_block_reason)
		return
	save_block_reason = ""
	if source == LEGACY_SAVE_FILE or int(parsed.get("grid_rows", 4)) != GRID_ROWS:
		# Legacy v1 stays intact even after the v2 file is created.
		if source == SAVE_FILE:
			migration_backup_source = source
		save_game()

# Validate before touching live state. Reject malformed containers instead
# of quietly rewriting a partial collection over the original file.
func _restore_save_data(data: Dictionary) -> bool:
	if not data.has("items"):
		return false
	for key in ["items", "vault", "unresolved_backpack"]:
		var records: Variant = data.get(key, [])
		if not records is Array:
			return false
		for record in records:
			if not record is Dictionary:
				return false
	for key in ["equipment", "collected"]:
		if not data.get(key, {}) is Dictionary:
			return false
	contents.clear()
	grid_positions.clear()
	unresolved_backpack.clear()
	var restored_indices: Dictionary = {}
	var saved_items: Array = data.get("items", [])
	var saved_grid_rows: int = maxi(1, int(data.get("grid_rows", 4)))
	for saved_index in range(saved_items.size()):
		var saved: Dictionary = saved_items[saved_index]
		var item: GhostItemInstance = null
		if contents.size() < capacity:
			item = _deserialize_item(saved)
		if item != null:
			item.exhibition_slot = -1
			var wanted: Vector2i = Vector2i(int(saved.get("grid_x", -1)), int(saved.get("grid_y", -1)))
			if wanted.y >= 0 and saved_grid_rows != GRID_ROWS:
				var old_page: int = int(floor(float(wanted.y) / float(saved_grid_rows)))
				wanted.y = old_page * GRID_ROWS + posmod(wanted.y, saved_grid_rows)
			var pos: Vector2i = wanted if _fits(item, wanted) else _first_open(item)
			if pos.x >= 0:
				restored_indices[saved_index] = contents.size()
				contents.append(item)
				grid_positions.append(pos)
				continue
		# Preserve the exact record, including fields this build cannot read.
		unresolved_backpack.append(saved.duplicate(true))
	# Retry records from earlier launches after normal backpack items. Never
	# evict a live item or auto-equip a previously inaccessible weapon.
	for saved in data.get("unresolved_backpack", []):
		var item: GhostItemInstance = null
		if contents.size() < capacity:
			item = _deserialize_item(saved)
		if item != null:
			var pos: Vector2i = _first_open(item)
			if pos.x >= 0:
				item.exhibition_slot = -1
				contents.append(item)
				grid_positions.append(pos)
				continue
		unresolved_backpack.append(saved.duplicate(true))
	vault.clear()
	unresolved_vault.clear()
	for saved in data.get("vault", []):
		var stored: GhostItemInstance = _deserialize_item(saved)
		if stored == null:
			unresolved_vault.append(saved.duplicate(true))
		else:
			vault.append(stored)
	_normalize_exhibition()
	collected_pickups.clear()
	for key in (data.get("collected", {}) as Dictionary).keys():
		collected_pickups[str(key)] = true
	var equipped_saved: Dictionary = data.get("equipment", {})
	for slot in equipment.keys():
		equipment[slot] = -1
		var saved_idx: int = int(equipped_saved.get(slot, -1))
		var idx: int = int(restored_indices.get(saved_idx, -1))
		var chosen: GhostItemInstance = get_item(idx)
		if chosen != null and not chosen.is_broken() and chosen.get_slot() == str(slot):
			equipment[slot] = idx
	contents_changed.emit()
	equipment_changed.emit()
	return true

func recovery_notice() -> String:
	if not save_block_reason.is_empty():
		return save_block_reason
	if not unresolved_backpack.is_empty():
		return "%d item(s) safely held for recovery. Free backpack space, restore missing resources, then reload." % unresolved_backpack.size()
	return ""

func _deserialize_item(saved: Dictionary) -> GhostItemInstance:
	var path: String = str(saved.get("resource", ""))
	if not path.begins_with("res://") or not ResourceLoader.exists(path):
		return null
	var definition: GhostItemData = load(path) as GhostItemData
	if definition == null:
		return null
	var item: GhostItemInstance = GhostItemGenerator.create(definition, int(saved.get("seed", 0)), str(saved.get("quality", "normal")))
	# v1/v2 saves lack these keys: retain deterministic roll defaults.
	item.palette_index = clampi(int(saved.get("palette_index", item.palette_index)), 0, 5)
	item.decoration_index = clampi(int(saved.get("decoration_index", item.decoration_index)), 0, 3)
	item.weapon_base_index = clampi(int(saved.get("weapon_base_index", item.weapon_base_index)), -1, 5)
	item.weapon_gradient_index = clampi(int(saved.get("weapon_gradient_index", item.weapon_gradient_index)), 0, 5)
	item.weapon_detail_a_index = clampi(int(saved.get("weapon_detail_a_index", item.weapon_detail_a_index)), 0, 3)
	item.weapon_detail_b_index = clampi(int(saved.get("weapon_detail_b_index", item.weapon_detail_b_index)), 0, 3)
	# A v1.12 save has no effect keys; seeded fallback remains stable.
	item.weapon_fx_style_index = clampi(int(saved.get("weapon_fx_style_index", item.weapon_fx_style_index)), -1, GhostWeaponFXLibrary.motif_limit(item.quality) - 1)
	item.weapon_fx_color_index = clampi(int(saved.get("weapon_fx_color_index", item.weapon_fx_color_index)), -1, GhostWeaponFXLibrary.PAINT.size() - 1)
	item.weapon_fx_accent_index = clampi(int(saved.get("weapon_fx_accent_index", item.weapon_fx_accent_index)), -1, GhostWeaponFXLibrary.PAINT.size() - 1)
	item.weapon_fx_trail_index = clampi(int(saved.get("weapon_fx_trail_index", item.weapon_fx_trail_index)), -1, GhostWeaponFXLibrary.trail_limit(item.quality) - 1)
	item.wand_cast_style_index = clampi(int(saved.get("wand_cast_style_index", item.wand_cast_style_index)), -1, GhostWeaponFXLibrary.form_limit(item.quality) - 1)
	item.weapon_impact_style_index = clampi(int(saved.get("weapon_impact_style_index", item.weapon_impact_style_index)), -1, GhostWeaponFXLibrary.impact_limit(item.quality) - 1)
	item.wand_lance_index = clampi(int(saved.get("wand_lance_index", item.wand_lance_index)), -1, 1)
	# For pre-v1.38 saves, generator rolls the same stable bow imprint.
	item.bow_element_index = clampi(int(saved.get("bow_element_index", item.bow_element_index)), -1, 3)
	item.bow_formation_index = clampi(int(saved.get("bow_formation_index", item.bow_formation_index)), -1, 1)
	item.bow_glow_index = clampi(int(saved.get("bow_glow_index", item.bow_glow_index)), -1, 9)
	item.bow_trail_index = clampi(int(saved.get("bow_trail_index", item.bow_trail_index)), -1, 5)
	item.bow_detail_index = clampi(int(saved.get("bow_detail_index", item.bow_detail_index)), -1, 4)
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
	# Preserve the actual generated rolls: random-quality generation consumes
	# an extra RNG draw compared with forced-quality reconstruction.
	if saved.has("rolled_stat"):
		item.stat_value = snappedf(float(saved["rolled_stat"]), 0.1)
	if saved.get("rolled_affixes") is Array:
		item.affixes.clear()
		for affix in saved["rolled_affixes"]:
			if affix is Dictionary:
				var restored_affix: Dictionary = affix.duplicate(true)
				# Generated affixes are quantized to tenths. JSON decimal parsing
				# can otherwise differ by a floating-point bit from snappedf.
				restored_affix["value"] = snappedf(float(affix.get("value", 0.0)), 0.1)
				item.affixes.append(restored_affix)
	if saved.has("rolled_sockets"):
		item.sockets = clampi(int(saved["rolled_sockets"]), 0, definition.max_sockets)
	for jewel in saved.get("socketed", []):
		if jewel is Dictionary and item.socketed.size() < item.sockets:
			item.socketed.append(jewel.duplicate(true))
	item.collector_favorite = bool(saved.get("collector_favorite", false))
	item.collector_locked = bool(saved.get("collector_locked", false))
	item.exhibition_slot = clampi(int(saved.get("exhibition_slot", -1)), -1, EXHIBITION_CAPACITY - 1)
	item.origin_room = str(saved.get("origin_room", ""))
	item.regional_rank = clampi(int(saved.get("regional_rank", 0)), 0, 3)
	item.ethereal = bool(saved.get("ethereal", false)) and item.supports_ethereal()
	item.max_durability = clampi(int(saved.get("max_durability", 80)), 1, 140) if item.ethereal else 0
	item.durability = clampi(int(saved.get("durability", item.max_durability)), 0, item.max_durability)
	return item

func vault_store(index: int, persist: bool = true) -> bool:
	var item: GhostItemInstance = get_item(index)
	if item == null or item.definition == null or item.get_slot() not in ["sword", "wand"]:
		return false
	if vault.size() + unresolved_vault.size() >= VAULT_CAPACITY:
		return false
	for slot in equipment.keys():
		if equipped_index(str(slot)) == index:
			return false
	var position_before: Vector2i = grid_positions[index]
	var equipment_before: Dictionary = equipment.duplicate(true)
	vault.append(item)
	_remove_item_at(index)
	if persist and not save_game():
		vault.pop_back()
		contents.insert(index, item)
		grid_positions.insert(index, position_before)
		equipment = equipment_before
		return false
	contents_changed.emit()
	equipment_changed.emit()
	return true

func vault_withdraw(index: int, persist: bool = true) -> bool:
	if index < 0 or index >= vault.size() or contents.size() >= capacity:
		return false
	var item: GhostItemInstance = vault[index]
	var pos: Vector2i = _first_open(item)
	if pos.x < 0:
		return false
	var previous_slot: int = item.exhibition_slot
	item.exhibition_slot = -1
	vault.remove_at(index)
	contents.append(item)
	grid_positions.append(pos)
	if persist and not save_game():
		contents.pop_back()
		grid_positions.pop_back()
		vault.insert(index, item)
		item.exhibition_slot = previous_slot
		return false
	contents_changed.emit()
	equipment_changed.emit()
	return true

func set_collector_flag(item: GhostItemInstance, flag: String, value: bool) -> bool:
	if item == null or (not contents.has(item) and not vault.has(item)) or flag not in ["collector_favorite", "collector_locked"]:
		return false
	var old: bool = bool(item.get(flag))
	item.set(flag, value)
	if not save_game():
		item.set(flag, old)
		return false
	contents_changed.emit()
	return true

# Each physical display references a single stored instance. Duplicated
# cosmetic UIDs are allowed; they never identify ownership or slot assignment.
func exhibition_item(slot: int) -> GhostItemInstance:
	if slot < 0 or slot >= EXHIBITION_CAPACITY:
		return null
	for item in vault:
		if item.exhibition_slot == slot:
			return item
	return null

func exhibition_reserved(slot: int) -> bool:
	for record in unresolved_vault:
		if int(record.get("exhibition_slot", -1)) == slot:
			return true
	return false

func _normalize_exhibition() -> void:
	var occupied: Dictionary = {}
	for item in vault:
		var slot: int = item.exhibition_slot
		if slot < 0:
			continue
		if slot >= EXHIBITION_CAPACITY or occupied.has(slot) or exhibition_reserved(slot):
			item.exhibition_slot = -1
		else:
			occupied[slot] = true

func set_exhibition(item: GhostItemInstance, slot: int, persist: bool = true) -> bool:
	if item == null or not vault.has(item) or slot < -1 or slot >= EXHIBITION_CAPACITY:
		return false
	if slot >= 0 and exhibition_reserved(slot):
		return false
	var previous: int = item.exhibition_slot
	var replaced: GhostItemInstance = exhibition_item(slot)
	if replaced == item:
		return true
	if replaced != null:
		replaced.exhibition_slot = -1
	item.exhibition_slot = slot
	if persist and not save_game():
		item.exhibition_slot = previous
		if replaced != null:
			replaced.exhibition_slot = slot
		return false
	contents_changed.emit()
	return true

# One use per actual melee contact action or successful wand release.
# Broken items survive as collectible relics, but cannot be equipped.
func wear_ethereal(item: GhostItemInstance, persist: bool = true) -> bool:
	if item == null or not contents.has(item) or not item.ethereal or item.is_broken():
		return false
	var broke: bool = item.wear_once()
	if broke:
		var index: int = contents.find(item)
		for slot in equipment.keys():
			if equipped_index(str(slot)) == index:
				equipment[slot] = -1
		equipment_changed.emit()
	contents_changed.emit()
	if persist:
		save_game()
	return broke

# Roll a natural weapon once, before showing it on the ground. No inventory mutation.
func generate_find(template: GhostItemData, seed_value: int, forced_quality: String = "", origin: String = "") -> GhostItemInstance:
	if template == null:
		return null
	var item: GhostItemInstance = GhostItemGenerator.create(template, seed_value, forced_quality)
	# New drops roll an independent, 128-bit cosmetic identity once, before presentation.
	# Do not change the item_seed that determines damage, affixes and sockets.
	if template.equip_slot != "none" and template.item_class == "equipment":
		item.apply_cosmetic_uid(GhostCosmeticRNGV152.fresh_uid())
	item.stamp_origin(origin)
	if not origin.is_empty():
		item.roll_ethereal()
	return item
