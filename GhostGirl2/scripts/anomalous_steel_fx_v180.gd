extends RefCounted
## Shared animated color and blade-local motif renderer. All effects are cosmetic.
static func color_at(colors: Array[Color], look: Dictionary, t: float, time: float) -> Color:
	if colors.size() < 3:
		return Color.WHITE
	var mode: int = int(look.get("color_mode", 0))
	var phase: float = time * float(look.get("shift_rate", 0.1))
	var u: float = clampf(t, 0.0, 1.0)
	if mode in [2, 3, 5, 6]:
		u = fposmod(t + phase, 1.0)
	var ink: Color = colors[0].lerp(colors[1], u * 2.0) if u < 0.5 else colors[1].lerp(colors[2], (u - 0.5) * 2.0)
	match mode:
		1: ink = ink.lerp(Color.WHITE, 0.18 + 0.17 * sin(phase * TAU))
		3: ink = Color.from_hsv(fposmod(ink.h + phase * 0.45, 1.0), ink.s, 1.0)
		4: ink = Color.from_hsv(fposmod(ink.h + phase, 1.0), 0.75, 1.0)
		5: ink = ink.lerp(Color.WHITE, pow(maxf(0.0, sin((t - phase) * TAU)), 5.0) * 0.7)
		6: ink = Color.from_hsv(fposmod(ink.h + phase + t * 0.35, 1.0), 0.85, 1.0)
	if int(look.get("material", 0)) == 6 or int(look.get("particle_tier", 0)) == 6:
		ink = Color.from_hsv(fposmod(ink.h + phase * 0.65 + t * 0.45, 1.0), 0.78, 1.0)
	if int(look.get("region_rank", 0)) > 0:
		var local: Color = look.get("region_color", Color.WHITE)
		var dusk: Color = look.get("region_shadow", Color.WHITE)
		var wave: float = 0.5 + 0.5 * sin(time * 1.7 + t * TAU)
		ink = ink.lerp(local.lerp(dusk, wave), 0.18 + 0.08 * float(look["region_rank"]))
	return ink

static func draw_edge(canvas: Node2D, path: PackedVector2Array, colors: Array[Color], look: Dictionary, time: float, strength: float = 1.0) -> void:
	if path.size() < 2:
		return
	var tier: int = maxi(int(look.get("material", 0)), int(look.get("particle_tier", 0)))
	var motif: int = int(look.get("glow_motif", 0))
	var region_rank: int = int(look.get("region_rank", 0))
	var power: float = clampf(strength, 0.65, 2.4)
	for i in range(path.size() - 1):
		for j in range(5):
			var u: float = float(i * 5 + j) / float((path.size() - 1) * 5)
			var a: Vector2 = path[i].lerp(path[i + 1], float(j) / 5.0)
			var b: Vector2 = path[i].lerp(path[i + 1], float(j + 1) / 5.0)
			var ink: Color = color_at(colors, look, u, time)
			canvas.draw_line(a, b, Color(ink.r, ink.g, ink.b, 0.20 * power), 3.6, true)
			canvas.draw_line(a, b, Color(ink.r, ink.g, ink.b, minf(0.95, 0.78 * power)), 1.3, true)
	var root: Vector2 = path[0]
	var tip: Vector2 = path[path.size() - 1]
	var axis: Vector2 = (tip - root).normalized()
	var normal: Vector2 = Vector2(-axis.y, axis.x)
	for j in range(3 + mini(tier, 4)):
		var u: float = fposmod(float(j) * 0.23 + time * (0.13 + float(motif) * 0.018), 1.0)
		var p: Vector2 = root.lerp(tip, u)
		var ink: Color = color_at(colors, look, u, time)
		ink.a = sin(u * PI) * 0.88
		var wiggle: Vector2 = normal * sin(u * TAU * 2.0 + time * 3.0) * 3.0
		match motif:
			0: canvas.draw_circle(p, 1.3, ink)
			1: canvas.draw_line(p - normal * 3.0, p + normal * 3.0, ink, 1.0, true)
			2: canvas.draw_colored_polygon(PackedVector2Array([p, p + wiggle + axis * 2.0, p + wiggle - axis * 2.0]), ink)
			3: canvas.draw_polyline(PackedVector2Array([p - axis * 3.0, p + wiggle, p + axis * 3.0]), ink, 1.0, true)
			4: canvas.draw_arc(p, 2.5, time, time + PI, 10, ink, 1.0, true)
			5: canvas.draw_line(p - axis * 5.0, p + axis * 2.0, ink, 1.4, true)
			6:
				canvas.draw_line(p - normal * 3.0, p + normal * 3.0, ink, 1.0, true)
				canvas.draw_line(p - axis * 3.0, p + axis * 3.0, ink, 1.0, true)
			7: canvas.draw_circle(p + wiggle, 1.7, ink)
		if tier == 6:
			canvas.draw_line(p + wiggle * 1.8, p - wiggle * 1.8 + axis * 2.0, ink, 0.9, true)

	# A distinct local signature accompanies the independent original motif.
	if region_rank > 0:
		var local: Color = look.get("region_color", Color.WHITE)
		var region: String = str(look.get("region", ""))
		for i in range(region_rank + 1):
			var u: float = fposmod(time * 0.16 + float(i) / float(region_rank + 1), 1.0)
			var p: Vector2 = root.lerp(tip, u)
			local.a = sin(u * PI) * 0.68
			match region:
				"moonwake_crypt":
					canvas.draw_arc(p + normal * 2.0, 3.0, time, time + PI, 10, local, 1.1, true)
				"hollow_veil_moor":
					canvas.draw_line(p - axis * 4.0 + normal * 3.0, p + axis * 2.0 + normal * 3.0, local, 2.2, true)
				"ashglass_vault":
					canvas.draw_polyline(PackedVector2Array([p - axis * 3.0, p + normal * 3.0, p + axis * 2.0]), local, 1.3, true)
				"briar_hollow":
					canvas.draw_colored_polygon(PackedVector2Array([p, p + normal * 4.0 - axis * 2.0, p + normal * 3.0 + axis * 2.0]), local)
				"observatory":
					canvas.draw_line(p - axis * 3.0, p + axis * 3.0, local, 1.0, true)
					canvas.draw_line(p - normal * 3.0, p + normal * 3.0, local, 1.0, true)
				"lily_pond":
					canvas.draw_arc(p, 2.8, 0.0, TAU, 12, local, 0.9, true)
