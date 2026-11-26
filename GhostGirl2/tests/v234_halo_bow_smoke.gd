extends SceneTree
const HEAD = preload("res://scripts/head_cosmetics_v202.gd")
const SURFACE = preload("res://scripts/weapon_surface_v190.gd")
const GAME = preload("res://scripts/game.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var ids: Array[String] = ["thornrose_bow", "moonveil_bow", "blackthorn_bow_v234", "reliquary_silver_bow_v234"]
    var styles: Array[String] = ["thornrose", "moonveil", "thornrose", "moonveil"]
    for i in range(ids.size()):
        var definition: GhostItemData = load("res://items/" + ids[i] + ".tres") as GhostItemData
        if definition == null or definition.icon == null or definition.weapon_style != "bow":
            _fail("Bow definition or icon missing")
            return
        var item: GhostItemInstance = GhostItemGenerator.create(definition, 1234, "rare")
        if item.bow_art_style() != styles[i]:
            _fail("Bow base mapped to incorrect painted rig")
            return
        var palette: Array[Color] = SURFACE.bow_pigment(item, item.collector_appearance())
        if palette.size() != item.bow_limb_gradient_colors().size():
            _fail("Material variant lost its seeded gradient")
            return
    var game: Node = GAME.new()
    var original: GhostItemData = load("res://items/dusk_needle.tres") as GhostItemData
    var seen: Dictionary = {}
    for i in range(1, 25):
        var found: GhostItemData = game.call("_roll_sword_drop", original, i * 23) as GhostItemData
        if found != null:
            seen[str(found.item_id)] = true
    if seen.size() != 4:
        _fail("Four bows not obtainable in the existing bow lane")
        return
    game.free()
    for face in ["front", "back", "left", "right"]:
        if HEAD.body_halo_center(null, face, false) != HEAD.halo_center(face, "idle_" + face, 0, false):
            _fail("Halo particle and head centers disagree")
            return
    var source: String = FileAccess.get_file_as_string("res://scripts/equipment_visuals.gd")
    var refresh: String = source.get_slice("func refresh() -> void:", 1).get_slice("\nfunc ", 0)
    if refresh.find("var amulet: GhostItemInstance") < 0 or refresh.find("var amulet: GhostItemInstance") > refresh.find("_rebuild_ambient_sources(feather, amulet,"):
        _fail("Missing refresh amulet declaration")
        return
    print("v2.34 PASS: four bow base mappings, loot lane, seeded pigment and shared halo anchors")
    quit(0)

func _fail(reason: String) -> void:
    push_error(reason)
    quit(1)
