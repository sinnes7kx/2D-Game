extends SceneTree
## v2.00: four-facing dual grip and bow-parented cosmetic/charge FX.
const DUAL = preload("res://scripts/v174_dual_swords.gd")
const HAND = preload("res://scripts/dagger_thrust_v186.gd")
const BOW = preload("res://scripts/bow_palette_overlay_v139.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var scene: PackedScene = load("res://scenes/player.tscn") as PackedScene
    var actor: Node2D = scene.instantiate() as Node2D
    root.add_child(actor)
    var body: AnimatedSprite2D = actor.get_node("Ghost") as AnimatedSprite2D
    var mask: AnimatedSprite2D = body.get_node("BowPaletteV139") as AnimatedSprite2D
    var full_color: AnimatedSprite2D = body.get_node("BowCarryV166") as AnimatedSprite2D
    var glow: Node2D = body.get_node("EquippedPrestigeFX") as Node2D
    if body == null or glow == null or mask == null or full_color == null:
        _fail("Missing real game bow, blade or FX nodes")
        return
    for face in ["front", "back", "left", "right"]:
        var idle_pair: Array = DUAL.authored_blade_spans(face, "idle", 0)
        var walk_pair: Array = DUAL.authored_blade_spans(face, "walk", 0)
        if idle_pair.size() != 2 or walk_pair.size() != 2:
            _fail("Dual sword facings lost a hand: " + face)
            return
        if idle_pair[0][0].distance_to(idle_pair[1][0]) < 17.0:
            _fail("Both blades appear anchored to the same hand: " + face)
            return
        for hand in [0, 1]:
            var source: Vector2 = HAND.hand_anchor(face, 0, hand)
            if source != Vector2.INF:
                if idle_pair[hand][0].distance_to(source) > 0.01 or walk_pair[hand][0].distance_to(source) > 0.01:
                    _fail("Visible dual-sword hilt missed the authored hand: " + face)
                    return
        var grip_left: Vector2 = DUAL.hand_grip(face, 0)
        var grip_right: Vector2 = DUAL.hand_grip(face, 1)
        if grip_left == Vector2.INF or grip_right == Vector2.INF:
            _fail("A hidden wrist has no stable fallback: " + face)
            return

    for name in ["thornrose_bow", "moonveil_bow"]:
        var definition: GhostItemData = load("res://items/%s.tres" % name) as GhostItemData
        var equipped: GhostItemInstance = GhostItemGenerator.create(definition, 200001, "rare")
        glow.set("item", equipped)
        glow.call("_sync_transform_parent")
        if glow.get_parent() != mask or glow.position != Vector2.ZERO:
            _fail("Bow FX were not physically parented under BowPaletteV139")
            return
        for face in ["front", "back", "left", "right"]:
            var animation: String = name.trim_suffix("_bow") + "_idle_" + face
            var pose: Dictionary = BOW.idle_hold_pose(face)
            if not mask.call("_show_idle_bow", equipped, animation):
                _fail("Could not show directional idle bow: " + animation)
                return
            if not is_equal_approx(mask.rotation_degrees, full_color.rotation_degrees) or mask.position.distance_to(full_color.position) > 0.01:
                _fail("Full-color bow, mask and child FX transforms disagree")
                return
            if absf(mask.rotation_degrees) < 90.0:
                _fail("Upside-down bow orientation has returned: " + face)
                return
            var handle: Vector2 = pose["position"] + (pose["source_handle"] as Vector2).rotated(deg_to_rad(float(pose["rotation_deg"])))
            if handle.distance_to(pose["hand"]) > 0.01:
                _fail("Bow detached from hand on " + face)
                return
            var p: Vector2 = Vector2(8, -16)
            if glow.to_global(p).distance_to(mask.to_global(p)) > 0.01:
                _fail("FX are not inheriting the bow position/rotation on " + face)
                return
        actor.set("bow_draw_active", true)
        actor.set("bow_draw_time", 0.23)
        if not is_equal_approx(float(glow.call("_bow_charge_progress")), 0.5):
            _fail("The heavy-bow FX does not respond to live charge state")
            return
        actor.set("bow_draw_time", 0.46)
        if not is_equal_approx(float(glow.call("_bow_charge_progress")), 1.0):
            _fail("Fully charged bow FX never reach full intensity")
            return
        actor.set("bow_draw_active", false)
        if float(glow.call("_bow_charge_progress")) != 0.0:
            _fail("Bow charge glow persisted after release")
            return
    var blade: GhostItemInstance = GhostItemGenerator.create(load("res://items/gloamrose_dual_swords_v174.tres") as GhostItemData, 200002, "rare")
    glow.set("item", blade)
    glow.call("_sync_transform_parent")
    if glow.get_parent() != body or glow.position != Vector2.ZERO:
        _fail("Non-bow weapon FX remained under a hidden bow")
        return
    actor.free()
    print("v2.00 PASS: dual sword wrist anchors, 8 upright bow poses, parented FX and live heavy charge")
    quit(0)

func _fail(message: String) -> void:
    push_error(message)
    quit(1)
