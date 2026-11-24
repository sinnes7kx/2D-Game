extends Node2D
## Small world-space hit confirmation, no blood/gore, no dialogue or HUD text.
const DURATION: float = 0.44
var age: float = 0.0
var rays: Array[Vector2] = []

func _ready() -> void:
	z_index = 12
	for i in range(14):
		var theta: float = float(i) * TAU / 14.0 + 0.17
		var length_factor: float = 0.66 + float(i % 5) * 0.11
		rays.append(Vector2.from_angle(theta) * length_factor)

func _process(delta: float) -> void:
	age += delta
	if age >= DURATION:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var fade: float = 1.0 - age / DURATION
	var ring: float = 11.0 + age * 70.0
	draw_arc(Vector2.ZERO, ring, 0.0, TAU, 26, Color(0.80, 0.68, 0.68, 0.24 * fade), 1.5, true)
	for i in range(rays.size()):
		var vector: Vector2 = rays[i]
		var start: Vector2 = vector * (6.0 + age * 65.0)
		var stop: Vector2 = vector * (14.0 + age * 100.0)
		var color: Color = Color(0.92, 0.83, 0.75, 0.77 * fade) if i % 3 == 0 else Color(0.63, 0.43, 0.47, 0.72 * fade)
		draw_line(start, stop, color, 2.2, true)
		draw_circle(stop, 1.8, color)
