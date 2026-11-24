@tool
extends Node2D
## Editable restful checkpoint. E heals, replenishes dew, and stores the
## current room/position for a safe return on defeat. No dialogue required.
@export var interaction_name: String = "Rest at the ember shrine"
@export var shrine_id: String = "ash_shrine"
@export var activated: bool = false
var clock: float = 0.0

func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group("interactable")
		add_to_group("rest_shrine")

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func _draw() -> void:
	var stone: Color = Color("353238")
	var iron: Color = Color("85787a")
	var warmth: Color = Color("b59a79") if not activated else Color("d9bca1")
	draw_circle(Vector2(0, 13), 39, Color(0.04, 0.035, 0.04, 0.49))
	draw_rect(Rect2(-25, -19, 50, 31), stone, true)
	draw_rect(Rect2(-25, -19, 50, 31), iron, false, 2.0)
	draw_line(Vector2(-17,-19), Vector2(-9,-40), iron, 3.0, true)
	draw_line(Vector2(17,-19), Vector2(9,-40), iron, 3.0, true)
	draw_arc(Vector2(0,-28), 12, 0, TAU, 24, iron, 2, true)
	var breath: float = 0.80 + 0.16 * sin(clock * 3.0)
	draw_circle(Vector2(0,-33), 13 * breath, Color(0.85, 0.54, 0.36, 0.10))
	draw_circle(Vector2(0,-33), 6 * breath, warmth)
	draw_circle(Vector2(0,-34), 3, Color(1, 0.85, 0.68, 0.94))
	if activated:
		draw_arc(Vector2.ZERO, 44, clock * 0.2, clock * 0.2 + PI, 26, Color(0.92,0.74,0.59,0.4), 2.0, true)
