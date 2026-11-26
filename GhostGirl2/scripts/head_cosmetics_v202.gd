extends Node2D
## v2.04 eye silhouettes and seeded palettes; original body atlases stay untouched.
## "wings" remains the SAVED legacy head-accessory key. "helm" is independent.
## No new item metadata or underlying Ghost Girl atlas edits.
const WALK_V223 = preload("res://scripts/walk_inbetweens_v223.gd")
const SWORD_V224 = preload("res://scripts/sword_attack_frames_v224.gd")
var phase: float = 0.0
var last_eye_pose_key: String = ""
var last_effect_bucket: int = -1
var had_head_art: bool = false
const HALO_FX = preload("res://scripts/fx_intensity_v1924.gd")
const HALO_ROLL = preload("res://scripts/collector_appearance_v177.gd")
var halo_fx_key: String = ""
var halo_fx_look: Dictionary = {}
var halo_key: String = ""
var halo_look: Dictionary = {}

func _ready() -> void:
    z_index = 8
    # The parent accessory layer is additive. Solid eyes need normal mixing
    # to cover the original pupils instead of drawing translucent green marks.
    var ink_material: CanvasItemMaterial = CanvasItemMaterial.new()
    ink_material.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
    material = ink_material
    set_process(true)

func _process(delta: float) -> void:
    phase += minf(delta, 0.075)
    var body: AnimatedSprite2D = _body_sprite()
    var key: String = (str(body.animation) + ":" + str(body.frame)) if body != null else ""
    var has_art: bool = _item("wings") != null or _item("helm") != null or _item("trinket") != null or _item("charm") != null
    var bucket: int = floori(phase * 18.0)
    if (has_art and (key != last_eye_pose_key or bucket != last_effect_bucket)) or has_art != had_head_art:
        queue_redraw()
    last_eye_pose_key = key
    last_effect_bucket = bucket
    had_head_art = has_art

func _item(slot: String) -> GhostItemInstance:
    var parent_visual: Node = get_parent()
    if parent_visual == null:
        return null
    var inv: Node = parent_visual.get("inventory") as Node
    return inv.get_equipped(slot) if inv != null else null

func _body_sprite() -> AnimatedSprite2D:
    var actor: Node = get_parent().get_parent() if get_parent() != null else null
    if actor == null:
        return null
    return actor.get_node_or_null("Ghost") as AnimatedSprite2D

func _face() -> String:
    var sprite: AnimatedSprite2D = _body_sprite()
    if sprite != null:
        for suffix in ["front", "left", "right", "back"]:
            if str(sprite.animation).ends_with("_" + suffix):
                return suffix
    var actor: Node = get_parent().get_parent() if get_parent() != null else null
    return str(actor.get("facing_name")) if actor != null else "front"

func _draw() -> void:
    var accessory: GhostItemInstance = _item("wings")
    var crown: GhostItemInstance = _item("helm")
    var face: String = _face()
    var charm: GhostItemInstance = _item("trinket")
    if charm == null:
        charm = _item("charm")
    if charm != null and (accessory == null or accessory.definition == null or str(accessory.definition.item_id) != "v202_crescent_halo"):
        _draw_seeded_halo(charm, face, crown != null)
    if crown != null and crown.definition != null:
        _draw_crown(str(crown.definition.item_id), crown.palette_color(), face)
    if accessory != null and accessory.definition != null:
        var id: String = str(accessory.definition.item_id)
        var accent: Color = accessory.palette_color().lerp(Color("e1d2ef"), 0.35)
        match id:
            "v202_luminous_eyes":
                _draw_eyes(accessory, face)
            "v202_bandit_mask":
                _draw_mask(accent, face)
            "v202_crescent_halo":
                _draw_halo(accent, face)
                var halo_x: float = 0.0 if face in ["front", "back"] else (4.0 if face == "right" else -4.0)
                _draw_halo_fx(accessory, Vector2(halo_x, -118.0), Vector2(22.0, 22.0))
            "v202_rose_horns":
                _draw_horns(accent, face)

