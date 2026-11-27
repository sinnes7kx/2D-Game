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
    # Tests must never write a real user:// inventory; equip indexing is
    # serialized identically when assigned directly in this isolated fixture.
    inv.equipment["wings"] = 0
    inv.equipment["helm"] = 4
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
    var horns = preload("res://scripts/horn_anchors_v268.gd")
    var img: Image = Image.create(256,220,false,Image.FORMAT_RGBA8)
    img.fill(Color.TRANSPARENT)
    img.fill_rect(Rect2i(95,18,70,55),Color.WHITE)
    var front: PackedVector2Array = horns.measure(img,"front")
    assert(front.size()==2 and front[0].x>95.0 and front[1].x<165.0)
    assert(front[0].y==36.0 and front[1].y==36.0)
    var profile: PackedVector2Array = horns.measure(img,"left")
    assert(profile[0].distance_to(profile[1])<front[0].distance_to(front[1]))
    assert(horns.far_side("back_right")==1 and horns.far_side("front_left")==0)
    assert(horns.direction("wand_walk_back_left","back")=="back_left")
    var sprite: AnimatedSprite2D = actor.get_node("Ghost") as AnimatedSprite2D
    assert(horns.pixel_to_local(Vector2(128,110),sprite).is_equal_approx(sprite.offset))
    var guide = horns.new()
    var roots: PackedVector2Array = guide.frame_roots(sprite,"front")
    assert(roots.size()==2)
    actor.free()
    inv.free()
    restored.free()
    old.free()
    print("v2.02 PASS: 4 accessory resources, 2 independent helms, legacy wings migration, live head layer and companion")
    quit(0)

func _fail(reason: String) -> void:
    push_error(reason)
    quit(1)
