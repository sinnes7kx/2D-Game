extends Node2D
## v1.56 — soft lantern-like wand release; cosmetic only, no collision or damage.
var ink_a: Color = Color("a9c9ff")
var ink_b: Color = Color("efb9f1")
var ink_c: Color = Color("f9e4c5")
var motif_phase: float = 0.0
var charged: bool = false
var signature: int = 0
var mythic_variant: int = 0
var age: float = 0.0
const LIFE: float = 0.38

func configure(a: Color, b: Color, c: Color, seed: int, heavy: bool, sig: int, layer_variant: int = 0) -> void:
	ink_a = a
	ink_b = b
	ink_c = c
	motif_phase = float(posmod(seed, 4096)) * TAU / 4096.0
	charged = heavy
	signature = clampi(sig, 0, 5)
	mythic_variant = posmod(layer_variant, 4)
	z_index = 28
	queue_redraw()

func _process(delta: float) -> void:
	age += delta
	if age >= LIFE:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var progress: float = clampf(age / LIFE, 0.0, 1.0)
	var fade: float = pow(1.0 - progress, 1.55)
	var radius: float = (10.0 + 24.0 * progress) * (1.32 if charged else 1.0)
	# Four feathered circles instead of opaque squares/rotating fans.
	draw_circle(Vector2.ZERO, radius * 1.42, Color(ink_a.r, ink_a.g, ink_a.b, 0.018 * fade))
	draw_circle(Vector2.ZERO, radius * 0.84, Color(ink_b.r, ink_b.g, ink_b.b, 0.038 * fade))
	draw_circle(Vector2.ZERO, radius * 0.40, Color(ink_c.r, ink_c.g, ink_c.b, 0.11 * fade))
	draw_circle(Vector2.ZERO, maxf(1.5, radius * 0.13), Color(1.0, 1.0, 1.0, 0.24 * fade))
	var pearl_count: int = 5 + (3 if charged else 0) + signature * 2
	for i in range(pearl_count):
		var u: float = float(i) / float(pearl_count)
		var theta: float = motif_phase + TAU * u + age * 1.4 * (1.0 if i % 2 == 0 else -1.0)
		var p: Vector2 = Vector2(cos(theta), sin(theta) * 0.69) * radius * (0.58 + 0.23 * sin(u * TAU * 2.0))
		var color: Color = ink_a.lerp(ink_b, u * 2.0) if u <= 0.5 else ink_b.lerp(ink_c, (u - 0.5) * 2.0)
		draw_circle(p, 1.2 + float(i % 3) * 0.36, Color(color.r, color.g, color.b, 0.31 * fade))
	# Rare patterns appear as a few firefly-like beads rather than clutter.
	if signature > 0:
		for j in range(signature + 1):
			var angle: float = age * 3.2 + motif_phase + float(j) * TAU / float(signature + 1)
			var tip: Vector2 = Vector2.from_angle(angle) * (radius * 0.48)
			draw_circle(tip, 2.1, Color(ink_c.r, ink_c.g, ink_c.b, 0.22 * fade))

	# A tiny seed-specific release ring for Mythic wands only.
	if signature == 4:
		var star_count: int = 4 + mythic_variant
		for k in range(star_count):
			var a: float = motif_phase + age * (3.6 + float(mythic_variant)) + TAU * float(k) / float(star_count)
			var pos: Vector2 = Vector2(cos(a), sin(a)) * radius * 0.76
			draw_circle(pos, 2.0, Color(ink_b.r, ink_b.g, ink_b.b, 0.20 * fade))
			draw_circle(pos, 0.8, Color(1.0, 1.0, 1.0, 0.22 * fade))
