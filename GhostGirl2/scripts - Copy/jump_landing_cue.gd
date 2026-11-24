extends Node2D
## Cosmetic moon-dust landing. Stronger when an aerial attack actually fired.
## Does not modify jump timing, collision, damage, or player movement.
var age: float = 0.0
var enhanced: bool = false
var accent: Color = Color("dcb8eb")
var motion: Vector2 = Vector2.RIGHT
const DURATION: float = 0.46

func _ready() -> void:
    z_index = 35

func _process(delta: float) -> void:
    age += delta
    if age >= DURATION:
        queue_free()
        return
    queue_redraw()

func _draw() -> void:
    var t: float = clampf(age / DURATION, 0.0, 1.0)
    var fade: float = pow(1.0 - t, 1.35)
    var base: Color = accent.lerp(Color("e7e1f5"), 0.46)
    var radius: float = 12.0 + t * (46.0 if enhanced else 32.0)
    draw_circle(Vector2.ZERO, radius * 0.63, Color(base.r, base.g, base.b, 0.08 * fade))
    draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(base.r, base.g, base.b, fade * (0.69 if enhanced else 0.40)), 2.3 if enhanced else 1.5, true)
    if enhanced:
        draw_arc(Vector2.ZERO, radius * 0.65, -0.2 * PI, 1.72 * PI, 28, Color(0.99, 0.92, 0.77, fade * 0.46), 1.6, true)
    var count: int = 16 if enhanced else 9
    for i in range(count):
        var angle: float = float(i) * TAU / float(count) + 0.28
        var travel: float = (12.0 + t * (27.0 + float(i % 3) * 7.0))
        var p: Vector2 = Vector2.from_angle(angle) * travel
        var ink: Color = Color(base.r, base.g, base.b, fade * (0.78 if enhanced else 0.57))
        if enhanced and i % 3 == 0:
            var tangent: Vector2 = Vector2.from_angle(angle + PI * 0.5)
            draw_line(p - tangent * 4.0, p + tangent * 4.0, ink, 1.4, true)
            draw_line(p - Vector2.from_angle(angle) * 3.0, p + Vector2.from_angle(angle) * 3.0, ink, 1.4, true)
        else:
            draw_circle(p, 1.3 + float(i % 2) * 0.6, ink)
    if enhanced:
        var forward: Vector2 = motion.normalized() if motion.length_squared() > 0.01 else Vector2.RIGHT
        draw_line(-forward * (5.0 + t * 15.0), forward * (14.0 + t * 31.0), Color(base.r, base.g, base.b, fade * 0.26), 1.8, true)
