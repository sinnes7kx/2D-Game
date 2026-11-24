extends Node2D
## Lantern-like afterglow for one physical arrow. Cosmetic only; no raycasts.
var arrow: Node2D = null
var elapsed: float = 0.0

func _ready() -> void:
    arrow = get_parent() as Node2D
    var mat: CanvasItemMaterial = CanvasItemMaterial.new()
    mat.blend_mode = CanvasItemMaterial.BLEND_MODE_MIX
    material = mat
    self_modulate.a = 0.55
    z_index = -1

func _process(delta: float) -> void:
    elapsed += delta
    queue_redraw()

func _color_at(t: float) -> Color:
    if arrow == null:
        return Color("f8d5e7")
    var a: Color = arrow.get("glow_a") as Color
    var b: Color = arrow.get("glow_b") as Color
    var c: Color = arrow.get("glow_c") as Color
    return a.lerp(b, t * 2.0) if t < 0.5 else b.lerp(c, (t - 0.5) * 2.0)

func _draw() -> void:
    if arrow == null or arrow.is_queued_for_deletion():
        return
    var dir: Vector2 = arrow.get("direction") as Vector2
    if dir.length_squared() < 0.01:
        return
    dir = dir.normalized()
    var head: Vector2 = dir * 18.0
    var color: Color = _color_at(0.75)
    var power: float = 1.18 if bool(arrow.get("charged")) else 0.82
    # Soft taper using concentric lamp-like glows; no hard rectangular beam.
    for k in range(5):
        var q: Vector2 = head - dir * float(k) * 5.0
        var fade: float = 1.0 - float(k) / 5.0
        draw_circle(q, 7.0 * fade + 1.0, Color(color.r, color.g, color.b, 0.028 * power * fade))
        draw_circle(q, 3.5 * fade + 0.7, Color(color.r, color.g, color.b, 0.082 * power * fade))
    draw_circle(head, 3.0, Color(color.r, color.g, color.b, 0.22 * power))
    # Past world positions recede behind the physical projectile and dissolve.
    var history: Array = arrow.get("trail_points")
    for i in range(history.size() - 1):
        var at: Vector2 = arrow.to_local(history[i])
        var next_at: Vector2 = arrow.to_local(history[i + 1])
        var f: float = 1.0 - float(i) / float(maxi(history.size(), 1))
        var c: Color = _color_at(clampf(float(i) / float(maxi(1, history.size() - 1)), 0.0, 1.0))
        draw_line(at, next_at, Color(c.r, c.g, c.b, 0.17 * f * power), 4.0 * f + 0.5, true)
        draw_line(at, next_at, Color(c.r, c.g, c.b, 0.24 * f * power), 1.2, true)
