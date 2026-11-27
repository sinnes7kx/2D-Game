extends Node2D
var actor: CharacterBody2D

func _ready() -> void:
	z_index=12

func _process(_delta: float) -> void:
	if not is_instance_valid(actor) or float(actor.get("ivory_guard_left_v289"))<=0.0:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(actor):
		return
	var axis: Vector2 = actor.get("ivory_guard_direction_v289")
	var a: float = axis.angle()
	var t: float = clampf(float(actor.get("ivory_guard_left_v289"))/0.46,0.0,1.0)
	var center: Vector2 = Vector2(0,-24)
	draw_arc(center,57.0,a-1.0,a+1.0,32,Color(0.94,0.84,0.64,0.15+t*0.12),8.0,true)
	draw_arc(center,57.0,a-1.0,a+1.0,32,Color(0.99,0.90,0.75,0.45+t*0.35),1.5,true)
	draw_line(center+axis*43.0,center+axis*72.0,Color(1.0,0.92,0.78,0.85),1.6,true)
