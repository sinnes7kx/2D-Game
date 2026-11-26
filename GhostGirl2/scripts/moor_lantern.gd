@tool
extends Node2D
const PERF_V230 = preload("res://scripts/performance_profiles_v230.gd")
var redraw_clock: float = 0.0
var last_profile_revision: int = -1
## Gentle, non-colliding path lantern to make the wilderness legible.
@export var lamp_color: Color = Color("d6a578")
@export_range(0.4, 1.5, 0.05) var glow_strength: float = 0.85
var age: float = 0.0

func _process(delta: float) -> void:
    age += delta
    redraw_clock += delta
    var hz: float = 0.0 if Engine.is_editor_hint() else PERF_V230.ambient_hz()
    if last_profile_revision != PERF_V230.revision or PERF_V230.due(redraw_clock, hz):
        last_profile_revision = PERF_V230.revision
        redraw_clock = PERF_V230.remainder(redraw_clock, hz)
        queue_redraw()

func _draw() -> void:
    var flicker: float = 0.88 + 0.12 * sin(age * 3.8)
    draw_circle(Vector2.ZERO, 23, Color(0.03, 0.03, 0.04, 0.25))
    draw_line(Vector2(0, 2), Vector2(0, -69), Color("484047"), 4.5, true)
    draw_line(Vector2(0, -69), Vector2(19, -69), Color("65545b"), 3.0, true)
    draw_line(Vector2(19, -69), Vector2(19, -58), Color("65545b"), 1.6, true)
    draw_colored_polygon(PackedVector2Array([Vector2(10,-57),Vector2(28,-57),Vector2(25,-35),Vector2(13,-35)]), Color("33272c"))
    draw_rect(Rect2(14,-54,10,16), Color(lamp_color.r,lamp_color.g,lamp_color.b,0.5), true)
    draw_circle(Vector2(19,-47), 23.0 * glow_strength, Color(lamp_color.r,lamp_color.g,lamp_color.b,0.045 * flicker))
    draw_circle(Vector2(19,-47), 9.0, Color(lamp_color.r,lamp_color.g,lamp_color.b,0.16 * flicker))
    draw_circle(Vector2(19,-47), 3.0, Color(1.0,0.88,0.71,0.85 * flicker))
