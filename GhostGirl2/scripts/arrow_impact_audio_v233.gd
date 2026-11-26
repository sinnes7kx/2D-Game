extends RefCounted
## Presentation only. Use explicit metadata and known material groups, never
## additional collision queries. Untagged enemies/world use soft/stone defaults.
const JUICE = preload("res://scripts/combat_juice_v194.gd")
const MATERIALS: Array[String] = ["flesh", "wood", "stone", "metal", "water", "magic"]

static func material_for(target: Object, fallback: String) -> String:
    if not is_instance_valid(target):
        return fallback if fallback in MATERIALS else "stone"
    var node: Node = target as Node
    if node == null:
        return fallback if fallback in MATERIALS else "stone"
    for depth in range(3):
        if node == null:
            break
        var tagged: String = str(node.get_meta("arrow_impact_material", ""))
        if tagged in MATERIALS:
            return tagged
        for kind in MATERIALS:
            if node.is_in_group("arrow_material_" + kind):
                return kind
        if node.is_in_group("breakable_cover"):
            return "wood"
        if node.is_in_group("water_body"):
            return "water"
        if node.is_in_group("moon_archery_targets") or node.is_in_group("v138_arrow_targets"):
            return "magic"
        if node.is_in_group("enemies"):
            return "flesh"
        node = node.get_parent()
    return fallback if fallback in MATERIALS else "stone"

static func cue(surface: String) -> String:
    return "arrow_" + (surface if surface in MATERIALS else "stone")

static func play(parent: Node, where: Vector2, surface: String, charged: bool) -> void:
    JUICE.play(parent, where, cue(surface), -13.5 if charged else -16.0)
