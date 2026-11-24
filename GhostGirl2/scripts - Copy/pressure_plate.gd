@tool
extends Node2D

@export var activated: bool = false
var glow_time: float = 0.0

func _process(delta: float) -> void:
	glow_time += delta
	queue_redraw()

func _draw() -> void:
	var radius := 48.0
	var glow_strength := 0.40 + sin(glow_time * 2.5) * 0.12
	var color := Color(0.84, 0.71, 1.0, 0.96) if activated else Color(0.66, 0.52, 0.83, 0.88)
	draw_circle(Vector2.ZERO, radius + 8.0, Color(0.35, 0.20, 0.50, glow_strength * 0.34))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, color, 4.0, true)
	draw_arc(Vector2.ZERO, radius - 9.0, 0.0, TAU, 64, Color(color.r, color.g, color.b, 0.45), 2.0, true)
	draw_line(Vector2(-29, 0), Vector2(29, 0), color, 2.0, true)
	draw_line(Vector2(0, -29), Vector2(0, 29), color, 2.0, true)
	for i in range(4):
		var theta := PI * 0.5 * i
		var center := Vector2(cos(theta), sin(theta)) * 29.0
		draw_circle(center, 5.0, color)
	if activated:
		draw_circle(Vector2.ZERO, 11.0 + sin(glow_time * 3.0) * 2.0, Color(0.95, 0.86, 1.0, 0.8))
