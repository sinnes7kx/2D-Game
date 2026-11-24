extends Node2D
## Ground-plane contact shadow. This stays on the floor while objects arc above it.
@export var width: float = 23.0
@export var depth: float = 8.0

func _draw() -> void:
	var vertices := PackedVector2Array()
	for i in range(32):
		var angle := TAU * float(i) / 32.0
		vertices.append(Vector2(cos(angle) * width, sin(angle) * depth))
	draw_colored_polygon(vertices, Color(0.04, 0.03, 0.10, 0.34))
