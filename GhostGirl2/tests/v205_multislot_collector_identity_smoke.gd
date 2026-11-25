extends SceneTree
## M0/M1: synthetic multitype collection identity, completely in memory.
## Never invoke save_game(), load_game() or touch user:// files.
const INVENTORY = preload("res://scripts/inventory.gd")
const ROLL = preload("res://scripts/collector_roll_code_v1931.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var inv: Node = INVENTORY.new()
    var resources: Array[String] = [
        "res://items/gloamrose_dual_swords_v174.tres",
        "res://items/thornrose_bow.tres",
        "res://items/v202_luminous_eyes.tres",
        "res://items/v202_moonlit_tiara.tres"
    ]
    var originals: Array[Dictionary] = []
    for i in range(resources.size()):
        var definition: GhostItemData = load(resources[i]) as GhostItemData
        if definition == null:
            _fail("Missing fixture definition: " + resources[i])
            return
        var item: GhostItemInstance = inv.generate_find(definition, 205100 + i * 139, "rare", "moonwake_crypt")
        item.collector_locked = true
        item.collector_favorite = true
        item.origin_room = "moonwake_crypt"
        if not item.save_cosmetic_look():
            _fail("Failed to bookmark original cosmetic appearance: " + resources[i])
            return
        var born: Dictionary = item.cosmetic_snapshot().duplicate(true)
        var birth_code: String = item.birth_roll_code_v1
        var birth_uid: String = item.birth_roll_uid_v1
        var physical: Dictionary = item.all_stats().duplicate(true)
        var seed: int = item.item_seed
        var quality: String = item.quality
        var affixes: Array[Dictionary] = item.affixes.duplicate(true)
        var sockets: int = item.sockets
        item.apply_cosmetic_uid("0123456789abcdef0123456789abcdef" if i % 2 == 0 else "fedcba9876543210fedcba9876543210")
        item.gradient_version = 2
        if item.item_seed != seed or item.quality != quality or item.all_stats() != physical or item.affixes != affixes or item.sockets != sockets:
            _fail("Appearance change modified combat item identity: " + resources[i])
            return
        if item.birth_roll_code_v1 != birth_code or item.birth_roll_uid_v1 != birth_uid:
            _fail("Appearance change modified original discovery imprint")
            return
        if not item.restore_cosmetic_look(0) or item.cosmetic_snapshot() != born:
            _fail("Favorite appearance did not reproduce exactly")
            return
        item.apply_cosmetic_uid("abcdef0123456789abcdef0123456789" if i % 2 == 0 else "1234567890abcdef1234567890abcdef")
        item.gradient_version = 2
        inv.contents.append(item)
        inv.grid_positions.append(Vector2i(i * 2, 0))
        originals.append({
            "seed": seed, "quality": quality, "stats": physical,
            "affixes": affixes, "sockets": sockets,
            "born": born, "birth_code": birth_code, "birth_uid": birth_uid,
            "current": item.cosmetic_snapshot().duplicate(true),
            "saved_looks": item.saved_cosmetic_looks.duplicate(true),
            "slot": item.get_slot(), "roll": ROLL.current(item)
        })
    inv.equipment["sword"] = 0
    inv.equipment["wings"] = 2
    inv.equipment["helm"] = 3
    inv.collected_pickups["fixture:found-moonlit-cache"] = true
    var raw: Dictionary = inv._build_save_data()
    var encoded: Variant = JSON.parse_string(JSON.stringify(raw))
    if not encoded is Dictionary:
        _fail("Save payload was not valid JSON")
        return
    var restored: Node = INVENTORY.new()
    if not restored._restore_save_data(encoded) or restored.contents.size() != originals.size():
        _fail("Restored collection lost item records")
        return
    if restored.equipment != inv.equipment or restored.collected_pickups != inv.collected_pickups:
        _fail("Equipped slots or collected flags changed on reload")
        return
    if not restored.vault.is_empty() or not restored.unresolved_backpack.is_empty():
        _fail("Reload introduced phantom duplicates")
        return
    for i in range(originals.size()):
        var expected: Dictionary = originals[i]
        var item: GhostItemInstance = restored.contents[i]
        if item.item_seed != expected["seed"] or item.quality != expected["quality"] or item.all_stats() != expected["stats"]:
            _fail("Item seed, rarity or stats changed on JSON reload: " + str(i))
            return
        if item.affixes != expected["affixes"] or item.sockets != expected["sockets"]:
            _fail("Item affixes/sockets changed on JSON reload: " + str(i))
            return
        if item.cosmetic_snapshot() != expected["current"] or item.saved_cosmetic_looks != expected["saved_looks"]:
            print("CURRENT_EXPECTED ", JSON.stringify(expected["current"]))
            print("CURRENT_ACTUAL ", JSON.stringify(item.cosmetic_snapshot()))
            print("SAVED_EXPECTED ", JSON.stringify(expected["saved_looks"]))
            print("SAVED_ACTUAL ", JSON.stringify(item.saved_cosmetic_looks))
            _fail("Current appearance or bookmarked looks changed: " + str(i))
            return
        if item.birth_roll_code_v1 != expected["birth_code"] or item.birth_roll_uid_v1 != expected["birth_uid"] or ROLL.current(item) != expected["roll"]:
            _fail("Birth/current rarity fingerprint changed: " + str(i))
            return
        if not item.collector_favorite or not item.collector_locked or item.get_slot() != expected["slot"] or item.origin_room != "moonwake_crypt":
            _fail("Collector flags, item slot or provenance changed: " + str(i))
            return
        var current: Dictionary = item.cosmetic_snapshot().duplicate(true)
        if not item.restore_cosmetic_look(0) or item.cosmetic_snapshot() != expected["born"]:
            _fail("Bookmarked original appearance failed after reload: " + str(i))
            return
        if item.item_seed != expected["seed"] or item.all_stats() != expected["stats"] or item.birth_roll_code_v1 != expected["birth_code"]:
            _fail("Restoring favorite appearance changed intrinsic item: " + str(i))
            return
        if current == item.cosmetic_snapshot():
            _fail("Restored favorite did not switch the changed appearance: " + str(i))
            return
    restored.free()
    inv.free()
    print("M0/M1 PASS: 4 equipment families, equipped slots, seed, stats, birth/current code, saved looks and in-memory JSON reload")
    quit(0)

func _fail(message: String) -> void:
    push_error(message)
    quit(1)
