@tool
extends Node2D
## Presentation only; bounded redraws follow the session performance profile.
const PERF = preload("res://scripts/performance_profiles_v230.gd")
const LIGHT = preload("res://assets/animated/candle_glow.png")
@export_enum("hearth", "lantern") var kind: String = "hearth"
@export var light_seed: int = 0
var age: float = 0.0
var pending: float = 0.0

func _process(delta: float) -> void:
    age += delta
    pending += delta
    var hz: float = PERF.ambient_hz()
    if PERF.due(pending, hz):
        pending = PERF.remainder(pending, hz)
        queue_redraw()

func _draw() -> void:
    var phase: float = float(light_seed) * 0.73
    var flicker: float = 0.90 + 0.07 * sin(age * 3.2 + phase) + 0.03 * sin(age * 7.3)
    var hearth: bool = kind == "hearth"
    var radius: float = 220.0 if hearth else 80.0
    var center: Vector2 = Vector2(0,-20) if hearth else Vector2.ZERO
    draw_texture_rect(LIGHT, Rect2(center - Vector2.ONE * radius, Vector2.ONE * radius * 2.0), false, Color(1.0,0.64,0.32,0.36 * flicker))
    if not hearth:
        draw_circle(Vector2.ZERO, 4.0, Color(1.0,0.81,0.48,0.8 * flicker))
        return
    for i in range(5):
        var x: float = float(i - 2) * 12.0
        var height: float = (42.0 + 34.0 * sin(float(i + 1) * 0.61)) * flicker
        var sway: float = sin(age * 4.0 + float(i) * 1.7 + phase) * 7.0
        var path: PackedVector2Array = PackedVector2Array([Vector2(x-12,0), Vector2(x-14,-height*0.36), Vector2(x+sway,-height), Vector2(x+10,-height*0.48), Vector2(x+13,0)])
        draw_colored_polygon(path, Color(0.94,0.39+float(i)*0.065,0.12,0.65))
        draw_colored_polygon(PackedVector2Array([Vector2(x-7,0),Vector2(x+sway*0.5,-height*0.65),Vector2(x+7,0)]),Color(1.0,0.84,0.41,0.85))
    var count: int = 8 if PERF.profile == PERF.Profile.LOW else 16
    for i in range(count):
        var t: float = fposmod(age*(0.23+float(i%4)*0.025)+float(i)/float(count),1.0)
        var at: Vector2 = Vector2(sin(float(i)*2.3+t*4.0)* (12.0+t*38.0), -18.0-t*122.0)
        draw_circle(at,1.3+float(i%3)*0.35,Color(1.0,0.64,0.25,sin(t*PI)*0.8))
