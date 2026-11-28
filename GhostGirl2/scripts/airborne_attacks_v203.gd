extends RefCounted
## v2.03: explicit airborne attack clips for every equipped weapon family,
## including bows and the unarmed/wand fallback. No duplicate hitboxes:
## this only re-times *the same eight approved directional pose frames*.
## Names insert "_air_" before facing, preserving weapon renderer prefixes,
## _heavy_ checks and trailing front/back/left/right.
const AIR_DURATIONS: Array[float] = [1.36, 0.90, 0.72, 0.65, 0.86, 1.09, 1.22, 1.34]
const FACINGS: Array[String] = ["front", "back", "left", "right"]
const ALL_FACINGS: Array[String] = ["front_right", "front_left", "back_left", "back_right", "front", "back", "left", "right"]

static func air_name(normal: String) -> String:
    if normal.contains("_air_"):
        return normal
    for face in ALL_FACINGS:
        var suffix: String = "_" + face
        if normal.ends_with(suffix):
            return normal.trim_suffix(suffix) + "_air" + suffix
    return normal

static func base_name(air: String) -> String:
    for face in ALL_FACINGS:
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
    # Wands use the approved unarmed action body plus their separate frame-
    # authored wand layer. Give them a real named aerial clip as well.
    for face in FACINGS:
        var source: String = "attack_unarmed_heavy_" + face
        var wand_ground: String = "attack_wand_heavy_" + face
        if frames.has_animation(source) and not frames.has_animation(wand_ground):
            frames.add_animation(wand_ground)
            frames.set_animation_speed(wand_ground, frames.get_animation_speed(source))
            frames.set_animation_loop(wand_ground, false)
            for i in range(mini(8, frames.get_frame_count(source))):
                frames.add_frame(wand_ground, frames.get_frame_texture(source, i), frames.get_frame_duration(source, i))
    for original in frames.get_animation_names():
        var name: String = str(original)
        if not name.begins_with("attack_") or not (name.contains("_heavy_") or name.begins_with("attack_thornrose_light_") or name.begins_with("attack_moonveil_light_") or name.begins_with("attack_forge_bow_light_")):
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
        "height": maxf(0.0, 25.0 * arc + (4.0 * arc if airborne_strike else 0.0) - (4.0 * plunge if airborne_strike else 0.0)),
        "rotation": (0.095 * sin(clampf((t - 0.10) / 0.72, 0.0, 1.0) * PI) * turn if airborne_strike else 0.018 * turn),
        "stretch": (0.016 * arc if airborne_strike else 0.008 * arc),
        "arc": arc
    }
