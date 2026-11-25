extends SceneTree
# Run: godot --headless --path GhostGirl2 --script res://tests/v204_eye_palette_coverage_smoke.gd
const EYES = preload("res://scripts/head_cosmetics_v202.gd")
const RNG = preload("res://scripts/cosmetic_rng_v152.gd")

func _initialize() -> void:
    var errors: Array[String] = []
    for seed in range(128):
        var index: int = EYES.eye_variant_index(seed)
        if index < 0 or index > 3 or index != EYES.eye_variant_index(seed):
            errors.append("Eye style is not stable or in range")
    for face in ["front", "left", "right", "back"]:
        var anchors: Array[Vector2] = EYES.eye_centers(face)
        if (face == "front" and anchors.size() != 2) or (face in ["left", "right"] and anchors.size() != 1) or (face == "back" and not anchors.is_empty()):
            errors.append("Wrong eye visibility in " + face)
        for center in anchors:
            if absf(center.x) < 11.0 or absf(center.y + 72.0) > 0.1:
                errors.append("Eye backing missed facial landmark in " + face)
    var a: Array[Color] = RNG.gradient_for_channel("", 1000, "head-eyes-v204", 1)
    var b: Array[Color] = RNG.gradient_for_channel("", 1000, "head-eyes-v204", 1)
    var c: Array[Color] = RNG.gradient_for_channel("", 1001, "head-eyes-v204", 1)
    if a.is_empty() or a != b or a == c:
        errors.append("Seeded eye color channel is not deterministic or distinct")
    if not errors.is_empty():
        for error in errors:
            push_error(error)
        quit(1)
        return
    print("v2.04 eye variant/anchor/palette smoke: PASS")
    quit(0)
