extends Node2D
## v1.57 — tiny, capped physical feedback. All cues are cosmetic and
## self-destruct. Only real attack release / actual evade / confirmed riposte.
var kind: String = "evade"
var direction: Vector2 = Vector2.RIGHT
var tint: Color = Color("cfb6ec")
var duration: float = 0.38
var time_left: float = 0.38

func _ready() -> void:
    add_to_group("combat_feedback_v157")
    duration = 0.21 if kind == "release" else (0.34 if kind == "evade" else (0.46 if kind == "ready" else 0.52))
    time_left = duration
    z_index = 45
    queue_redraw()

func _process(delta: float) -> void:
    time_left -= delta
    if time_left <= 0.0:
        queue_free()
        return
    queue_redraw()

func _draw() -> void:
    var progress: float = clampf(1.0 - time_left / maxf(0.001, duration), 0.0, 1.0)
    var fade: float = pow(1.0 - progress, 1.55)
    var forward: Vector2 = direction.normalized() if direction.length_squared() > 0.01 else Vector2.RIGHT
    var across: Vector2 = Vector2(-forward.y, forward.x)
    var bright: Color = Color(1.0, 0.95, 0.82)
    if kind == "release":
        # Short local warning-release spark, never a fullscreen impact.
        draw_circle(Vector2.ZERO, 5.0 + progress * 8.0, Color(tint.r, tint.g, tint.b, fade * 0.12))
        draw_line(-across * (8.0 + 7.0 * progress), across * (8.0 + 7.0 * progress), Color(tint.r, tint.g, tint.b, fade * 0.57), 1.7, true)
        draw_line(-forward * 3.0, forward * (13.0 + progress * 8.0), Color(bright.r, bright.g, bright.b, fade * 0.38), 1.25, true)
        return
    if kind == "evade":
        draw_arc(Vector2.ZERO, 12.0 + progress * 23.0, forward.angle() + 0.9, forward.angle() + TAU - 0.9, 28, Color(tint.r, tint.g, tint.b, fade * 0.52), 1.6, true)
        for i in range(4):
            var p: Vector2 = (forward * (float(i) - 1.5) + across * sin(progress * 5.0 + float(i))) * 8.0
            draw_circle(p, 1.7, Color(bright.r, bright.g, bright.b, fade * 0.43))
        return
    if kind == "ready":
        draw_arc(Vector2.ZERO, 21.0 + progress * 13.0, -PI * 0.72, PI * 0.72, 26, Color(tint.r, tint.g, tint.b, fade * 0.53), 1.8, true)
        draw_circle(Vector2(0, -25.0 - 7.0 * progress), 2.0, Color(bright.r, bright.g, bright.b, fade * 0.9))
        return
    # Riposte: a distinctive paired crescent, small central flash and
    # directional streaks at the contact point. Only spawned after hit().
    var radius: float = 17.0 + 38.0 * progress
    draw_circle(Vector2.ZERO, radius * 0.58, Color(tint.r, tint.g, tint.b, fade * 0.065))
    draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(tint.r, tint.g, tint.b, fade * 0.70), 2.3, true)
    draw_arc(Vector2.ZERO, radius * 0.70, 0.0, TAU, 36, Color(bright.r, bright.g, bright.b, fade * 0.55), 1.2, true)
    for i in range(5):
        var p: Vector2 = forward * (5.0 + 11.0 * float(i)) + across * (float(i % 3) - 1.0) * 4.0
        draw_line(p, p + forward * (24.0 + 17.0 * progress), Color(bright.r, bright.g, bright.b, fade * 0.42), 1.2, true)
