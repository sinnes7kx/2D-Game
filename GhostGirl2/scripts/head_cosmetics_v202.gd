extends Node2D
## v2.04 eye silhouettes and seeded palettes; original body atlases stay untouched.
## "wings" remains the SAVED legacy head-accessory key. "helm" is independent.
## No new item metadata or underlying Ghost Girl atlas edits.
var phase: float = 0.0

func _ready() -> void:
    z_index = 8
    set_process(true)

func _process(delta: float) -> void:
    phase += minf(delta, 0.075)
    if int(phase * 18.0) % 2 == 0:
        queue_redraw()

func _item(slot: String) -> GhostItemInstance:
    var parent_visual: Node = get_parent()
    if parent_visual == null:
        return null
    var inv: Node = parent_visual.get("inventory") as Node
    return inv.get_equipped(slot) if inv != null else null

func _face() -> String:
    var actor: Node = get_parent().get_parent() if get_parent() != null else null
    return str(actor.get("facing_name")) if actor != null else "front"

func _draw() -> void:
    var accessory: GhostItemInstance = _item("wings")
    var crown: GhostItemInstance = _item("helm")
    var face: String = _face()
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
            "v202_rose_horns":
                _draw_horns(accent, face)

# This channel is independent from loot/stat rolls and persists through the
# existing cosmetic UID / seed snapshots, favorites and vault serialization.
const EYE_RNG = preload("res://scripts/cosmetic_rng_v152.gd")
const EYE_VARIANTS: Array[String] = ["moonveil", "cathedral", "starborn", "hollow"]

static func eye_variant_index(seed: int) -> int:
    return posmod(seed, EYE_VARIANTS.size())

static func eye_centers(face: String) -> Array[Vector2]:
    # Original v2.02 spread (+/-9) fell BETWEEN the black pupils.
    # These are Ghost-local anchors; EquipmentVisuals copies Ghost's transform.
    match face:
        "front":
            return [Vector2(-19.0, -72.0), Vector2(19.0, -72.0)]
        "left":
            return [Vector2(-15.0, -72.0)]
        "right":
            return [Vector2(15.0, -72.0)]
    return []

func _eye_ellipse(center: Vector2, radius: Vector2, tint: Color) -> void:
    var points: PackedVector2Array = PackedVector2Array()
    for i in range(25):
        var angle: float = TAU * float(i) / 24.0
        points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
    draw_colored_polygon(points, tint)

func _draw_eyes(item: GhostItemInstance, face: String) -> void:
    var centers: Array[Vector2] = eye_centers(face)
    if centers.is_empty():
        return
    var variant: int = eye_variant_index(item.visual_seed())
    var colors: Array[Color] = EYE_RNG.gradient_for_channel(
        item.cosmetic_uid, item.visual_seed(), "head-eyes-v204", item.gradient_version)
    var primary: Color = EYE_RNG.sample_palette(colors, 0.23)
    var secondary: Color = EYE_RNG.sample_palette(colors, 0.78)
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
