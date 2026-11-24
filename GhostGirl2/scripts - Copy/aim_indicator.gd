extends Node2D
## Small cursor reticle while holding an item. Uses the world's 2D cursor
## coordinates so its center is the actual launch direction target.

var player
var phase: float = 0.0

func _process(delta: float) -> void:
	phase += delta
	var should_show: bool = not OS.has_feature("mobile") and is_instance_valid(player) and player.carrying != null
	if not should_show:
		visible = false
		return
	visible = true
	global_position = get_global_mouse_position()
	queue_redraw()

func _draw() -> void:
	var tint: Color = Color(0.95, 0.85, 1.0, 0.72)
	var radius: float = 14.0 + sin(phase * 4.0) * 1.2
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, tint, 1.5, true)
	draw_line(Vector2(-21.0, 0.0), Vector2(-9.0, 0.0), tint, 1.5, true)
	draw_line(Vector2(9.0, 0.0), Vector2(21.0, 0.0), tint, 1.5, true)
	draw_line(Vector2(0.0, -21.0), Vector2(0.0, -9.0), tint, 1.5, true)
	draw_line(Vector2(0.0, 9.0), Vector2(0.0, 21.0), tint, 1.5, true)
	draw_circle(Vector2.ZERO, 2.0, Color(1.0, 0.96, 1.0, 0.8))
