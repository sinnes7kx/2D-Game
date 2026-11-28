extends RefCounted
## Shared animated color and blade-local motif renderer. All effects are cosmetic.
const FX_LEVEL = preload("res://scripts/fx_intensity_v1924.gd")
const PALETTE = preload("res://scripts/cosmetic_rng_v152.gd")

static func color_at(colors: Array[Color], look: Dictionary, t: float, time: float) -> Color:
	if colors.is_empty():
		return Color.WHITE
	var mode: int = int(look.get("color_mode", 0))
	var speed: float = float(look.get("palette_speed", look.get("shift_rate", 0.1)))
	var direction: float = float(look.get("palette_direction", 1.0))
	var phase: float = time * speed * direction
	var spread: float = float(look.get("palette_span", 1.0))
	var offset: float = float(look.get("palette_offset", 0.0))
	var pulse: float = float(look.get("palette_pulse", 0.15))
	var smooth: bool = int(look.get("palette_curve", 0)) != 1
	var u: float = t * spread + offset
	var cycle: bool = false
	var anomaly: bool = int(look.get("material", 0)) == 6 or int(look.get("particle_tier", 0)) == 6
	match mode:
		2:
			u += phase
			cycle = true
		3:
			u += sin(phase * TAU) * 0.33
			cycle = true
		4:
			u += 0.5 + 0.5 * sin(phase * TAU + offset)
			cycle = true
		5:
			u += phase * 0.5
			cycle = true
		6:
			u += phase + sin(t * TAU + phase * TAU) * 0.25
			cycle = true
	if anomaly:
		# Anomaly has a more unusual wave, but NEVER rotates the HSV hue wheel.
		u += phase * 0.7 + sin(t * TAU * spread + phase * TAU) * 0.18
		cycle = true
	var ink: Color = PALETTE.sample_palette(colors, u if cycle else t, cycle, smooth)
	if mode == 1:
		ink = ink.lerp(Color.WHITE, (0.5 + 0.5 * sin(phase * TAU)) * pulse)
	elif mode == 5:
		ink = ink.lerp(Color.WHITE, pow(maxf(0.0, sin((t - phase) * TAU)), 5.0) * pulse)
	if int(look.get("region_rank", 0)) > 0:
		var local: Color = look.get("region_color", Color.WHITE)
		var dusk: Color = look.get("region_shadow", Color.WHITE)
		var wave: float = 0.5 + 0.5 * sin(time * 1.7 + t * TAU)
		ink = ink.lerp(local.lerp(dusk, wave), 0.18 + 0.08 * float(look["region_rank"]))
	return ink

static func draw_edge(canvas: Node2D, path: PackedVector2Array, colors: Array[Color], look: Dictionary, time: float, strength: float = 1.0, details: bool = true) -> void:
	if path.size() < 2 or FX_LEVEL.intensity <= 0.0:
		return
	var tier: int = maxi(int(look.get("material", 0)), int(look.get("particle_tier", 0)))
	var motif: int = int(look.get("glow_motif", 0))
	var region_rank: int = int(look.get("region_rank", 0))
	var power: float = clampf(strength, 0.0, 1.35)
	var protected_top: bool = tier >= 6 or int(look.get("signature",0)) >= 4
	if power <= 0.0:
		return
	for i in range(path.size() - 1):
		for j in range(5):
			var u: float = float(i * 5 + j) / float((path.size() - 1) * 5)
			var a: Vector2 = path[i].lerp(path[i + 1], float(j) / 5.0)
			var b: Vector2 = path[i].lerp(path[i + 1], float(j + 1) / 5.0)
			var ink: Color = color_at(colors, look, u, time)
			# Layered soft bloom and a bright metal-following core. Independent of
			# particle motion; no flat opaque rectangle over the weapon.
			var shimmer: float = 0.90 + 0.10 * sin(time * 1.3 + u * TAU)
			if not protected_top:
				var crest: float = pow(maxf(0.0,cos((u-time*(0.11+float(tier)*0.018))*TAU)),9.0)
				shimmer = (0.50 + float(tier)*0.075) + crest*0.60
			var core: Color = ink.lerp(Color.WHITE, 0.34)
			canvas.draw_line(a, b, Color(ink.r, ink.g, ink.b, FX_LEVEL.edge_alpha(canvas, 0.025 * power)), 8.0, true)
			canvas.draw_line(a, b, Color(ink.r, ink.g, ink.b, FX_LEVEL.edge_alpha(canvas, 0.075 * power)), 5.0, true)
			canvas.draw_line(a, b, Color(ink.r, ink.g, ink.b, FX_LEVEL.edge_alpha(canvas, 0.19 * power)), 2.8, true)
			canvas.draw_line(a, b, Color(core.r, core.g, core.b, FX_LEVEL.edge_alpha(canvas, 0.48 * power * shimmer)), 1.05, true)
	if not details:
		return
	var root: Vector2 = path[0]
	var tip: Vector2 = path[path.size() - 1]
	var axis: Vector2 = (tip - root).normalized()
	var normal: Vector2 = Vector2(-axis.y, axis.x)
	if protected_top:
		for j in range(2 + mini(tier, 3)):
			var u: float = fposmod(float(j) * 0.23 + time * (0.13 + float(motif) * 0.018), 1.0)
			var p: Vector2 = point_on_path(path, u)
			var ink: Color = color_at(colors, look, u, time)
			ink = ink.lerp(Color.WHITE, 0.24)
			ink.a = FX_LEVEL.edge_alpha(canvas, sin(u * PI) * 0.55)
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

	else:
		_draw_tier_detail(canvas,path,colors,look,time,power,tier)

	# A distinct local signature accompanies the independent original motif.
	if region_rank > 0:
		var local: Color = look.get("region_color", Color.WHITE)
		var region: String = str(look.get("region", ""))
		for i in range(region_rank + 1):
			var u: float = fposmod(time * 0.16 + float(i) / float(region_rank + 1), 1.0)
			var p: Vector2 = point_on_path(path, u)
			local.a = FX_LEVEL.edge_alpha(canvas, sin(u * PI) * 0.34)
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

	draw_signature(canvas, path, colors, look, time)

