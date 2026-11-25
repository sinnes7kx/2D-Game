extends Node2D
## v2.02 original frame-compatible head ornament strokes.
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
                _draw_eyes(accent, face)
            "v202_bandit_mask":
                _draw_mask(accent, face)
            "v202_crescent_halo":
                _draw_halo(accent, face)
            "v202_rose_horns":
                _draw_horns(accent, face)

func _draw_eyes(color: Color, face: String) -> void:
    if face == "back":
        return
    var flicker: float = 0.84 + 0.16 * sin(phase * 3.2)
    var spread: float = 9.0 if face == "front" else 5.0
    var offset: float = 0.0 if face == "front" else (4.0 if face == "right" else -4.0)
    for side in [-1.0, 1.0]:
        var p: Vector2 = Vector2(offset + side * spread, -72.0)
        draw_circle(p, 5.2, Color(color.r, color.g, color.b, 0.08 * flicker))
        draw_line(p + Vector2(-3.0, 0), p + Vector2(3.0, -0.5), Color(color.r, color.g, color.b, 0.66 * flicker), 1.8, true)
        draw_circle(p, 1.6, Color(0.98, 0.96, 1.0, 0.88 * flicker))

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
