@tool
extends Node2D
## A small, editor-free interactable puzzle piece. Geometry is drawn at runtime.
## Bell, blossom and mirror are deliberately nonblocking; collisions are edited
## separately inside each room scene.

@export var interaction_name: String = "Memory mechanism"
@export_enum("bell", "blossom", "mirror") var kind: String = "bell"
@export_range(0, 3, 1) var orientation: int = 0
@export var lit: bool = false
@export var tint: Color = Color(0.87, 0.72, 0.98)
var phase: float = 0.0

func _ready() -> void:
    add_to_group("interactable")

func _process(delta: float) -> void:
    phase += delta
    queue_redraw()

func _draw() -> void:
    var pulse: float = 0.5 + sin(phase * 2.5) * 0.12
    var tone: Color = Color(0.99, 0.91, 0.68) if lit else tint
    var rim: Color = Color(tone.r, tone.g, tone.b, 0.7 if lit else 0.34)
    draw_circle(Vector2.ZERO, 44.0, Color(tone.r, tone.g, tone.b, 0.10 + pulse * 0.12))
    draw_arc(Vector2.ZERO, 33.0, 0.0, TAU, 40, rim, 2.5, true)
    match kind:
        "bell":
            draw_arc(Vector2(0, -7), 20.0, PI, TAU, 24, tone, 3.0, true)
            draw_line(Vector2(-20, -7), Vector2(-24, 12), tone, 3.0, true)
            draw_line(Vector2(20, -7), Vector2(24, 12), tone, 3.0, true)
            draw_line(Vector2(-24, 12), Vector2(24, 12), tone, 3.0, true)
            draw_circle(Vector2(0, 17), 5.0, tone)
            draw_circle(Vector2(0, -28), 4.0, tone)
        "blossom":
            for i in range(7):
                var theta: float = TAU * float(i) / 7.0 + phase * 0.08
                var p: Vector2 = Vector2(cos(theta), sin(theta)) * 15.0
                draw_circle(p, 10.5, Color(tone.r, tone.g, tone.b, 0.77))
                draw_circle(p + Vector2(-2, -3), 4.0, Color(1.0, 0.97, 1.0, 0.36))
            draw_circle(Vector2.ZERO, 8.0, Color(0.97, 0.82, 0.57))
            if lit:
                for j in range(7):
                    var theta2: float = TAU * float(j) / 7.0 + phase * 0.4
                    draw_circle(Vector2(cos(theta2), sin(theta2)) * 37.0, 2.8, Color(1.0, 0.94, 0.75, 0.7))
        "mirror":
            var angle: float = PI / 4.0 + float(orientation) * PI / 4.0
            var axis: Vector2 = Vector2(cos(angle), sin(angle))
            draw_circle(Vector2.ZERO, 24.0, Color(0.16, 0.18, 0.32, 0.92))
            draw_line(-axis * 24.0, axis * 24.0, Color(0.98, 0.92, 1.0), 6.0, true)
            draw_line(-axis * 19.0 + Vector2(0, -2), axis * 19.0 + Vector2(0, -2), Color(0.65, 0.83, 1.0), 2.0, true)
            for k in range(4):
                var mark: float = float(k) * TAU / 4.0 - PI / 2.0
                draw_circle(Vector2(cos(mark), sin(mark)) * 31.0, 3.0, tone)
    if lit:
        draw_arc(Vector2.ZERO, 39.0, phase * 0.3, phase * 0.3 + PI * 0.85, 20, Color(1.0, 0.90, 0.64, 0.55), 2.0, true)