# Shared Collector's Lens / held weapon illumination. Paths are in the
# caller's local weapon coordinates, not the character's world coordinates.
static func blade_light_strength(look: Dictionary, scale: float) -> float:
	return maxf(0.0, float(look.get("glow_strength", 1.0)) * scale)

static func draw_blade_light(canvas: Node2D, paths: Array[PackedVector2Array], colors: Array[Color], look: Dictionary, time: float, scale: float) -> void:
	if scale <= 0.0 or FX_LEVEL.intensity <= 0.0:
		return
	var strength: float = blade_light_strength(look, scale)
	if strength <= 0.0:
		return
	for i in range(paths.size()):
		var path: PackedVector2Array = paths[i]
		if path.size() < 2:
			continue
		draw_edge(canvas, path, colors, look, time, strength, i % 2 == 0)
		for j in range(10):
			var u: float = 0.12 + 0.8 * float(j) / 9.0
			var at: Vector2 = point_on_path(path, u)
			var ink: Color = color_at(colors, look, u, time).lerp(Color.WHITE, 0.25)
			canvas.draw_circle(at, 6.0, Color(ink.r, ink.g, ink.b, FX_LEVEL.edge_alpha(canvas, 0.055 * scale)))
			canvas.draw_circle(at, 2.5, Color(ink.r, ink.g, ink.b, FX_LEVEL.edge_alpha(canvas, 0.19 * scale)))
			canvas.draw_circle(at, 0.9, Color(ink.r, ink.g, ink.b, FX_LEVEL.edge_alpha(canvas, 0.48 * scale)))

static func point_on_path(path: PackedVector2Array, u: float) -> Vector2:
	if path.size() < 2:
		return path[0] if not path.is_empty() else Vector2.ZERO
	var at: float = clampf(u, 0.0, 1.0) * float(path.size() - 1)
	var i: int = mini(floori(at), path.size() - 2)
	return path[i].lerp(path[i + 1], at - float(i))

static func signature_kind(look: Dictionary) -> int:
	var sig: int = int(look.get("signature", 0))
	if maxi(int(look.get("material", 0)), int(look.get("particle_tier", 0))) == 6:
		return 10
	if sig == 4:
		return 6 + clampi(int(look.get("signature_variant", 0)), 0, 3)
	return sig

