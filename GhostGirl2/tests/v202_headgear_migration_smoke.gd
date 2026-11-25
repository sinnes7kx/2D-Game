extends SceneTree
## New additive helm + untouched wings equipment migration, and real preview rig.
const INV = preload("res://scripts/inventory.gd")
const PLAYER = preload("res://scenes/player.tscn")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var inv: Node = INV.new()
    var ids: Array[String] = ["v202_luminous_eyes", "v202_bandit_mask", "v202_crescent_halo", "v202_rose_horns", "v202_moonlit_tiara", "v202_starfall_diadem"]
    for i in range(ids.size()):
        var resource: GhostItemData = load("res://items/%s.tres" % ids[i]) as GhostItemData
        if resource == null or resource.icon == null or resource.equip_slot != ("wings" if i < 4 else "helm"):
            _fail("Broken accessory item or icon: " + ids[i])
            return
        var item: GhostItemInstance = GhostItemGenerator.create(resource, 202200 + i, "magic")
        inv.contents.append(item)
        inv.grid_positions.append(Vector2i(i, 0))
    if not inv.equip_at(0) or not inv.equip_at(4):
        _fail("Head accessory and helm cannot be equipped independently")
        return
    if inv.get_equipped("wings") != inv.contents[0] or inv.get_equipped("helm") != inv.contents[4]:
        _fail("Helm overwrote the separately equipped head accessory")
        return
    var data: Dictionary = inv._build_save_data()
    if int(data["equipment"]["wings"]) != 0 or int(data["equipment"]["helm"]) != 4:
        _fail("Both equipment keys must be present in the same safe save")
        return
    var restored: Node = INV.new()
    if not restored._restore_save_data(data):
        _fail("Cannot deserialize additive helm slot")
        return
    if restored.get_equipped("wings").definition.item_id != ids[0] or restored.get_equipped("helm").definition.item_id != ids[4]:
        _fail("Save/reload lost a head accessory or diadem")
        return
    if restored.get_equipped("wings").item_seed != 202200 or restored.get_equipped("helm").item_seed != 202204:
        _fail("Save/reload changed item seeds")
        return
    var legacy: Dictionary = data.duplicate(true)
    (legacy["equipment"] as Dictionary).erase("helm")
    var old: Node = INV.new()
    if not old._restore_save_data(legacy) or old.get_equipped("wings") == null or old.get_equipped("helm") != null:
        _fail("A legacy wings-only save failed after helm slot addition")
        return
    var original_legacy: GhostItemData = load("res://items/rosewing_mantle.tres") as GhostItemData
    if original_legacy == null or original_legacy.equip_slot != "wings":
        _fail("Legacy Rosewing Mantle equipment key was changed")
        return
    var actor: Node2D = PLAYER.instantiate() as Node2D
    root.add_child(actor)
    var head_layer: Node = actor.get_node_or_null("EquipmentVisuals/HeadCosmeticsV202")
    var familiar: Node = actor.get_node_or_null("MoonmothGuideV202")
    if head_layer == null or familiar == null:
        _fail("Live Ghost Girl body lacks accessory layer or companion")
        return
    actor.free()
    inv.free()
    restored.free()
    old.free()
    print("v2.02 PASS: 4 accessory resources, 2 independent helms, legacy wings migration, live head layer and companion")
    quit(0)

func _fail(reason: String) -> void:
    push_error(reason)
    quit(1)
