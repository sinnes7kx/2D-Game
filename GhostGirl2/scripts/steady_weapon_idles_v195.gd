extends RefCounted
## v1.95 — steady eight-step idle presentation for baked sword, polearm and bows.
## Existing artwork is the source: the approved neutral silhouette is locked,
## while restrained interior-paint in-betweens soften abrupt two-pose jumps.
## No animation manifest, source PNG, hitbox, equipment or save data is changed.
const CYCLE_SECONDS: float = 3.45
const STEPS: int = 8
const SWORD_STEPS: int = 24 # Procedural interior-paint in-betweens; original silhouette stays fixed.
const BLEND_STEPS: Array = [0.0, 0.024, 0.055, 0.095, 0.145, 0.112, 0.069, 0.027]
static var _textures_by_key: Dictionary = {}
static var _atlas_images: Dictionary = {}

static func matches(name: String) -> bool:
    return name.begins_with("sword_idle_") or name.begins_with("dagger_idle_") or name.begins_with("nocturne_dagger_idle_") or name.begins_with("spear_idle_") \
        or name.begins_with("briarwake_spear_idle_") \
        or name.begins_with("thornrose_idle_") or name.begins_with("moonveil_idle_")

static func is_smooth_blade_idle(name: String) -> bool:
    return name.begins_with("sword_idle_") or name.begins_with("dagger_idle_") or name.begins_with("nocturne_dagger_idle_")

static func is_bow_idle(name: String) -> bool:
    return name.begins_with("thornrose_idle_") or name.begins_with("moonveil_idle_")

static func install(sprite: AnimatedSprite2D) -> void:
    if sprite == null or sprite.sprite_frames == null:
        return
    var frames: SpriteFrames = sprite.sprite_frames
    if bool(frames.get_meta("v195_stable_idle_installed", false)):
        return
    for value in frames.get_animation_names():
        var name: String = str(value)
        if not matches(name) or not frames.get_animation_loop(name) or frames.get_frame_count(name) < STEPS:
            continue
        var neutral: Texture2D = frames.get_frame_texture(name, 0)
        # v1.75 left-bow body has source frame 1 at slot 2, while
        # slot 3 is the neutral pose again. Without this, all blends are static.
        var alternate_index: int = 2 if is_bow_idle(name) and name.ends_with("_left") else 3
        var alternate: Texture2D = frames.get_frame_texture(name, alternate_index)
        if neutral == null or alternate == null:
            continue
        var key: String = "%s:%d:%d" % [name, neutral.get_rid().get_id(), alternate.get_rid().get_id()]
        var requested_steps: int = SWORD_STEPS if is_smooth_blade_idle(name) else STEPS
        key += ":%d" % requested_steps
        var generated: Array = _textures_by_key.get(key, [])
        if generated.is_empty():
            generated = _create_steps(neutral, alternate, requested_steps)
            if generated.size() != requested_steps:
                push_warning("v1.95 could not smooth " + name + "; original frames retained")
                continue
            _textures_by_key[key] = generated
        if requested_steps == SWORD_STEPS:
            # Rebuild only blade idles; attacks, walks and
            # every original source frame remain untouched in project files.
            for i in range(STEPS):
                frames.set_frame(name, i, generated[i] as Texture2D, 1.0)
            for i in range(STEPS, SWORD_STEPS):
                frames.add_frame(name, generated[i] as Texture2D, 1.0)
            frames.set_animation_speed(name, float(SWORD_STEPS) / CYCLE_SECONDS)
        else:
            var total_duration: float = 0.0
            for i in range(STEPS):
                var duration: float = frames.get_frame_duration(name, i)
                total_duration += duration
                frames.set_frame(name, i, generated[i] as Texture2D, duration)
            frames.set_animation_speed(name, total_duration / CYCLE_SECONDS)
    _atlas_images.clear() # Do not keep large decompressed 2048x1760 atlases.
    frames.set_meta("v195_stable_idle_installed", true)

static func _source_image(texture: Texture2D) -> Image:
    if texture is AtlasTexture:
        var tile: AtlasTexture = texture as AtlasTexture
        if tile.atlas == null:
            return null
        var key: int = tile.atlas.get_rid().get_id()
        if not _atlas_images.has(key):
            _atlas_images[key] = tile.atlas.get_image()
        var whole: Image = _atlas_images[key] as Image
        if whole == null or whole.is_empty():
            return null
        if whole.is_compressed():
            whole.decompress()
        var region: Rect2i = Rect2i(Vector2i(tile.region.position), Vector2i(tile.region.size))
        if region.position.x < 0 or region.position.y < 0 or region.end.x > whole.get_width() or region.end.y > whole.get_height():
            return null
        return whole.get_region(region)
    return texture.get_image()

static func _create_steps(neutral: Texture2D, alternate: Texture2D, steps: int = STEPS) -> Array[Texture2D]:
    var base: Image = _source_image(neutral)
    var breath: Image = _source_image(alternate)
    var results: Array[Texture2D] = []
    if base == null or breath == null or base.is_empty() or breath.is_empty() or base.get_size() != breath.get_size():
        return results
    if base.is_compressed():
        base.decompress()
    if breath.is_compressed():
        breath.decompress()
    base.convert(Image.FORMAT_RGBA8)
    breath.convert(Image.FORMAT_RGBA8)
    var original: PackedByteArray = base.get_data()
    var other: PackedByteArray = breath.get_data()
    if original.size() != other.size():
        return results
    results.append(neutral) # Exact approved pixels on the resting beat.
    for i in range(1, steps):
        var amount: float = float(BLEND_STEPS[i]) if steps == STEPS else 0.18 * (0.5 - 0.5 * cos(TAU * float(i) / float(steps)))
        var blended: PackedByteArray = _mix_rgba(original, other, amount)
        var image: Image = Image.create_from_data(base.get_width(), base.get_height(), false, Image.FORMAT_RGBA8, blended)
        results.append(ImageTexture.create_from_image(image))
    return results

static func _mix_rgba(base: PackedByteArray, other: PackedByteArray, mix: float) -> PackedByteArray:
    var out: PackedByteArray = base.duplicate()
    var weight: float = clampf(mix, 0.0, 0.2)
    for p in range(0, base.size(), 4):
        # Lock approved blade/bow/trident contours and all transparency:
        # never crossfade a silhouette or draw a faint second weapon edge.
        if base[p + 3] < 232 or other[p + 3] < 232:
            continue
        # Only softly interpolate opaque interior paint/breathing details.
        # The original alpha, outline and weapon alignment are pixel-stable.
        for channel in range(3):
            if base[p + channel] != other[p + channel]:
                out[p + channel] = clampi(roundi(lerpf(float(base[p + channel]), float(other[p + channel]), weight)), 0, 255)
    return out