# This channel is independent from loot/stat rolls and persists through the
# existing cosmetic UID / seed snapshots, favorites and vault serialization.
const EYE_RNG = preload("res://scripts/cosmetic_rng_v152.gd")
const EYE_VARIANTS: Array[String] = ["moonveil", "cathedral", "starborn", "hollow"]

static func eye_variant_index(seed: int) -> int:
    return posmod(seed, EYE_VARIANTS.size())

static func eye_centers(face: String) -> Array[Vector2]:
    # Centered 256x220 Ghost-local coordinates calibrated against the
    # real dark pupils in the supplied equipment screenshot. The old
    # centers were approx. 18px screen-space left and 17px too low.
    match face:
        "front":
            return [Vector2(9.0, -43.0), Vector2(37.0, -43.0)]
        "left":
            return [Vector2(8.0, -42.0)]
        "right":
            return [Vector2(32.0, -42.0)]
    return []

static func pose_eye_centers(animation_name: String, frame_index: int, face: String) -> Array[Vector2]:
    # Track head translation in the approved frame-authored clips. This
    # changes overlay coordinates only, not the original face pixels.
    var base: Array[Vector2] = eye_centers(face)
    if base.is_empty():
        return base
    var frame: int = clampi(frame_index, 0, 7)
    # Dodge has 16 authored poses; its eye guide contains eight beats.
    if animation_name.begins_with("dodge_"):
        frame = clampi(roundi(float(frame_index) * 7.0 / 15.0), 0, 7)
    var offset: Vector2 = Vector2.ZERO
    if animation_name.contains("walk"):
        var dx: Array[float] = [-1.0, 0.0, 1.0, 2.0, 1.0, 0.0, -1.0, -1.0]
        var dy: Array[float] = [0.0, 1.0, 1.5, 0.5, 0.0, -1.0, -1.0, 0.0]
        offset = Vector2(dx[frame], dy[frame])
    elif animation_name.begins_with("attack_") or animation_name.begins_with("wand_cast_") or animation_name.contains("_heavy_") or animation_name.contains("_light_"):
        var dx: Array[float] = [0.0, 1.0, 2.0, 2.0, 1.0, 0.0, -1.0, 0.0]
        var dy: Array[float] = [0.0, -1.0, -2.0, -3.0, -2.0, -1.0, 0.0, 0.0]
        offset = Vector2(dx[frame] * (-1.0 if face == "left" else 1.0), dy[frame])
    elif animation_name.contains("dodge") or animation_name.contains("air_") or animation_name.contains("jump"):
        offset = Vector2(0.0, [-1.0, -2.0, -3.0, -4.0, -3.0, -2.0, -1.0, 0.0][frame])
    else:
        offset.y = [0.0, 0.0, 0.5, 0.5, 0.0, -0.5, -0.5, 0.0][frame]
    var result: Array[Vector2] = []
    for center in base:
        result.append(center + offset)
    return result

func _eye_ellipse(center: Vector2, radius: Vector2, tint: Color) -> void:
    var points: PackedVector2Array = PackedVector2Array()
    for i in range(25):
        var angle: float = TAU * float(i) / 24.0
        points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
    draw_colored_polygon(points, tint)

