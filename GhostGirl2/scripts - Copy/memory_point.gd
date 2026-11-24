@tool
extends Node2D
## The environmental storytelling node: silent visual feedback only.
@export var interaction_name: String = "Touch the memory"
@export_enum("sanctum", "star") var memory_kind: String = "sanctum"
@export var awakened: bool = false
var elapsed: float = 0.0

func _ready() -> void:
    if not Engine.is_editor_hint():
        add_to_group("interactable")

func _process(delta: float) -> void:
    elapsed += delta
    queue_redraw()

func _draw() -> void:
    var glow: Color = Color(0.96, 0.85, 1.0) if memory_kind == "sanctum" else Color(0.97, 0.94, 0.73)
    var strength: float = 0.34 if awakened else 0.65 + sin(elapsed * 1.6) * 0.13
    draw_circle(Vector2(0, -16), 27.0, Color(glow.r, glow.g, glow.b, 0.09 * strength))
    draw_arc(Vector2(0, -16), 18.0, 0.0, TAU, 32, Color(glow.r, glow.g, glow.b, strength), 2.0, true)
    draw_circle(Vector2(0, -16), 6.0, Color(glow.r, glow.g, glow.b, strength))
    for i in range(5):
        var theta: float = elapsed * 0.42 + float(i) * TAU / 5.0
        var p: Vector2 = Vector2(cos(theta) * 31.0, -16.0 + sin(theta) * 20.0)
        draw_circle(p, 2.2, Color(glow.r, glow.g, glow.b, strength * 0.68))
