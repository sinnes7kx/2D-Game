extends SceneTree
## v1.98 regression: sword air whoosh, longer art-only geometry, four-handed
## bow carry and miss-safe heavy / charged / jump presentation.
const SOUND = preload("res://scripts/combat_juice_v194.gd")
const SCYTHE = preload("res://scripts/scythe_art_v190.gd")
const DAGGER = preload("res://scripts/dagger_thrust_v186.gd")
const DUAL = preload("res://scripts/v173_dual_daggers.gd")
const POSE = preload("res://scripts/v172_weapon_pose.gd")
const BOW = preload("res://scripts/bow_palette_overlay_v139.gd")
const AIR_WAKE = preload("res://scripts/swing_wake_v198.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var durations: Dictionary = {"swing":0.22, "heavy_swing":0.43, "jump_swing":0.49, "charged_swing":0.39}
    for kind in durations:
        var clip: AudioStreamWAV = SOUND._render(kind)
        if clip == null or clip.mix_rate != SOUND.RATE:
            _fail("Missing airy sword sound: " + str(kind))
            return
        var seconds: float = float(clip.data.size()) / (2.0 * float(clip.mix_rate))
        if absf(seconds - float(durations[kind])) > 0.003:
            _fail("Incorrect swing transient duration: " + str(kind))
            return
        var active: bool = false
        for i in range(0, clip.data.size(), 17):
            if clip.data[i] != 0:
                active = true
                break
        if not active:
            _fail("Silent swing: " + str(kind))
            return
    if not is_equal_approx(SCYTHE.REAPER_SPAN, 86.0) or POSE.TRIDENT_SHAFT_BACK < 25.0 or DUAL.BLADE_LENGTH < 34.0:
        _fail("Longer Reaper/trident/paired-dagger art lengths missing")
        return
    var scythe: PackedVector2Array = SCYTHE.span("scythe_idle_right", 0, {})
    if scythe.size() != 2 or not is_equal_approx(scythe[0].distance_to(scythe[1]), SCYTHE.REAPER_SPAN):
        _fail("Reaper shaft length or hand anchor changed unexpectedly")
        return
    var single: PackedVector2Array = DAGGER.single_span("front", 3, false)
    var paired: PackedVector2Array = DAGGER.span("front", 3, 0, false, true)
    if single.size() != 2 or paired.size() != 2 or single[0].distance_to(single[1]) < 31.0 or paired[0].distance_to(paired[1]) < 27.0:
        _fail("Dagger or stiletto blade did not lengthen")
        return
    if not (AIR_WAKE.new() is Node2D):
        _fail("Air wake must stay a visual-only node")
        return

    var player: Node = (load("res://scenes/player.tscn") as PackedScene).instantiate()
    root.add_child(player)
    var body: AnimatedSprite2D = player.get_node("Ghost")
    var palette: AnimatedSprite2D = player.get_node("Ghost/BowPaletteV139")
    var carry: AnimatedSprite2D = player.get_node("Ghost/BowCarryV166")
    for art_name in ["thornrose", "moonveil"]:
        var resource: String = "res://items/%s_bow.tres" % art_name
        var template: GhostItemData = load(resource) as GhostItemData
        if template == null:
            _fail("Missing bow template: " + resource)
            return
        var item: GhostItemInstance = GhostItemGenerator.create(template, 198, "rare")
        for face in ["front", "back", "left", "right"]:
            var anim: String = art_name + "_idle_" + face
            if not body.sprite_frames.has_animation(anim):
                _fail("Bow idle not found: " + anim)
                return
            # No baked second bow underneath the rotated overlay.
            var neutral: Texture2D = body.sprite_frames.get_frame_texture(anim, 0)
            var bare: Texture2D = body.sprite_frames.get_frame_texture("attack_unarmed_light_" + face, 0)
            if neutral != bare:
                _fail("A duplicate baked idle bow remains on Ghost Girl: " + anim)
                return
            var pose: Dictionary = BOW.idle_hold_pose(face)
            var source_pivot: Vector2 = pose["source_handle"]
            var screen_pivot: Vector2 = pose["position"] + source_pivot.rotated(deg_to_rad(float(pose["rotation_deg"])))
            if screen_pivot.distance_to(pose["hand"]) > 0.01:
                _fail("Bow pivot is not on the correct hand: " + face)
                return
            if not palette.call("_show_idle_bow", item, anim):
                _fail("Could not display rotated bow idle: " + anim)
                return
            if not carry.visible or not palette.visible or palette.position.distance_to(carry.position) > 0.01 or not is_equal_approx(palette.rotation_degrees, carry.rotation_degrees):
                _fail("Bow pigment mask and full-color bow are misaligned: " + anim)
                return
            if carry.flip_h != (face == "left") or palette.flip_h != carry.flip_h:
                _fail("Incorrect handedness in bow idle: " + anim)
                return
    # A miss remains presentation-only; no collision shapes or attack logic.
    var code: String = FileAccess.get_file_as_string("res://scripts/player.gd")
    for phrase in ['_emit_air_wake("heavy", attack_direction)', '_emit_air_wake("jump", attack_direction)', '_emit_air_wake("charged", bow_firing_direction)', '_emit_air_wake("charged", spell_direction)']:
        if not code.contains(phrase):
            _fail("Missing committed air cue: " + phrase)
            return
    player.free()
    print("v1.98 PASS: airy swing audio, art-only longer blades, 8 bow hand-aligned idle poses, miss-safe air wakes")
    quit(0)

func _fail(message: String) -> void:
    push_error(message)
    quit(1)
