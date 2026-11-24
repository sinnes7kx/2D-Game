extends SceneTree
const INV = preload("res://scripts/inventory.gd")
const PANEL = preload("res://scenes/inventory_panel.tscn")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var inv: Node = INV.new()
	var base: GhostItemData = load("res://items/rosemirror_twinblade_v170.tres") as GhostItemData
	var first: GhostItemInstance = GhostItemGenerator.create(base, 192201, "rare")
	first.cosmetic_uid = "0123456789abcdef0123456789abcdef"
	first.collector_locked = true
	first.collector_favorite = true
	var second: GhostItemInstance = GhostItemGenerator.create(base, 192202, "rare")
	second.cosmetic_uid = first.cosmetic_uid # Same look, separate possessions.
	second.collector_locked = true
	var known: Dictionary = inv._serialize_item(first, Vector2i(0, 5))
	var overflow: Dictionary = inv._serialize_item(second, Vector2i(4, 5))
	var missing: Dictionary = known.duplicate(true)
	missing["resource"] = "res://items/recovery_fixture_missing_v1922.tres"
	missing["future_metadata"] = {"custom_field": ["keep", 14]}
	var fixture: Dictionary = {"items": [missing, known, overflow], "equipment": {"sword": 1}, "collected": {"fixture_pickup": true}, "grid_rows": 4, "vault": []}
	inv.capacity = 1
	if not inv._restore_save_data(fixture):
		_fail("Legacy fixture failed to load")
		return
	if inv.contents.size() != 1 or inv.unresolved_backpack.size() != 2 or inv.get_equipped("sword") != inv.contents[0]:
		_fail("Missing resource shifted equipment or discarded overflow")
		return
	if inv.get_position(0) != Vector2i(0,7) or inv.contents[0].all_stats() != first.all_stats() or not inv.contents[0].collector_locked:
		_fail("Old grid migration or saved stat/protection failed")
		return
	var panel: Control = PANEL.instantiate()
	root.add_child(panel)
	panel.call("bind_inventory", inv)
	if not str(panel.get_node("Layout/InventoryNotice").text).contains("2 item(s)"):
		_fail("Recovery notice missing from inventory")
		return
	panel.free()
	var saved: Dictionary = JSON.parse_string(JSON.stringify(inv._build_save_data()))
	if saved["unresolved_backpack"].size() != 2 or saved["unresolved_backpack"][0]["future_metadata"] != missing["future_metadata"]:
		_fail("Unknown raw metadata lost on serialization")
		return
	inv.capacity = 72
	if not inv._restore_save_data(saved) or inv.contents.size() != 2 or inv.unresolved_backpack.size() != 1:
		_fail("Overflow did not recover after capacity restored")
		return
	if inv.contents[1].item_seed != second.item_seed or inv.contents[1].cosmetic_uid != first.cosmetic_uid or not inv.contents[1].collector_locked or inv.get_equipped("sword") != inv.contents[0]:
		_fail("Recovery changed identity or equipped another item")
		return
	# Simulate the missing resource becoming available again; preserve the
	# exact record's rolls and metadata until recovery is actually possible.
	var retry: Dictionary = inv._build_save_data()
	retry["unresolved_backpack"][0]["resource"] = base.resource_path
	if not inv._restore_save_data(retry) or inv.contents.size() != 3 or not inv.unresolved_backpack.is_empty():
		_fail("Restored definition did not recover")
		return
	if inv.contents[2].cosmetic_snapshot() != first.cosmetic_snapshot() or inv.contents[2].all_stats() != first.all_stats():
		_fail("Recovered item's appearance or stats changed")
		return
	var before: Dictionary = inv._build_save_data()
	if inv._restore_save_data({"items": [known, "invalid"]}) or inv._restore_save_data({}) or inv._build_save_data() != before:
		_fail("Malformed save replaced live state")
		return
	inv.save_block_reason = "fixture: invalid save"
	if inv.save_game():
		_fail("Blocked save attempted overwrite")
		return
	# Isolated fixture, never read/write an actual player save.
	var dir: String = "user://v1922_recovery_fixture_%d" % Time.get_ticks_usec()
	if DirAccess.make_dir_recursive_absolute(dir) != OK:
		_fail("Could not create test folder")
		return
	var source: String = dir + "/legacy.json"
	var file: FileAccess = FileAccess.open(source, FileAccess.WRITE)
	if file == null:
		_fail("Could not write fixture")
		return
	file.store_string("original legacy fixture")
	file.close()
	inv.migration_backup_source = source
	if not inv._backup_migration_source() or FileAccess.get_file_as_string(source + ".pre-grid6.bak") != "original legacy fixture":
		_fail("Pre-migration backup did not preserve bytes")
		return
	inv.migration_backup_source = source
	if not inv._backup_migration_source() or not FileAccess.file_exists(source + ".pre-grid6.1.bak"):
		_fail("Existing backup was not retained")
		return
	for name in ["legacy.json", "legacy.json.pre-grid6.bak", "legacy.json.pre-grid6.1.bak"]:
		DirAccess.remove_absolute(dir + "/" + name)
	DirAccess.remove_absolute(dir)
	inv.free()
	print("v1.92.2 PASS: missing resources, overflow recovery, exact saved identity, old grid mapping, malformed save rejection and migration backup")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
