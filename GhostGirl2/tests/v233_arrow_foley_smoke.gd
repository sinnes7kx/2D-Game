extends SceneTree
const ARROW = preload("res://scripts/arrow_impact_audio_v233.gd")
const JUICE = preload("res://scripts/combat_juice_v194.gd")
const GAME = preload("res://scripts/game.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var node: Node2D = Node2D.new()
    root.add_child(node)
    var child: Node2D = Node2D.new()
    node.add_child(child)
    node.set_meta("arrow_impact_material", "metal")
    if ARROW.material_for(child, "stone") != "metal":
        _fail("Parent material metadata not inherited")
        return
    node.remove_meta("arrow_impact_material")
    node.add_to_group("breakable_cover")
    if ARROW.material_for(child, "stone") != "wood" or ARROW.material_for(null, "flesh") != "flesh":
        _fail("Known material or fallback incorrect")
        return
    var audio_hashes: Dictionary = {}
    for surface in ARROW.MATERIALS:
        var clip: AudioStreamWAV = JUICE._render(ARROW.cue(surface))
        if clip == null or clip.data.size() < 1000 or clip.mix_rate != JUICE.RATE:
            _fail("Missing material audio")
            return
        audio_hashes[hash(clip.data)] = true
    if audio_hashes.size() != 6:
        _fail("Material audio must not reuse identical samples")
        return
    JUICE.set_sound_level(0.0)
    ARROW.play(node, Vector2.ZERO, "wood", false)
    if get_nodes_in_group("ghost_impact_audio").size() != 0:
        _fail("Arrow impact ignored mute")
        return
    JUICE.set_sound_level(1.0)
    var game: Node = GAME.new()
    var original: GhostItemData = load("res://items/dusk_needle.tres") as GhostItemData
    var seen: Dictionary = {}
    for seed in range(1, 4000):
        var item: GhostItemData = game.call("_roll_sword_drop", original, seed) as GhostItemData
        if item != null and str(item.item_id).ends_with("_v233"):
            seen[item.item_id] = true
            if item.icon == null or seed % 7 != 0 or seed % 23 == 0:
                _fail("New base missing icon or outside existing sword lane")
                return
    if seen.size() != 3:
        _fail("Not all new blades are obtainable")
        return
    game.free()
    node.free()
    print("v2.33 PASS: material classification, distinct PCM cues, mute and three existing-class loot bases")
    quit(0)

func _fail(reason: String) -> void:
    push_error(reason)
    quit(1)
