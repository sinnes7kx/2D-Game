extends RefCounted
## v2.03: explicit airborne attack clips for every equipped weapon family,
## including bows and the unarmed/wand fallback. No duplicate hitboxes:
## this only re-times *the same eight approved directional pose frames*.
## Names insert "_air_" before facing, preserving weapon renderer prefixes,
## _heavy_ checks and trailing front/back/left/right.
const AIR_DURATIONS: Array[float] = [1.36, 0.90, 0.72, 0.65, 0.86, 1.09, 1.22, 1.34]
const FACINGS: Array[String] = ["front", "back", "left", "right"]

static func air_name(normal: String) -> String:
    for face in FACINGS:
        var suffix: String = "_" + face
        if normal.ends_with(suffix):
            return normal.trim_suffix(suffix) + "_air" + suffix
    return normal

static func base_name(air: String) -> String:
    for face in FACINGS:
        var suffix: String = "_air_" + face
        if air.ends_with(suffix):
            return air.trim_suffix(suffix) + "_" + face
    return air

static func install(sprite: AnimatedSprite2D) -> void:
    if sprite == null or sprite.sprite_frames == null:
        return
    var frames: SpriteFrames = sprite.sprite_frames
    if bool(frames.get_meta("v203_air_attacks_installed", false)):
        return
    for original in frames.get_animation_names():
        var name: String = str(original)
        if not name.begins_with("attack_") or not name.contains("_heavy_"):
            continue
        var target: String = air_name(name)
        if name == target or frames.has_animation(target) or frames.get_frame_count(name) < 8:
            continue
        frames.add_animation(target)
        frames.set_animation_speed(target, frames.get_animation_speed(name))
        frames.set_animation_loop(target, false)
        # New airborne tempo without shifting the art relative to actual wrist
        # guides. Heavy-frame poses 3-5 get a quick plunging impact beat.
        for i in range(8):
            frames.add_frame(target, frames.get_frame_texture(name, i), AIR_DURATIONS[i])
    frames.set_meta("v203_air_attacks_installed", true)

static func airborne_pose(progress: float, airborne_strike: bool, direction: float) -> Dictionary:
    var t: float = clampf(progress, 0.0, 1.0)
    var arc: float = sin(t * PI)
    # Distinct mid-air wind-up, compression and forward-facing followthrough.
    var plunge: float = pow(clampf((t - 0.20) / 0.56, 0.0, 1.0), 1.35)
    var turn: float = direction
    return {
        "height": 34.0 * arc + (5.0 * arc if airborne_strike else 0.0) - (4.0 * plunge if airborne_strike else 0.0),
        "rotation": (0.095 * sin(clampf((t - 0.10) / 0.72, 0.0, 1.0) * PI) * turn if airborne_strike else 0.018 * turn),
        "stretch": (0.025 * arc if airborne_strike else 0.012 * arc),
        "arc": arc
    }
