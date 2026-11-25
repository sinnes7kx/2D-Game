@tool
extends Node2D
## A stage marker for the v2.02 fletcher trial.
## The physical arrow still owns the one and only hit/collision sweep.
@export_range(0, 2, 1) var stage_index: int = 0
@export var trigger_radius: float = 33.0
var glow: float = 0.0

func _ready() -> void:
    if not Engine.is_editor_hint():
        add_to_group("v139_elemental_world")

func on_elemental_arrow_hit(_element: int, _formation: int, charged: bool, airborne: bool) -> bool:
    var range: Node = get_parent()
    if range == null or not range.has_method("on_target_hit"):
        return false
    if bool(range.call("on_target_hit", stage_index, charged, airborne)):
        glow = 1.0
        return true
    return false

func _process(delta: float) -> void:
    if glow > 0.0:
        glow = maxf(0.0, glow - delta * 1.45)
        queue_redraw()
    elif Engine.is_editor_hint():
        queue_redraw()

func _draw() -> void:
    var wood: Color = Color("675561")
    var outer: Color = Color("a994a9")
    var center: Color = Color("b4bad9") if stage_index == 0 else (Color("dbb9a4") if stage_index == 1 else Color("d0bbec"))
    draw_line(Vector2(0, 34), Vector2(0, -33), wood, 7.0, true)
    draw_circle(Vector2(0, -35), 29.0, Color("3c3344"))
    draw_arc(Vector2(0, -35), 27, 0.0, TAU, 30, outer, 4.5, true)
    draw_arc(Vector2(0, -35), 18, 0.0, TAU, 30, center, 3.5, true)
    draw_circle(Vector2(0, -35), 6.0, Color("e7d5de"))
    if stage_index == 2:
        draw_line(Vector2(-9, -13), Vector2(0, -24), Color("a7c9e8"), 2.0, true)
        draw_line(Vector2(0, -24), Vector2(9, -13), Color("a7c9e8"), 2.0, true)
    if glow > 0.0:
        draw_circle(Vector2(0, -35), 23.0, Color(center.r, center.g, center.b, glow * 0.12))
