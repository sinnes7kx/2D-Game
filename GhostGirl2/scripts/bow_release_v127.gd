extends Node2D
## Draw-only bowstring flare; no hitbox, damage or additional arrows.
var age: float = 0.0
var duration: float = 0.28
var direction: Vector2 = Vector2.RIGHT
var charged: bool = false
var ink: Color = Color("dda9c6")
var accent: Color = Color("cad7f1")
var rare_variant: int = -1

func _ready() -> void:
    z_index = 43

func _process(delta: float) -> void:
    age += delta
    if age >= duration:
        queue_free()
        return
    queue_redraw()

func _draw() -> void:
    var progress: float = clampf(age / duration, 0.0, 1.0)
    var fade: float = 1.0 - progress
    var heading: Vector2 = direction.normalized() if direction.length_squared() > 0.01 else Vector2.RIGHT
    var normal: Vector2 = Vector2(-heading.y, heading.x)
    var half: float = (19.0 if charged else 11.0) * (1.0 + progress)
    var bloom: Color = Color(ink.r, ink.g, ink.b, 0.43 * fade)
    draw_line(normal * half, -normal * half, bloom, 1.7, true)
    draw_arc(Vector2.ZERO, (14.0 if charged else 9.0) + 15.0 * progress, -PI / 2.0, PI / 2.0, 22, Color(accent.r, accent.g, accent.b, 0.5 * fade), 1.6, true)
    if rare_variant >= 0:
        var count: int = 5 + (3 if charged else 0)
        for i in range(count):
            var theta: float = float(i) * TAU / float(count) + float(rare_variant) * 0.4
            var p: Vector2 = Vector2.from_angle(theta) * (6.0 + 24.0 * progress)
            var c: Color = Color(accent.r, accent.g, accent.b, fade * 0.52)
            if rare_variant % 2 == 0:
                draw_circle(p, 2.1, c)
            else:
                draw_line(p - Vector2(0, 3), p + Vector2(0, 3), c, 1.3, true)
