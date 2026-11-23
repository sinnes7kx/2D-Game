@tool
extends Node2D
## Artist / level designer can move the five Marker2D children in the scene.
## The path is no longer baked to the original 1448x1086 canvas.
@export_range(1, 4, 1) var segments_lit: int = 1
var phase: float = 0.0

func _process(delta: float) -> void:
	phase += delta
	queue_redraw()

func _points() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for name in ["Source", "MirrorWest", "MirrorNorth", "MirrorEast", "Star"]:
		var marker: Marker2D = get_node_or_null(name) as Marker2D
		if marker == null:
			return []
		result.append(marker.position)
	return result

func _draw() -> void:
	var positions: Array[Vector2] = _points()
	if positions.size() != 5:
		return
	for i in range(4):
		var from: Vector2 = positions[i]
		var to: Vector2 = positions[i + 1]
		if i < segments_lit:
			draw_line(from, to, Color(0.58, 0.53, 0.95, 0.10), 21.0, true)
			draw_line(from, to, Color(0.69, 0.80, 1.0, 0.27), 9.0, true)
			draw_line(from, to, Color(0.96, 0.91, 1.0, 0.88), 2.6, true)
			var shimmer: Vector2 = from.lerp(to, fposmod(phase * 0.55, 1.0))
			draw_circle(shimmer, 5.0, Color(1.0, 0.95, 0.81, 0.86))
		else:
			draw_line(from, to, Color(0.65, 0.62, 0.85, 0.20), 1.2, true)
	draw_circle(positions[0], 19.0 + sin(phase * 2.0) * 2.0, Color(0.8, 0.8, 1.0, 0.16))
	draw_circle(positions[0], 9.0, Color(0.92, 0.85, 1.0, 0.87))
	var target_color: Color = Color(0.99, 0.93, 0.68, 0.8) if segments_lit == 4 else Color(0.65, 0.54, 0.82, 0.65)
	draw_arc(positions[4], 28.0, 0.0, TAU, 32, target_color, 4.0, true)
	draw_circle(positions[4], 7.0, target_color)