func _draw_eyes(item: GhostItemInstance, face: String) -> void:
    var sprite: AnimatedSprite2D = _body_sprite()
    var index: int = WALK_V223.source_pose_index(sprite.sprite_frames, str(sprite.animation), sprite.frame) if sprite != null else 0
    if sprite != null:
        index = SWORD_V224.source_pose_index(sprite.sprite_frames, str(sprite.animation), index)
    var centers: Array[Vector2] = pose_eye_centers(str(sprite.animation), index, face) if sprite != null else eye_centers(face)
    if centers.is_empty():
        return
    var variant: int = item.eye_style_override if item.eye_style_override >= 0 else eye_variant_index(item.visual_seed())
    var colors: Array[Color] = EYE_RNG.gradient_for_channel(
        item.cosmetic_uid, item.visual_seed(), "head-eyes-v204", item.gradient_version)
    var primary: Color = EYE_RNG.sample_palette(colors, 0.23)
    var secondary: Color = EYE_RNG.sample_palette(colors, 0.78)
    if item.eye_palette_override >= 0:
        var accents: Array[Color] = [Color("dbb5f7"), Color("ed7cb0"), Color("86aafc"), Color("77d3b5"), Color("e4c578"), Color("a6a1b9")]
        primary = accents[clampi(item.eye_palette_override, 0, accents.size() - 1)]
        secondary = primary.lerp(Color.WHITE, 0.48)
    # A readable pale contour even when the seeded palette rolls very dark.
    var rim: Color = primary.lerp(Color("eaf2ff"), 0.58)
    var pupil: Color = secondary.lerp(Color.WHITE, 0.38)
    var pulse: float = 0.94 + 0.06 * sin(phase * (1.3 + float(variant) * 0.23))
    for center in centers:
        # Solid opaque backing hides the original black eyes in the *same*
        # coordinate space; glow is applied only to the outlines, not the mask.
        _eye_ellipse(center, Vector2(11.7, 8.7), Color("15101e"))
        _eye_ellipse(center, Vector2(10.7, 7.6), rim.darkened(0.64))
        _eye_ellipse(center, Vector2(9.8, 6.5), Color("21192b"))
        match variant:
            0: # Moonveil: wide, watchful irises
                _eye_ellipse(center, Vector2(6.0, 5.5), primary * Color(1, 1, 1, pulse))
                _eye_ellipse(center, Vector2(3.3, 4.1), pupil)
                draw_circle(center + Vector2(-1.0, -1.3), 1.5, Color.WHITE)
            1: # Cathedral: vertical luminous slits
                _eye_ellipse(center, Vector2(6.3, 5.6), primary.darkened(0.25))
                _eye_ellipse(center, Vector2(2.1, 5.5), pupil)
                draw_line(center + Vector2(0, -5), center + Vector2(0, 5), rim, 1.4, true)
            2: # Starborn: tiny four-point stellar gaze
                _eye_ellipse(center, Vector2(5.6, 4.6), primary.darkened(0.35))
                draw_line(center + Vector2(-5.0, 0), center + Vector2(5.0, 0), pupil, 2.0, true)
                draw_line(center + Vector2(0, -5.8), center + Vector2(0, 5.8), pupil, 2.0, true)
                draw_circle(center, 2.1, Color.WHITE)
            3: # Hollow: bright ring around a dark, open center
                draw_arc(center, 5.1, 0.0, TAU, 28, pupil, 2.8, true)
                draw_circle(center, 2.3, Color("100d17"))
                draw_circle(center + Vector2(-2.7, -2.3), 1.1, rim)
        # Delicate readable contour, not a full-screen bloom.
        draw_arc(center, 10.2, 0.05, PI - 0.05, 22, rim, 1.6, true)
        draw_arc(center, 10.2, PI + 0.05, TAU - 0.05, 22, rim, 1.2, true)

func _draw_mask(color: Color, face: String) -> void:
    if face == "back":
        return
    var offset: float = 0.0 if face == "front" else (5.0 if face == "right" else -5.0)
    var w: float = 24.0 if face == "front" else 15.0
    var left: Vector2 = Vector2(offset - w, -73.0)
    var right: Vector2 = Vector2(offset + w, -73.0)
    draw_line(left, right, Color("292431"), 11.0, true)
    draw_line(left + Vector2(1.0, -4.0), right + Vector2(-1.0, -4.0), color.darkened(0.35), 2.3, true)
    for s in [-1.0, 1.0]:
        draw_arc(Vector2(offset + s * w * 0.45, -72.0), 5.2, -PI, 0.0, 14, Color("b8a4b9"), 1.6, true)

func _draw_halo(color: Color, face: String) -> void:
    var shimmer: float = 0.73 + 0.14 * sin(phase * 2.0)
    var x: float = 0.0 if face in ["front", "back"] else (4.0 if face == "right" else -4.0)
    draw_arc(Vector2(x, -118.0), 22.0, -PI, PI, 36, Color(color.r, color.g, color.b, 0.13 * shimmer), 6.0, true)
    draw_arc(Vector2(x, -118.0), 22.0, -PI, PI, 36, Color(color.r, color.g, color.b, 0.90 * shimmer), 2.2, true)
    draw_line(Vector2(x - 5.0, -139.0), Vector2(x + 5.0, -139.0), Color("fff5df"), 1.2, true)

