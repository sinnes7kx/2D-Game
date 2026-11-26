extends SceneTree
const POSE = preload("res://scripts/v172_weapon_pose.gd")
const HAND = preload("res://scripts/dagger_thrust_v186.gd")
const BLUNT = preload("res://scripts/blunt_weapon_family_v203.gd")
const HEAD = preload("res://scripts/head_cosmetics_v202.gd")

func _initialize() -> void:
    for face in ["front", "back", "left", "right"]:
        for frame in range(8):
            var wrist: Vector2 = HAND.hand_anchor(face, POSE.polearm_sequence()[frame], 0 if face == "left" else 1)
            for heavy in [false, true]:
                var span: PackedVector2Array = POSE.pierce_span(face, frame, heavy)
                if wrist == Vector2.INF:
                    if not span.is_empty():
                        _fail("Occluded wrist has detached polearm")
                        return
                elif span.size() != 2 or span[0] != wrist or not is_equal_approx(span[0].distance_to(span[1]), 74.0):
                    _fail("Polearm wrist or shaft length changed")
                    return
        if HEAD.halo_center(face, "idle_" + face, 0, false).y >= -80.0:
            _fail("Halo below head")
            return
    for kind in ["mace", "morningstar", "flail"]:
        var outline: PackedVector2Array = BLUNT.head_outline(Vector2.ZERO, Vector2.RIGHT, kind)
        if outline.size() < 8:
            _fail("Missing forged outline")
            return
        for point in outline:
            if point.length() > 16.0:
                _fail("Oversized blunt head")
                return
    var variants: Dictionary = {}
    for seed in range(20):
        variants[HEAD.halo_variant(seed)] = true
    if variants.size() != 5:
        _fail("Missing seeded halo variants")
        return
    var source: String = FileAccess.get_file_as_string("res://scripts/player.gd")
    if not source.contains('elif active_attack_style == "spear":') or not source.contains('["dagger", "dual_dagger", "spear"] else "_heavy_"'):
        _fail("Ground or airborne spear route missing")
        return
    print("v2.32 PASS: wrist-aligned thrusts, compact shared head geometry and seeded halo")
    quit(0)

func _fail(reason: String) -> void:
    push_error(reason)
    quit(1)
