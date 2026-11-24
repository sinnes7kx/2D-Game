@tool
extends Node2D
## Purely visual puzzle instructions: a physical, editable scene node.
## No text or dialogue is displayed when Ghost Girl discovers a clue.
@export_enum("bells", "flowers", "mirrors", "moon") var clue_type: String = "bells":
	set(value):
		clue_type = value
		queue_redraw()

func _draw() -> void:
	# A discreet engraved triptych; all symbols are rendered in the room,
	# never in a screen-blocking pop-up.
	var silver: Color = Color(0.84, 0.82, 0.96, 0.76)
	var dim: Color = Color(0.38, 0.32, 0.52, 0.42)
	draw_line(Vector2(-81, 27), Vector2(81, 27), dim, 2.0, true)
	draw_line(Vector2(-81, -25), Vector2(81, -25), dim, 2.0, true)
	for idx in range(3):
		var x: float = -55.0 + float(idx) * 55.0
		draw_arc(Vector2(x, 0), 21.0, 0.0, TAU, 24, dim, 1.4, true)
		draw_circle(Vector2(x, 33), 2.5, silver)
		match clue_type:
			"bells":
				# First the western, then the southern, then the eastern bell.
				draw_arc(Vector2(x, -5), 10.0, PI, TAU, 20, silver, 2.1, true)
				draw_line(Vector2(x - 10, -5), Vector2(x - 12, 8), silver, 2.0, true)
				draw_line(Vector2(x + 10, -5), Vector2(x + 12, 8), silver, 2.0, true)
				draw_line(Vector2(x - 12, 8), Vector2(x + 12, 8), silver, 2.0, true)
				draw_circle(Vector2(x, 12), 3.0, silver)
			"flowers":
				var colors: Array[Color] = [Color(1.0, 0.56, 0.72), Color(0.96, 0.94, 1.0), Color(0.64, 0.56, 0.98)]
				for petal in range(5):
					var angle: float = float(petal) * TAU / 5.0
					draw_circle(Vector2(x, 0) + Vector2.from_angle(angle) * 8.0, 6.0, colors[idx])
				draw_circle(Vector2(x, 0), 3.0, Color(0.97, 0.84, 0.62))
			"mirrors":
				var answers: Array[int] = [2, 0, 3]
				var a: float = PI / 4.0 + float(answers[idx]) * PI / 4.0
				var axis: Vector2 = Vector2.from_angle(a) * 14.0
				draw_line(Vector2(x, 0) - axis, Vector2(x, 0) + axis, silver, 3.0, true)
			"moon":
				draw_arc(Vector2(x, 0), 11.0, -PI * 0.6, PI * 0.8, 24, silver, 2.5, true)
	draw_line(Vector2(-25, 0), Vector2(-14, 0), silver, 1.5, true)
	draw_line(Vector2(30, 0), Vector2(41, 0), silver, 1.5, true)
