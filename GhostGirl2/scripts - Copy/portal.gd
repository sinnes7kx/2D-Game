@tool
extends Node2D

@export var interaction_name: String = "Garden gate"
@export var destination: String = "garden"
@export var opened: bool = false
var pulse: float = 0.0

func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group("interactable")
		add_to_group("room_portal")

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func _draw() -> void:
	var c := Color(0.80, 0.66, 1.0, 0.95) if opened else Color(0.56, 0.42, 0.70, 0.82)
	var alpha := 0.35 + sin(pulse * 2.7) * 0.15
	draw_arc(Vector2(0, -16), 48.0, PI, TAU, 32, Color(c.r, c.g, c.b, alpha), 5.0, true)
	draw_line(Vector2(-48, -16), Vector2(-48, 19), c, 4.0, true)
	draw_line(Vector2(48, -16), Vector2(48, 19), c, 4.0, true)
	if not opened:
		for i in range(5):
			var x := float(i - 2) * 17.0
			draw_line(Vector2(x, -48), Vector2(x, 18), Color(0.70, 0.57, 0.88, alpha), 2.0, true)
	else:
		for j in range(9):
			var a: float = pulse * 0.5 + float(j) * TAU / 9.0
			var p := Vector2(cos(a) * 27.0, -18.0 + sin(a) * 14.0)
			draw_circle(p, 2.2, Color(0.98, 0.87, 1.0, 0.75))
