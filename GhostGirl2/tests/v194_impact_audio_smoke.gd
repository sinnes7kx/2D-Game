extends SceneTree
const JUICE = preload("res://scripts/combat_juice_v194.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    for cue in ["swing", "hit", "parry", "dodge", "spell", "spell_heavy", "spell_release", "spell_release_heavy", "spell_hit", "debris", "evade"]:
        var clip: AudioStreamWAV = JUICE._render(cue)
        if clip == null or clip.data.size() < 1000 or clip.mix_rate != 22050:
            _fail("Missing or malformed generated cue: " + cue)
            return
    JUICE.set_sound_level(0.0)
    JUICE.set_shake_level(0.0)
    if JUICE.sound_level != 0.0 or JUICE.shake_level != 0.0:
        _fail("Accessibility mute/shake-off setting failed")
        return
    var world: Node2D = Node2D.new()
    root.add_child(world)
    JUICE.play(world, Vector2.ZERO, "hit")
    if get_nodes_in_group("ghost_impact_audio").size() != 0:
        _fail("Muted cues spawned voices")
        return
    JUICE.set_sound_level(1.0)
    JUICE.set_shake_level(1.0)
    JUICE.play(world, Vector2.ZERO, "hit")
    if get_nodes_in_group("ghost_impact_audio").size() != 1:
        _fail("Audible cue did not spawn exactly one voice")
        return
    world.queue_free()
    print("v1.94 PASS: generated combat audio, mute, shake settings, and one-shot gating")
    quit(0)

func _fail(message: String) -> void:
    push_error(message)
    quit(1)
