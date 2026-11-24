extends Node2D
## Cosmetic attack release for the Moor Warden. No collision, hitboxes,
## timers that trigger damage, or extra projectile hits.
var kind: int = 0
var facing: Vector2 = Vector2.DOWN
var age: float = 0.0
var lifetime: float = 0.48

func _ready() -> void:
    z_index = 15

func _process(delta: float) -> void:
    age += delta
    if age >= lifetime:
        queue_free()
    else:
        queue_redraw()

func _draw() -> void:
    var t: float = clampf(age / lifetime, 0.0, 1.0)
    var alpha: float = pow(1.0 - t, 1.5)
    var pink: Color = Color(0.99, 0.65, 0.78, 0.8 * alpha)
    var pearl: Color = Color(0.93, 0.89, 1.0, 0.65 * alpha)
    var direction: Vector2 = facing.normalized() if facing.length_squared() > 0.01 else Vector2.DOWN
    if kind == 0:
        var start_angle: float = direction.angle() - PI * 0.52
        var end_angle: float = direction.angle() + PI * 0.52
        draw_arc(Vector2.ZERO, 110.0 + 70.0 * t, start_angle, end_angle, 52, pink, 8.0 * (1.0 - t) + 1.0, true)
        draw_arc(Vector2.ZERO, 75.0 + 80.0 * t, start_angle, end_angle, 52, pearl, 2.4, true)
    elif kind == 1:
        draw_arc(Vector2.ZERO, 50.0 + 190.0 * t, 0.0, TAU, 88, pearl, 6.0 * (1.0 - t) + 1.0, true)
        draw_arc(Vector2.ZERO, 30.0 + 215.0 * t, 0.0, TAU, 88, pink, 2.0, true)
        for i in range(12):
            var theta: float = float(i) * TAU / 12.0
            var p: Vector2 = Vector2.from_angle(theta) * (48.0 + 185.0 * t)
            draw_circle(p, 3.0 * (1.0 - t) + 1.0, pink)
    else:
        var end_point: Vector2 = direction * 330.0
        var perpendicular: Vector2 = Vector2(-direction.y, direction.x)
        draw_line(Vector2.ZERO, end_point, Color(0.70, 0.49, 0.89, 0.13 * alpha), 32.0 * (1.0 - t) + 6.0, true)
        draw_line(Vector2.ZERO, end_point, pink, 12.0 * (1.0 - t) + 1.5, true)
        draw_line(Vector2.ZERO, end_point, pearl, 3.2, true)
        for i in range(9):
            var f: float = (float(i) + 0.5) / 9.0
            var wobble: float = sin(f * 22.0 + t * 17.0) * 15.0 * (1.0 - t)
            draw_circle(end_point * f + perpendicular * wobble, 2.5, pearl)