static func draw_signature(canvas: Node2D, path: PackedVector2Array, colors: Array[Color], look: Dictionary, time: float,scale: float=1.0) -> void:
	if path.size() < 2 or scale<=0.0:
		return
	var kind: int = signature_kind(look)
	if kind == 0:
		return
	var axis: Vector2 = (path[-1] - path[0]).normalized()
	if axis.is_zero_approx():
		return
	var normal: Vector2 = Vector2(-axis.y, axis.x)
	for i in range(3):
		var u: float = 0.12 + 0.76 * fposmod(time * 0.16 + float(i) / 3.0, 1.0)
		var center: Vector2 = point_on_path(path, u)
		var ink: Color = color_at(colors, look, u, time).lerp(Color.WHITE, 0.22)
		ink.a = FX_LEVEL.edge_alpha(canvas, (0.38 + 0.14 * sin(u * PI))*scale)
		var offset: Vector2 = normal * (2.5 + 1.5 * sin(time * 2.0 + float(i)))
		var p: Vector2 = center + offset
		match kind:
			1:
				canvas.draw_polyline(PackedVector2Array([center-axis*3.0,p,center+axis*2.0]),ink,1.0,true)
			2:
				canvas.draw_arc(p,3.3,time,time+PI*1.5,12,ink,1.0,true)
			3:
				canvas.draw_line(p-axis*3.0,p+axis*3.0,ink,1.0,true)
				canvas.draw_line(p-normal*2.6,p+normal*2.6,ink,1.0,true)
			5:
				canvas.draw_arc(p,3.7,time,time+PI*1.2,14,ink,1.1,true)
				canvas.draw_circle(center,0.9,ink)
			6:
				canvas.draw_polyline(PackedVector2Array([center-axis*4.0,p-axis,p+axis,center+axis*4.0]),ink,1.0,true)
			7:
				canvas.draw_circle(p,1.5,ink)
				canvas.draw_line(p-axis*3.0,p,ink,0.8,true)
			8:
				canvas.draw_arc(p,2.0+1.6*sin(u*PI),0.0,TAU,14,ink,0.9,true)
			9:
				canvas.draw_colored_polygon(PackedVector2Array([center,p-axis*2.0,p+normal*1.5,p+axis*2.0]),ink)
			10:
				var zig: Vector2 = normal * sin(time*2.4+float(i)*2.0)*3.0
				canvas.draw_polyline(PackedVector2Array([center-axis*4.0,p-axis*2.0,p+zig,center+axis*4.0]),ink,1.1,true)
				ink.a *= 0.65
				canvas.draw_circle(p+zig,1.2,ink)

# Lower tiers have different silhouettes and cadence, not merely more dots.
# The existing highest-tier and Mythic/Moonfall effects are untouched.
static func _draw_tier_detail(canvas: Node2D,path: PackedVector2Array,colors: Array[Color],look: Dictionary,time: float,power: float,tier: int) -> void:
	var axis: Vector2 = (path[-1]-path[0]).normalized()
	var n: Vector2 = axis.orthogonal()
	if axis.is_zero_approx():
		return
	if tier == 0:
		return # Plain polished edge.
	var count: int = 1 if tier <= 2 else (2 if tier <= 4 else 3)
	for j in range(count):
		var u: float = fposmod(time*(0.075+float(tier)*0.012)+float(j)/float(count),1.0)
		var p: Vector2 = point_on_path(path,u)
		var ink: Color = color_at(colors,look,u,time).lerp(Color.WHITE,0.36)
		var alpha: float = FX_LEVEL.edge_alpha(canvas,sin(u*PI)*power*0.70)
		ink.a = alpha
		match tier:
			1: # A passing silver glint.
				canvas.draw_line(p-axis*3.0,p+axis*3.0,ink,1.5,true)
			2: # A small luminous bead with a soft halo.
				canvas.draw_circle(p,4.0,Color(ink.r,ink.g,ink.b,alpha*0.13))
				canvas.draw_circle(p,1.4,ink)
			3: # A short slow ribbon, bound to the edge.
				canvas.draw_polyline(PackedVector2Array([p-axis*5.0,p+n*2.0,p+axis*4.0]),ink,1.2,true)
			4: # Celestial stars.
				canvas.draw_line(p-axis*3.0,p+axis*3.0,ink,1.0,true)
				canvas.draw_line(p-n*3.5,p+n*3.5,ink,1.0,true)
				canvas.draw_circle(p,1.25,ink)
			5: # Ethereal wisps, not a fast swarm.
				var drift: Vector2 = p+n*sin(time*0.55+float(j)*2.1)*5.0
				canvas.draw_circle(drift,6.0,Color(ink.r,ink.g,ink.b,alpha*0.10))
				canvas.draw_line(drift-axis*5.0,drift,Color(ink.r,ink.g,ink.b,alpha*0.45),2.1,true)
				canvas.draw_circle(drift,2.0,ink)
