extends RefCounted
## Draw-only bow-seed signature motifs on the single physical arrow.
## Uses no extra hitboxes, physics queries, damage, or random frames.
static func draw_motif(canvas: Node2D, style: int, forward: Vector2, time: float, base_color: Color) -> void:
	if style <= 0 or style > 8 or forward.length_squared() < 0.01:
		return
	var dir: Vector2 = forward.normalized()
	var normal: Vector2 = Vector2(-dir.y, dir.x)
	var glow: Color = base_color.lerp(Color("f8eafa"), 0.32)
	match style:
		1: # Moonthread, a soft double filament
			for side in [-1.0, 1.0]:
				canvas.draw_line(dir * 12.0 + normal * 3.0 * side, -dir * 35.0 + normal * 4.0 * side, Color(glow.r, glow.g, glow.b, 0.27), 1.2, true)
		2: # Twin Helix: two animated ribbons, still one real arrow
			for side in [-1.0, 1.0]:
				var ribbon: PackedVector2Array = []
				for i in range(9):
					var u: float = float(i) / 8.0
					ribbon.append(dir * (10.0 - u * 46.0) + normal * side * sin(u * TAU * 1.5 + time * 4.5) * 5.0)
				canvas.draw_polyline(ribbon, Color(glow.r, glow.g, glow.b, 0.29), 1.2, true)
		3: # Halo Burst
			canvas.draw_arc(dir * 8.0, 9.0 + sin(time * 4.0) * 1.5, 0.0, TAU, 20, Color(glow.r, glow.g, glow.b, 0.33), 1.2, true)
		4: # Petal Drift
			for i in range(5):
				var u: float = float(i) / 5.0
				var center: Vector2 = -dir * (8.0 + u * 33.0) + normal * sin(time * 2.7 + u * TAU) * 7.0
				canvas.draw_circle(center, 1.4 + (1.0 - u) * 1.0, Color(glow.r, glow.g, glow.b, 0.30 * (1.0 - u)))
		5: # Glass Motes
			for i in range(5):
				var u: float = float(i) / 5.0
				var center: Vector2 = -dir * (9.0 + u * 34.0) + normal * cos(time * 1.8 + float(i) * 2.0) * 5.0
				canvas.draw_colored_polygon(PackedVector2Array([center - dir * 3.0, center + normal * 2.0, center + dir * 2.5]), Color(glow.r, glow.g, glow.b, 0.24 * (1.0 - u)))
		6: # Comet Tail: tapered instead of a square beam
			for i in range(7):
				var u: float = float(i) / 7.0
				var center: Vector2 = -dir * (3.0 + u * 46.0)
				canvas.draw_circle(center, 4.0 * (1.0 - u) + 0.4, Color(glow.r, glow.g, glow.b, 0.13 * (1.0 - u)))
		7: # Starlace
			for i in range(5):
				var u: float = float(i) / 5.0
				var center: Vector2 = -dir * (9.0 + u * 34.0) + normal * sin(u * 15.0 + time * 1.5) * 6.0
				var radius: float = 1.0 + 1.5 * (1.0 - u)
				var ink: Color = Color(glow.r, glow.g, glow.b, 0.40 * (1.0 - u))
				canvas.draw_line(center - dir * radius, center + dir * radius, ink, 1.0, true)
				canvas.draw_line(center - normal * radius, center + normal * radius, ink, 1.0, true)
		8: # Wisp Bloom
			for i in range(5):
				var u: float = float(i) / 5.0
				var center: Vector2 = -dir * (5.0 + u * 35.0) + normal * sin(time * 2.2 + u * TAU * 2.0) * 5.5
				canvas.draw_circle(center, 4.0 - u * 2.0, Color(glow.r, glow.g, glow.b, 0.085 * (1.0 - u)))
				canvas.draw_circle(center, 1.2, Color(glow.r, glow.g, glow.b, 0.32 * (1.0 - u)))
