extends RefCounted
## Seeded surface pigment. Pure functions permit exact preview and testing.
## Surface pigment is not light, damage, a particle emitter or a new item roll.
const FX_LEVEL = preload("res://scripts/fx_intensity_v1924.gd")
const LABELS: Array[String] = ["Brushed Steel", "Damascus", "Opal Veins", "Flowing Runes", "Spectral Glass", "Starfield", "Prismatic Fracture"]

static func surface_for_ticket(ticket: int, tier: int) -> int:
	# Higher material rarity unlocks additional surface families, independent
	# of quality, shape, guard and existing glow. Every lower family remains possible.
	var maximum: int = clampi(tier + 1, 1, 6)
	return posmod(ticket, maximum + 1)

static func animated(mode: int) -> bool:
	return mode >= 2

static func sample(u: float, v: float, phase: float, mode: int, seed_phase: float, speed: float) -> float:
	var t: float = phase * speed + seed_phase * TAU
	match mode:
		0: return 0.22 + 0.12 * sin(u * 115.0 + v * 7.0 + seed_phase * TAU)
		1: return 0.5 + 0.5 * sin(u * 37.0 + sin(v * 7.0 + seed_phase * TAU) * 2.8)
		2: return pow(0.5 + 0.5 * sin(u * 21.0 + v * 6.0 + t), 3.0)
		3: return pow(0.5 + 0.5 * cos(u * 40.0 - t * 2.0), 6.0)
		4: return 0.5 + 0.5 * sin(u * 10.0 + v * 3.0 - t + sin(u * 18.0 + t))
		5: return 0.35 + 0.35 * sin(u * 13.0 - t + v * 4.0) + 0.3 * pow(maxf(0.0, sin(u * 71.0 + v * 39.0 + seed_phase * TAU)), 9.0)
		6: return 0.5 + 0.5 * sin(u * 27.0 + v * 11.0 + t * 1.5 + sin(u * 59.0 - t))
	return 0.0

# Cross-section interpolation uses the exact outline, including needle and
# waist profiles. Every mark stays inside the physical metal.
static func at_edge(points: PackedVector2Array, u: float) -> Vector2:
	var t: float = clampf(u, 0.0, 1.0)
	if t <= 0.30:
		return points[0].lerp(points[1], t / 0.30)
	if t <= 0.76:
		return points[1].lerp(points[2], (t - 0.30) / 0.46)
	return points[2].lerp(points[3], (t - 0.76) / 0.24)

static func surface_color(profile: Dictionary, u: float, v: float, phase: float) -> Color:
	var mode: int = int(profile.get("surface_mode", 0))
	var weight: float = clampf(sample(u, v, phase, mode, float(profile.get("surface_phase", 0.0)), float(profile.get("surface_speed", 1.0))), 0.0, 1.0)
	var metal: Color = profile["metal"] if v < 0.5 else profile["shade"]
	var accent: Color = profile["accent"]
	var colors: Array = profile.get("surface_colors", [])
	if not colors.is_empty():
		var shift: float = u + (phase * float(profile.get("surface_speed",0.5)) * 0.12 if animated(mode) else 0.0)
		accent = GhostCosmeticRNGV152.sample_palette(colors, shift, animated(mode))

	return metal.lerp(accent, minf(0.85, weight * (0.18 if mode < 2 else 0.48) * FX_LEVEL.intensity))

static func draw_surface(canvas: Node2D, left: PackedVector2Array, right: PackedVector2Array, profile: Dictionary, phase: float) -> void:
	# Split each cross section at the bevel; leave the true cutting edge
	# and center ridge intact. Include exact outline breakpoints to avoid
	# quads crossing narrow curved shoulders.
	var cuts: Array[float] = [0.03, 0.10, 0.17, 0.24, 0.30, 0.37, 0.44, 0.51, 0.58, 0.65, 0.72, 0.76, 0.83, 0.90, 0.96]
	for i in range(cuts.size() - 1):
		var a: float = cuts[i]
		var b: float = cuts[i+1]
		var la: Vector2 = at_edge(left, a)
		var ra: Vector2 = at_edge(right, a)
		var lb: Vector2 = at_edge(left, b)
		var rb: Vector2 = at_edge(right, b)
		for j in range(4):
			var v0: float = 0.08 + float(j) * 0.21
			var v1: float = v0 + 0.21
			# Interpolate pigment across adjacent cells rather than painting
			# visible flat squares. Keep a crisp center ridge on both faces.
			var va: float = v0 if j != 2 else 0.501
			var vb: float = v1 if j != 1 else 0.499
			var inks: PackedColorArray = PackedColorArray([surface_color(profile,a,va,phase),surface_color(profile,b,va,phase),surface_color(profile,b,vb,phase),surface_color(profile,a,vb,phase)])
			for k in range(4):
				var ink: Color = inks[k]
				ink.a = FX_LEVEL.alpha(0.64)
				inks[k] = ink
			canvas.draw_polygon(PackedVector2Array([la.lerp(ra,v0),lb.lerp(rb,v0),lb.lerp(rb,v1),la.lerp(ra,v1)]), inks)
	# Small rune strokes or distant stars inside the actual steel, never
	# outside the outline. No glow sprite or additional hit.
	var mode: int = int(profile.get("surface_mode", 0))
	if mode not in [3, 5]:
		return
	for i in range(5):
		var u: float = 0.12 + 0.76 * fposmod(float(i)*0.21 + (phase*0.08 if mode == 3 else float(profile.get("surface_phase",0.0))),1.0)
		var l: Vector2 = at_edge(left,u)
		var r: Vector2 = at_edge(right,u)
		var p: Vector2 = l.lerp(r,0.31 if i%2==0 else 0.66)
		var tint: Color = profile["edge"]
		tint.a = FX_LEVEL.alpha(0.20 + 0.20 * (0.5 + 0.5*sin(phase*1.8+float(i))))
		if mode == 3:
			canvas.draw_line(l.lerp(r,0.28),l.lerp(r,0.72),tint,0.65,true)
		else:
			canvas.draw_circle(p,minf(0.7,l.distance_to(r)*0.09),tint)
