extends SceneTree
## M2 vault regression: head accessories and tiaras may be stored as safely
## as swords, including protected/favorite records and exhibition assignments.
## Synthetic in-memory fixtures only; never writes a player user:// save.
const INV = preload("res://scripts/inventory.gd")
const VAULT = preload("res://scripts/collection_vault_v181.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var inv: Node = INV.new()
    var eyes_data: GhostItemData = load("res://items/v202_luminous_eyes.tres") as GhostItemData
    var tiara_data: GhostItemData = load("res://items/v202_moonlit_tiara.tres") as GhostItemData
    if eyes_data == null or tiara_data == null:
        _fail("Head accessory and helm resources must exist")
        return
    var eyes: GhostItemInstance = GhostItemGenerator.create(eyes_data, 206011, "rare")
    var tiara: GhostItemInstance = GhostItemGenerator.create(tiara_data, 206017, "magic")
    eyes.collector_favorite = true
    eyes.collector_locked = true
    eyes.apply_cosmetic_uid("abcdef0123456789abcdef0123456789")
    eyes.gradient_version = 2
    if not eyes.save_cosmetic_look():
        _fail("Cannot bookmark collectible eye palette")
        return
    var snapshot: Dictionary = eyes.cosmetic_snapshot()
    var stats: Dictionary = eyes.all_stats()
    var seed: int = eyes.item_seed
    inv.contents.append(eyes)
    inv.grid_positions.append(Vector2i(0, 0))
    inv.contents.append(tiara)
    inv.grid_positions.append(Vector2i(2, 0))
    inv.equipment["wings"] = 0
    if inv.vault_store(0, false):
        _fail("Equipped Glowing Eyes were stored without unequipping")
        return
    inv.equipment["wings"] = -1
    var original: Dictionary = inv._build_save_data()
    inv.save_block_reason = "fixture: disk unavailable"
    if inv.vault_store(0, true) or inv._build_save_data() != original:
        _fail("Failed eye transfer mutated the collection")
        return
    inv.save_block_reason = ""
    if not inv.vault_store(0, false) or inv.vault[0] != eyes:
        _fail("Unequipped collectible eyes cannot enter the vault")
        return
    if not inv.vault_store(0, false) or inv.vault[1] != tiara:
        _fail("Unequipped collectible tiara cannot enter the vault")
        return
    if not inv.set_exhibition(eyes, 1, false) or inv.exhibition_item(1) != eyes:
        _fail("Vaulted eyes did not retain exact exhibition instance")
        return
    var stored: Dictionary = inv._build_save_data()
    inv.save_block_reason = "fixture: disk unavailable"
    if inv.vault_withdraw(0, true) or inv._build_save_data() != stored:
        _fail("Failed eye withdrawal altered display or collector records")
        return
    inv.save_block_reason = ""
    var reloaded: Node = INV.new()
    var json: Variant = JSON.parse_string(JSON.stringify(inv._build_save_data()))
    if not json is Dictionary or not reloaded._restore_save_data(json) or reloaded.vault.size() != 2:
        _fail("Equipment vault did not survive JSON reload")
        return
    var restored: GhostItemInstance = reloaded.vault[0]
    if restored.definition.item_id != eyes_data.item_id or restored.item_seed != seed or restored.cosmetic_snapshot() != snapshot or restored.all_stats() != stats:
        _fail("Vault JSON reload mutated eye seed, palette or stats")
        return
    if not restored.collector_favorite or not restored.collector_locked or reloaded.exhibition_item(1) != restored:
        _fail("Vault reload lost protection or display assignment")
        return
    var ui: Control = VAULT.new()
    root.add_child(ui)
    ui.open_vault(inv, eyes)
    if ui.get("shown").size() != 2:
        _fail("Collection Vault UI still filters out head equipment")
        return
    var view: OptionButton = ui.get("source_view") as OptionButton
    view.select(1)
    ui.refresh()
    if ui.get("shown").size() != 0:
        _fail("Backpack shows items already stored in the vault")
        return
    ui.free()
    if not inv.vault_withdraw(0, false) or inv.contents[0] != eyes:
        _fail("Eye withdrawal lost original item instance")
        return
    if eyes.item_seed != seed or eyes.cosmetic_snapshot() != snapshot or eyes.all_stats() != stats or not eyes.collector_locked or not eyes.collector_favorite:
        _fail("Head accessory changed during vault roundtrip")
        return
    inv.free()
    reloaded.free()
    print("v2.06 PASS: accessory/helm vault, equipped guard, failed-transfer rollback, exhibition, palette and JSON reload")
    quit(0)

func _fail(message: String) -> void:
    push_error(message)
    quit(1)
