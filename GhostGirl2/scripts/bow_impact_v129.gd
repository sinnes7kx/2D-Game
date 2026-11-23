extends Node2D
## Cosmetic, single-impact presentation for a physical arrow.
## No collision or damage; even triple-stars are only painted effects.
var ink: Color = Color("e8a5bd")
var accent: Color = Color("b9cafa")
var arrow_heading: Vector2 = Vector2.RIGHT
var motif: int = 0
var rare_variant: int = -1
var rarity: int = 0
var charged: bool = false
var element_index: int = 0
var formation_index: int = 0
var age: float = 0.0
const LIFETIME: float = 0.48

func configure(primary: Color, secondary: Color, variant: int, tier: int, heading: Vector2, is_charged: bool, shape_motif: int) -> void:
    ink = primary
    accent = secondary
    rare_variant = variant
    rarity = maxi(0, tier)
    arrow_heading = heading.normalized() if heading.length_squared() > 0.001 else Vector2.RIGHT
    charged = is_charged
    motif = shape_motif

func _ready() -> void:
    z_index = 45

func _process(delta: float) -> void:
    age += delta
    if age >= LIFETIME:
        queue_free()
    else:
        queue_redraw()

func _draw() -> void:
    var progress: float = clampf(age / LIFETIME, 0.0, 1.0)
    var alpha: float = pow(1.0 - progress, 1.3)
    var size: float = (20.0 if charged else 13.0) + progress * (47.0 if charged else 29.0)
    var pale: Color = ink.lerp(Color.WHITE, 0.42)
    var halo: Color = accent.lerp(ink, 0.30)
    draw_circle(Vector2.ZERO, size * 0.66, Color(halo.r, halo.g, halo.b, 0.10 * alpha))
    draw_arc(Vector2.ZERO, size, -0.42 * PI, 1.47 * PI, 34, Color(pale.r, pale.g, pale.b, alpha * (0.44 if charged else 0.24)), 1.8, true)
    var back: Vector2 = arrow_heading * (-11.0 - progress * 35.0)
    draw_line(Vector2.ZERO, back, Color(ink.r, ink.g, ink.b, alpha * 0.68), 2.0, true)
    var elemental: Color = GhostBowImprintsV138.color_for_element(element_index)
    var ring_radius: float = size * (1.22 if element_index == 3 else 0.88)
    if element_index > 0:
        draw_arc(Vector2.ZERO, ring_radius, progress * PI * 0.4, progress * PI * 0.4 + TAU * 0.86, 38, Color(elemental.r, elemental.g, elemental.b, 0.64 * alpha), 2.5, true)
        for j in range(7 if element_index == 1 else 5):
            var theta: float = float(j) * TAU / float(7 if element_index == 1 else 5) + progress
            var pos: Vector2 = Vector2.from_angle(theta) * size * (0.46 + progress * 0.47)
            if element_index == 2:
                draw_line(pos - Vector2(0, 4), pos + Vector2(0, 4), Color(elemental.r, elemental.g, elemental.b, 0.70 * alpha), 1.4, true)
            else:
                draw_circle(pos, 2.3 + progress * 1.7, Color(elemental.r, elemental.g, elemental.b, 0.55 * alpha))
    if formation_index == 1:
        for offset in [-1.0, 1.0]:
            var side: Vector2 = Vector2(-arrow_heading.y, arrow_heading.x) * offset * (15.0 + progress * 13.0)
            draw_arc(side, size * 0.53, 0.0, TAU * 0.72, 18, Color(elemental.r, elemental.g, elemental.b, 0.31 * alpha), 1.5, true)
    if rarity < 2 or rare_variant < 0:
        for i in range(5):
            var p: Vector2 = Vector2.from_angle(float(i) * TAU / 5.0) * size * 0.73
            draw_circle(p, 1.4, Color(pale.r, pale.g, pale.b, alpha * 0.30))
        return
    # Rare visual variants: one arrow, one resolved hit. No spawned projectiles.
    var count: int = 7 + mini(rarity, 4) * 2
    for i in range(count):
        var phase: float = float(i) * TAU / float(count) + float(posmod(motif, 13)) * 0.15
        var radius: float = size * (0.68 + float(i % 3) * 0.14)
        var p: Vector2 = Vector2.from_angle(phase + progress * 0.55) * radius
        var c: Color = ink if i % 2 == 0 else accent
        c.a = alpha * 0.66
        match rare_variant % 4:
            0: # Rose-comet petals
                var tangent: Vector2 = Vector2.from_angle(phase + PI * 0.5)
                draw_colored_polygon(PackedVector2Array([p - tangent * 3.0, p + Vector2.from_angle(phase) * 6.0, p + tangent * 3.0]), c)
            1: # Crescent halo shards
                draw_arc(p, 4.1 + progress * 2.0, phase, phase + PI * 1.35, 10, c, 1.5, true)
            2: # Frost star needles
                draw_line(p - Vector2(0, 5), p + Vector2(0, 5), c, 1.6, true)
                draw_line(p - Vector2(5, 0), p + Vector2(5, 0), c, 1.4, true)
            _: # Dusk helix fragments
                var spoke: Vector2 = Vector2.from_angle(phase) * (4.0 + progress * 5.0)
                draw_line(p - spoke, p + spoke, c, 1.5, true)
    if rarity >= 3 and charged:
        for n in range(3):
            var a: float = float(n) * TAU / 3.0 + progress * 1.4
            var p: Vector2 = Vector2.from_angle(a) * (size * 0.55)
            draw_circle(p, 3.3, Color(pale.r, pale.g, pale.b, alpha * 0.58))
