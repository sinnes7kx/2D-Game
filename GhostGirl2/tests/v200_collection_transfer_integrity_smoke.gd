extends SceneTree
## M0 next roadmap slice: exact owned item survives rejected disk writes and
## vault/display moves. Synthetic in-memory inventory; no private saves.
const INVENTORY = preload("res://scripts/inventory.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var inv: Node = INVENTORY.new()
    var template: GhostItemData = load("res://items/gloamrose_dual_swords_v174.tres") as GhostItemData
    var item: GhostItemInstance = GhostItemGenerator.create(template, 200911, "rare")
    item.cosmetic_uid = "c6b8cfd579a1e0c229fe843b71f609ad"
    item.gradient_version = 2
    item.collector_favorite = true
    item.collector_locked = true
    if not item.save_cosmetic_look():
        _fail("Could not save a protected cosmetic favorite")
        return
    inv.contents.append(item)
    inv.grid_positions.append(Vector2i(0, 0))
    inv.equipment["sword"] = -1
    var original: Dictionary = inv._build_save_data()
    var appearance: Dictionary = item.cosmetic_snapshot()
    var stats: Dictionary = item.all_stats()
    var saved_seed: int = item.item_seed
    var saved_uid: String = item.cosmetic_uid
    inv.save_block_reason = "fixture: disk unavailable"
    if inv.vault_store(0, true) or inv.contents.size() != 1 or not inv.vault.is_empty() or inv.contents[0] != item:
        _fail("Rejected deposit removed or duplicated the owned item")
        return
    if inv._build_save_data() != original:
        _fail("Rejected deposit mutated collection identity")
        return
    inv.save_block_reason = ""
    if not inv.vault_store(0, false):
        _fail("Cannot deposit protected, unequipped item")
        return
    if not inv.set_exhibition(item, 2, false) or inv.exhibition_item(2) != item:
        _fail("Exhibition lost exact vault instance")
        return
    var vaulted: Dictionary = inv._build_save_data()
    inv.save_block_reason = "fixture: disk unavailable"
    if inv.vault_withdraw(0, true) or inv.vault.size() != 1 or not inv.contents.is_empty():
        _fail("Failed withdrawal lost or cloned the vault item")
        return
    if inv._build_save_data() != vaulted or inv.exhibition_item(2) != item:
        _fail("Withdrawal rollback dropped exhibition assignment or item rolls")
        return
    inv.save_block_reason = ""
    if not inv.vault_withdraw(0, false):
        _fail("Vault withdrawal did not succeed after save access restored")
        return
    if inv.contents.size() != 1 or not inv.vault.is_empty() or inv.contents[0] != item or item.exhibition_slot != -1:
        _fail("Withdrawn item identity or exhibition cleanup incorrect")
        return
    if item.item_seed != saved_seed or item.cosmetic_uid != saved_uid or item.all_stats() != stats or item.cosmetic_snapshot() != appearance or not item.collector_favorite or not item.collector_locked:
        _fail("Vault roundtrip changed favorite/protection/seed/stats/appearance")
        return
    var encoded: Dictionary = JSON.parse_string(JSON.stringify(inv._build_save_data())) as Dictionary
    var recovered: Node = INVENTORY.new()
    if not recovered._restore_save_data(encoded) or recovered.contents.size() != 1 or recovered.contents[0].gradient_version != 2:
        _fail("Versioned dark appearance failed inventory reload")
        return
    var carried: GhostItemInstance = recovered.contents[0]
    if carried.cosmetic_snapshot() != appearance or carried.item_seed != saved_seed or carried.all_stats() != stats or not carried.collector_locked or not carried.collector_favorite:
        _fail("Reload altered collectible identity")
        return
    recovered.free()
    inv.free()
    print("v2.00 M0 PASS: deposit/withdraw rollback, exhibition, seed, look, stats and protected vault roundtrip")
    quit(0)

func _fail(message: String) -> void:
    push_error(message)
    quit(1)
