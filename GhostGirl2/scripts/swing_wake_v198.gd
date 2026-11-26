extends Node2D
## v1.98 small committed-air wake. No collision, damage, hit counts or saves.
## Shows motion on a HEAVY, JUMP or CHARGED release even with zero targets.
var age: float = 0.0
var life: float = 0.24
var direction: Vector2 = Vector2.RIGHT
var kind: String = "heavy"
var color: Color = Color("ccbdd9")

func _ready() -> void:
    z_index = 25
    add_to_group("v198_air_wake")
    set_process(true)

func _process(delta: float) -> void:
    age += delta
    if age >= life:
        queue_free()
        return
    queue_redraw()

func _draw() -> void:
    var t: float = clampf(age / life, 0.0, 1.0)
    var fade: float = pow(1.0 - t, 1.75)
    var heading: Vector2 = direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT
    var angle: float = heading.angle()
    var distance: float = (10.0 if kind == "charged" else 14.0) + 10.0 * t
    var span: float = 0.46 if kind == "charged" else 0.72
    var radius: float = ((18.0 if kind == "charged" else 23.0) + 15.0 * t) * 1.20
    var rim: Color = Color(color.r, color.g, color.b, 0.25 * fade)
    var feather: Color = Color(color.r, color.g, color.b, 0.08 * fade)
    var center: Vector2 = heading * distance
    draw_arc(center, radius, angle - span, angle + span, 18, rim, 1.5, true)
    draw_arc(center, radius + 5.0, angle - span * 0.72, angle + span * 0.72, 16, feather, 4.0, true)
    for i in range(3):
        var u: float = float(i + 1) / 4.0
        var p: Vector2 = center + Vector2.from_angle(angle + (u - 0.5) * span * 1.8) * (radius + 1.5)
        draw_line(p - heading * (5.0 + 4.0 * t), p + heading * 2.0, Color(color.r, color.g, color.b, 0.17 * fade), 0.9, true)
