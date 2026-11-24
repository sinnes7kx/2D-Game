@tool
extends Node2D
## Quiet environmental storytelling. Readable but not a new mandatory quest.
@export var slab_title: String = "THE LAST BELL"
@export_multiline var inscription: String = "Even after the Warden fell, one vigil remained."
var elapsed: float = 0.0

func _ready() -> void:
    if not Engine.is_editor_hint():
        add_to_group("interactable")
        add_to_group("v134_story_slab")

func _process(delta: float) -> void:
    elapsed += delta
    queue_redraw()

func _draw() -> void:
    var glow: float = 0.5 + 0.5 * sin(elapsed * 1.6)
    draw_circle(Vector2(0, 12), 27.0, Color(0.03, 0.025, 0.04, 0.36))
    draw_colored_polygon(PackedVector2Array([Vector2(-16, 10), Vector2(-14, -26), Vector2(-7, -40), Vector2(7, -40), Vector2(14, -26), Vector2(16, 10)]), Color("393343"))
    draw_line(Vector2(-14, -26), Vector2(-7, -40), Color("96849c"), 2.0, true)
    draw_line(Vector2(-7, -40), Vector2(7, -40), Color("96849c"), 2.0, true)
    draw_line(Vector2(7, -40), Vector2(14, -26), Color("96849c"), 2.0, true)
    draw_arc(Vector2(0, -19), 9.0, 0.0, TAU, 28, Color(0.90, 0.76, 0.86, 0.26 + 0.22 * glow), 1.7, true)
    draw_line(Vector2(0, -27), Vector2(0, -11), Color("c8b2d2"), 1.3, true)
