extends SceneTree
## Visual regression: idle must have 8 smooth transition frames, not two jumps.
const STEADY = preload("res://scripts/steady_weapon_idles_v195.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var original: PackedByteArray = PackedByteArray([255, 20, 10, 255])
    var alternate: PackedByteArray = PackedByteArray([10, 20, 255, 255])
    var tones: Dictionary = {}
    for mix in STEADY.BLEND_STEPS:
        var out: PackedByteArray = STEADY._mix_rgba(original, alternate, float(mix))
        if out.size() != 4 or out[3] != 255:
            _fail("RGBA frame blend damaged opacity")
            return
        tones[str(out[0]) + ":" + str(out[2])] = true
    if tones.size() != 8:
        _fail("Eight idle transitions are not distinct")
        return

    var actor: Node = (load("res://scenes/player.tscn") as PackedScene).instantiate()
    root.add_child(actor)
    var body: AnimatedSprite2D = actor.get_node("Ghost") as AnimatedSprite2D
    var frames: SpriteFrames = body.sprite_frames
    var checked: int = 0
    var families: Array[String] = ["sword_idle_", "dagger_idle_", "nocturne_dagger_idle_", "briarwake_spear_idle_", "spear_idle_", "thornrose_idle_", "moonveil_idle_"]
    for prefix in families:
        for face in ["front", "back", "left", "right"]:
            var name: String = prefix + face
            var expected: int = STEADY.SWORD_STEPS if STEADY.is_smooth_blade_idle(name) else 8
            if not frames.has_animation(name) or frames.get_frame_count(name) != expected:
                _fail("Missing stabilized idle frames: " + name)
                return
            if not frames.get_animation_loop(name):
                _fail("Idle does not loop: " + name)
                return
            var refs: Dictionary = {}
            var total: float = 0.0
            for i in range(expected):
                var texture: Texture2D = frames.get_frame_texture(name, i)
                if texture == null or texture.get_size() != Vector2(256, 220):
                    _fail("Invalid idle texture dimensions: " + name)
                    return
                refs[texture.get_instance_id()] = true
                total += frames.get_frame_duration(name, i)
            if refs.size() != expected:
                _fail("Idle has repeated frame references: " + name)
                return
            if not is_equal_approx(total / frames.get_animation_speed(name), STEADY.CYCLE_SECONDS):
                _fail("Idle cycle duration not stabilized: " + name)
                return
            var second: Texture2D = frames.get_frame_texture(name, 2)
            STEADY.install(body)
            if frames.get_frame_texture(name, 2) != second:
                _fail("Idle patch is not idempotent")
                return
            checked += 1
    if checked != 28 or STEADY.matches("attack_briarwake_spear_heavy_front") or STEADY.matches("thornrose_walk_left"):
        _fail("Wrong animation coverage")
        return
    print("v1.96 PASS: 28 four-direction idle loops, 16 sword-and-dagger / 8 other generated frames, steady 3.45s cycle, no attack/walk changes")
    actor.free()
    quit(0)

func _fail(message: String) -> void:
    push_error(message)
    quit(1)