func _draw_horns(color: Color, face: String) -> void:
    for side in [-1.0, 1.0]:
        var base: Vector2 = Vector2(side * 23.0, -101.0)
        var tip: Vector2 = Vector2(side * 39.0, -130.0)
        var mid: Vector2 = Vector2(side * 32.0, -116.0)
        draw_line(base, mid, Color("3a253b"), 8.0, true)
        draw_line(mid, tip, Color("3a253b"), 6.0, true)
        draw_line(base, mid, color.darkened(0.35), 4.5, true)
        draw_line(mid, tip, color.lightened(0.13), 2.8, true)
        draw_circle(base, 3.1, Color("9e718a"))

func _draw_crown(id: String, color: Color, face: String) -> void:
    if id not in ["v202_moonlit_tiara", "v202_starfall_diadem"]:
        return
    var metal: Color = color.lerp(Color("d4b5cf"), 0.35)
    var center: Vector2 = Vector2(0.0, -96.0)
    var base_width: float = 27.0 if face in ["front", "back"] else 17.0
    var left: Vector2 = center + Vector2(-base_width, 1.0)
    var right: Vector2 = center + Vector2(base_width, 1.0)
    draw_arc(center, base_width, PI * 1.08, PI * 1.92, 20, Color("352b37"), 5.8, true)
    draw_arc(center, base_width, PI * 1.08, PI * 1.92, 20, metal, 2.0, true)
    if id == "v202_starfall_diadem":
        draw_line(left, center + Vector2(0, -18), metal, 2.1, true)
        draw_line(center + Vector2(0, -18), right, metal, 2.1, true)
        draw_circle(center + Vector2(0, -18), 3.3, Color("e7d2ed"))
    else:
        draw_line(left, center + Vector2(0, -11), metal, 1.8, true)
        draw_line(center + Vector2(0, -11), right, metal, 1.8, true)
        draw_circle(center + Vector2(0, -11), 2.7, Color("ecd3df"))


# Independent cosmetic channel; never change a saved charm, its affixes,
# equipment slot, or its collectible identity.
static func halo_variant(seed: int) -> int:
    return posmod(seed, 5)

static func halo_center(face: String, animation: String, source_frame: int, crown: bool) -> Vector2:
    var reference_face: String = "front" if face == "back" else face
    var neutral: Array[Vector2] = eye_centers(reference_face)
    var moving: Array[Vector2] = pose_eye_centers(animation, source_frame, reference_face)
    var drift: Vector2 = moving[0] - neutral[0] if not moving.is_empty() and not neutral.is_empty() else Vector2.ZERO
    var x: float = 15.0
    if face == "left":
        x = 11.0
    elif face == "right":
        x = 20.0
    return Vector2(x, -96.0 - (13.0 if crown else 0.0)) + drift

static func body_halo_center(sprite: AnimatedSprite2D, face: String, crown: bool) -> Vector2:
    var animation: String = str(sprite.animation) if sprite != null else "idle_" + face
    var index: int = WALK_V223.source_pose_index(sprite.sprite_frames, animation, sprite.frame) if sprite != null else 0
    if sprite != null:
        index = SWORD_V224.source_pose_index(sprite.sprite_frames, animation, index)
    return halo_center(face, animation, index, crown)

