@tool
extends Node2D
## Designer-placed target for the moonrose hook. F casts toward an anchor.
## Put these nodes under Gameplay/HookAnchors and move them in the editor.
@export var hover_radius: float = 29.0
var elapsed: float = 0.0

func _ready() -> void:
    if not Engine.is_editor_hint():
        add_to_group("hook_anchor")

func _process(delta: float) -> void:
    elapsed += delta
    queue_redraw()

func _draw() -> void:
    var t: float = elapsed * 0.75
    var silver: Color = Color(0.88, 0.78, 0.97, 0.78)
    draw_circle(Vector2.ZERO, hover_radius * 1.15, Color(0.64, 0.50, 0.90, 0.07))
    draw_arc(Vector2.ZERO, hover_radius, 0.0, TAU, 40, Color(0.82, 0.63, 0.98, 0.22), 2.0, true)
    draw_arc(Vector2.ZERO, 15.0, 0.1, PI * 1.65, 30, silver, 3.0, true)
    # Rose / moon emblem, intentionally delicate rather than a huge marker.
    for i in range(5):
        var a: float = float(i) * TAU / 5.0 + t * 0.06
        draw_circle(Vector2.from_angle(a) * 7.2, 4.8, Color(0.92, 0.60, 0.76, 0.65))
    draw_circle(Vector2.ZERO, 4.0, Color(0.98, 0.92, 1.0, 0.85))
    for j in range(4):
        var a2: float = t + float(j) * TAU / 4.0
        var p: Vector2 = Vector2.from_angle(a2) * (22.0 + sin(elapsed * 1.5) * 3.0)
        draw_circle(p, 1.8, Color(0.96, 0.91, 1.0, 0.48))
