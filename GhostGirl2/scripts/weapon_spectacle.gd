extends Node2D
## Lightweight original procedural VFX. No textures or reused copyrighted art.
## Spawned on real hit confirmation; purely visual and automatically freed.
var effect_kind: String = "strike"
var ink: Color = Color("d4b0eb")
var motif: int = 0
var accent: Color = Color("f7d3e9")
var trail_style: int = 0
var rarity: int = 0
var life: float = 0.32
var lifetime: float = 0.32
var facing: Vector2 = Vector2.RIGHT
var caption: Label = null

func configure(kind: String, tint: Color, variant: int, tier: int, heading: Vector2 = Vector2.RIGHT, secondary: Color = Color("f7d3e9"), motion: int = 0) -> void:
	configure_v118(kind, tint, variant, tier, heading, secondary, motion)

func configure_v118(kind: String, tint: Color, variant: int, tier: int, heading: Vector2 = Vector2.RIGHT, secondary: Color = Color("f7d3e9"), motion: int = 0) -> void:
	effect_kind = kind
	ink = tint
	motif = variant
	accent = secondary
	trail_style = motion
	rarity = maxi(0, tier)
	facing = heading.normalized() if heading.length_squared() > 0.01 else Vector2.RIGHT
	lifetime = 0.52 if kind == "riposte" else (0.42 if kind == "ready" else 0.32)
	life = lifetime

func _ready() -> void:
	self_modulate.a = 0.62 # Does not fade the child counter/riposte caption.
	z_index = 44
	if effect_kind in ["riposte", "ready"]:
		caption = Label.new()
		caption.text = "RIPOSTE!" if effect_kind == "riposte" else "COUNTER READY"
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_font_size_override("font_size", 20 if effect_kind == "riposte" else 12)
		caption.add_theme_color_override("font_color", Color("fff2c7") if effect_kind == "riposte" else Color("d1bcf0"))
		caption.add_theme_color_override("font_shadow_color", Color(0.07, 0.03, 0.11, 0.9))
		caption.add_theme_constant_override("shadow_offset_x", 1)
		caption.add_theme_constant_override("shadow_offset_y", 2)
		caption.position = Vector2(-95, -68)
		caption.size = Vector2(190, 36)
		add_child(caption)

func _process(delta: float) -> void:
	life -= delta
	if life <= 0.0:
		queue_free()
		return
	if caption != null:
		var t: float = 1.0 - life / lifetime
		caption.position.y = -68.0 - 18.0 * t
		caption.modulate.a = minf(1.0, life / 0.17)
	queue_redraw()

func _draw() -> void:
	var t: float = clampf(1.0 - life / lifetime, 0.0, 1.0)
	var fade: float = pow(1.0 - t, 1.3)
	var is_counter: bool = effect_kind in ["ready", "riposte"]
	var main: Color = (Color("f9dba8").lerp(ink, 0.28) if is_counter else ink)
	var radius: float = (23.0 if effect_kind == "ready" else (31.0 if effect_kind == "riposte" else 20.0)) + t * (68.0 if effect_kind == "riposte" else 41.0)
	draw_circle(Vector2.ZERO, radius * 0.66, Color(main.r, main.g, main.b, fade * 0.07))
	draw_arc(Vector2.ZERO, radius, -0.18 * PI, 1.82 * PI, 48, Color(main.r, main.g, main.b, fade * (0.88 if is_counter else 0.52)), 3.1 if is_counter else 1.6, true)
	if is_counter:
		draw_arc(Vector2.ZERO, radius * 0.69, 0.0, TAU, 36, Color(1.0, 0.98, 0.89, fade * 0.45), 1.8, true)
	var count: int = (24 if effect_kind == "riposte" else (12 if is_counter else 7 + rarity * 3))
	for i in range(count):
		var theta: float = float(i) * TAU / float(count) + float(motif % 4) * 0.17
		var spread: float = 12.0 + t * (92.0 if effect_kind == "riposte" else (54.0 + rarity * 4.0))
		var wobble: float = sin(float(i * 11 + motif * 7) * 0.77 + t * 5.0) * 7.0
		var p: Vector2 = Vector2.from_angle(theta) * (spread + wobble)
		var size: float = (2.8 + float(i % 4) * 0.8) * (1.0 - 0.42 * t)
		var other: Color = main if i % 2 == 0 else accent
		var color: Color = other.lerp(Color.WHITE, 0.22 + 0.10 * float(i % 3))
		color.a = fade * (0.85 if is_counter else 0.72)
		var twist: float = sin(t * TAU * (1.0 + float(trail_style) * 0.3) + float(i)) * float(trail_style) * 1.2
		p += Vector2.from_angle(theta + PI * 0.5) * twist
		match motif % 10:
			0: # Rose petals
				var tangent: Vector2 = Vector2.from_angle(theta + PI * 0.5)
				draw_colored_polygon(PackedVector2Array([p - tangent * size, p + Vector2.from_angle(theta) * size * 1.65, p + tangent * size, p - Vector2.from_angle(theta) * size * 0.7]), color)
			1: # Starlight needles
				draw_line(p - Vector2.from_angle(theta) * size * 1.7, p + Vector2.from_angle(theta) * size * 1.8, color, 1.8, true)
			2: # Frost crosses
				draw_line(p + Vector2(-size, 0), p + Vector2(size, 0), color, 1.4, true)
				draw_line(p + Vector2(0, -size), p + Vector2(0, size), color, 1.4, true)
			3: # Floating motes
				draw_circle(p, size * 0.7, color)
			4: # Lace shimmer
				draw_arc(p, size * 1.2, 0.20 * PI, 1.90 * PI, 12, color, 1.2, true)
			5: # Thorn halo
				draw_colored_polygon(PackedVector2Array([p - Vector2(3, 2), p + Vector2(size * 1.6, 0), p + Vector2(0, size * 1.3)]), color)
			6: # Astral petals
				draw_colored_polygon(PackedVector2Array([p + Vector2(0, -size), p + Vector2(size * 0.6, 0), p + Vector2(0, size), p + Vector2(-size * 0.6, 0)]), color)
			7: # Silver runes
				draw_line(p + Vector2(-size, -size), p + Vector2(size, size), color, 1.3, true)
				draw_line(p + Vector2(-size * 0.5, size), p + Vector2(size * 0.4, -size), color, 1.3, true)
			8: # Aurora ghostfire
				draw_arc(p + Vector2(0, -size * 0.3), size, PI * 0.1, PI * 1.6, 10, color, 1.4, true)
			9: # Eclipse shards
				draw_colored_polygon(PackedVector2Array([p + Vector2(-size * 0.4, size), p + Vector2(0, -size * 1.8), p + Vector2(size * 0.5, size * 0.4)]), color)
	if effect_kind == "riposte":
		# The secondary color gets its own high-contrast ring on confirmed hits.
		draw_arc(Vector2.ZERO, radius * 0.81, PI * 0.15, PI * 1.75, 38, Color(accent.r, accent.g, accent.b, fade * 0.70), 2.3, true)
		for j in range(4):
			var angle: float = facing.angle() + (float(j) - 1.5) * 0.18
			var origin: Vector2 = Vector2.from_angle(angle) * (16.0 + t * 35.0)
			draw_line(origin, origin + Vector2.from_angle(angle) * (55.0 + t * 30.0), Color(1.0, 0.93, 0.78, fade * 0.85), 3.5, true)