func _draw_seeded_halo(item: GhostItemInstance, face: String, crown: bool) -> void:
    var key: String = "%s:%d:%d" % [item.cosmetic_uid, item.visual_seed(), item.gradient_version]
    if halo_key != key:
        halo_key = key
        var palette: Array[Color] = EYE_RNG.gradient_for_channel(item.cosmetic_uid, item.visual_seed(), "accessory-halo-v232", item.gradient_version)
        halo_look = {"kind": halo_variant(item.visual_seed()), "metal": EYE_RNG.sample_palette(palette, 0.25).lerp(Color("b8a8b9"), 0.52), "edge": EYE_RNG.sample_palette(palette, 0.72).lerp(Color("f4e5df"), 0.48)}
    var center: Vector2 = body_halo_center(_body_sprite(), face, crown)
    var metal: Color = halo_look["metal"]
    var edge: Color = halo_look["edge"]
    var kind: int = int(halo_look["kind"])
    var radius: Vector2 = Vector2(23.0 if face in ["front", "back"] else 19.0, 7.0)
    _draw_halo_fx(item, center, radius)
    var segments: int = 36
    var points: PackedVector2Array = PackedVector2Array()
    for i in range(segments + 1):
        var angle: float = TAU * float(i) / float(segments)
        var at: Vector2 = center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y)
        if kind == 1 and i in [5, 6, 7, 8, 23, 24, 25]:
            if points.size() > 1:
                draw_polyline(points, metal.darkened(0.35), 2.5, true)
                draw_polyline(points, edge, 1.0, true)
            points.clear()
        else:
            points.append(at)
    if points.size() > 1:
        draw_polyline(points, metal.darkened(0.35), 2.5, true)
        draw_polyline(points, edge, 1.0, true)
    if kind == 2 or kind == 4:
        for i in range(6 if kind == 2 else 4):
            var angle: float = TAU * float(i) / float(6 if kind == 2 else 4)
            var at: Vector2 = center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y)
            var outward: Vector2 = Vector2(cos(angle), sin(angle))
            draw_line(at, at + outward * (4.0 if kind == 2 else 2.5), edge, 1.0, true)
    elif kind == 3:
        var inner: PackedVector2Array = PackedVector2Array()
        for i in range(19):
            var angle: float = PI * float(i) / 18.0
            inner.append(center + Vector2(cos(angle) * (radius.x - 2.0), sin(angle) * (radius.y - 2.0)))
        draw_polyline(inner, metal.lightened(0.22), 1.2, true)

# Seeded, bounded decorative halo effects. The ring remains visible at FX Off.
func _draw_halo_fx(item: GhostItemInstance, center: Vector2, radius: Vector2) -> void:
    if HALO_FX.intensity <= 0.0:
        return
    var key: String = "%s:%d:%d" % [item.cosmetic_uid, item.visual_seed(), item.gradient_version]
    if halo_fx_key != key:
        halo_fx_key = key
        halo_fx_look = HALO_ROLL.roll(item.cosmetic_uid, item.visual_seed(), item.gradient_version)
    var tier: int = int(halo_fx_look.get("particle_tier", 0))
    var motif: int = int(halo_fx_look.get("glow_motif", 0))
    if OS.is_debug_build() and item.debug_collector_tier >= 0:
        tier = item.debug_collector_tier
    if OS.is_debug_build() and item.debug_glow_motif >= 0:
        motif = item.debug_glow_motif
    var ink: Color = item.palette_color().lerp(Color("f3d9ff"), 0.32)
    var spread: Vector2 = radius + Vector2(4.0 + tier, 3.0 + tier)
    for i in range(3 + tier):
        var a: float = phase * (1.1 + tier * 0.17) + TAU * float(i) / float(3 + tier)
        var at: Vector2 = center + Vector2(cos(a) * spread.x, sin(a) * spread.y)
        var alpha: float = HALO_FX.alpha(0.40 + 0.18 * sin(a * 2.0))
        var light: Color = Color(ink.r, ink.g, ink.b, alpha)
        draw_circle(at, 3.5 + tier * 0.3, Color(ink.r, ink.g, ink.b, alpha * 0.12))
        if motif % 3 == 0:
            draw_line(at - Vector2(2.0, 0), at + Vector2(2.0, 0), light, 0.8, true)
            draw_line(at - Vector2(0, 2.0), at + Vector2(0, 2.0), light, 0.8, true)
        elif motif % 3 == 1:
            draw_arc(at, 2.1, a, a + PI, 8, light, 0.9, true)
        else:
            draw_circle(at, 1.1 + tier * 0.12, light)
    if tier >= 4:
        var arc: PackedVector2Array = PackedVector2Array()
        for i in range(25):
            var a: float = phase * 0.7 + float(i) * PI / 24.0
            arc.append(center + Vector2(cos(a) * spread.x, sin(a) * spread.y))
        draw_polyline(arc, Color(ink.r, ink.g, ink.b, HALO_FX.alpha(0.35)), 1.2, true)
