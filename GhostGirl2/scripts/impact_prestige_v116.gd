extends Node2D
## One strictly visual effect per confirmed blade/wand contact. No hitboxes.
## Item seed picks the shape; cosmetic palettes supply the colour.
var kind: String = "blood"
var primary: Color = Color("b44a63")
var secondary: Color = Color("e19bb4")
var style: int = 0
var tier: int = 0
var heading: Vector2 = Vector2.RIGHT
var age: float = 0.0
var lifetime: float = 0.75
var phase: float = 0.0

func configure(effect_kind: String, ink: Color, accent: Color, variant: int, rarity: int, direction: Vector2 = Vector2.RIGHT, seed_value: int = 0) -> void:
    kind = effect_kind
    primary = ink
    secondary = accent
    style = variant
    tier = rarity
    heading = direction.normalized() if direction.length_squared() > 0.01 else Vector2.RIGHT
    phase = float(posmod(seed_value, 360)) * PI / 180.0
    lifetime = 0.96 if (style >= 3 and tier >= 2) else 0.68
    z_index = 48

func _ready() -> void:
    self_modulate.a = 0.65

func _process(delta: float) -> void:
    age += delta
    if age >= lifetime:
        queue_free()
    else:
        queue_redraw()

func _draw() -> void:
    var t: float = clampf(age / lifetime, 0.0, 1.0)
    var fade: float = pow(1.0 - t, 1.35)
    var horizontal: Vector2 = Vector2(-heading.y, heading.x)
    if kind == "blood":
        # Stylised crimson/rose spatter: decisive short directional burst,
        # then falling beads. Sanguine Cascade (style 4) adds many more beads.
        var base_red: Color = Color("b34a63").lerp(primary, 0.19)
        var edge_red: Color = Color("ef7c91").lerp(secondary, 0.25)
        var count: int = 14 + style * 4 + tier * 2
        if style == 4:
            count += 14
        draw_circle(Vector2(0, 1), 13.0 + 16.0 * t, Color(base_red.r, base_red.g, base_red.b, 0.21 * fade))
        for i in range(count):
            var f: float = float(i) / float(maxi(1, count))
            var a: float = f * 21.991 + phase + float(style) * 0.47
            var spread: float = (15.0 + float(i % 7) * 4.2 + float(style) * 3.0) * 1.22
            var front: Vector2 = heading * spread * (0.40 + t * 1.05)
            var side: Vector2 = horizontal * sin(a) * spread * (0.20 + t * 0.67)
            var fall: Vector2 = Vector2(0, 22.0 * t * t + float(i % 4) * t * 4.0)
            var p: Vector2 = front + side + fall
            var tint: Color = base_red if i % 4 != 0 else edge_red
            var size: float = (1.7 + float(i % 4) * 0.92) * (1.0 - t * 0.45)
            draw_circle(p, size, Color(tint.r, tint.g, tint.b, fade * 0.82))
            if style >= 2 and i % 4 == 0:
                draw_line(p - heading * 5.0, p + heading * 2.0, Color(tint.r, tint.g, tint.b, fade * 0.52), maxf(0.8, size * 0.66), true)
        if style >= 3 and tier >= 2:
            for j in range(5):
                var r: float = 8.0 + float(j) * 8.2 + t * 9.0
                draw_arc(Vector2.ZERO, r, phase + float(j) * 0.9, phase + float(j) * 0.9 + PI * 0.54, 12, Color(edge_red.r, edge_red.g, edge_red.b, fade * 0.36), 1.1, true)
    elif kind == "finisher":
        var radius: float = 16.0 + 65.0 * t
        draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(primary.r, primary.g, primary.b, fade * 0.9), 3.0, true)
        draw_arc(Vector2.ZERO, radius * 0.72, 0.0, TAU, 32, Color(secondary.r, secondary.g, secondary.b, fade * 0.65), 1.5, true)
        for i in range(8):
            var axis: Vector2 = Vector2.from_angle(phase + TAU * float(i) / 8.0)
            draw_line(axis * radius * 0.8, axis * radius * 1.18, Color(secondary.r, secondary.g, secondary.b, fade * 0.8), 2.0, true)
    else:
        # Wand hits: different ring, fractured-prism, petal and star styles.
        var radius: float = 12.0 + 55.0 * t
        var a: Color = primary.lerp(secondary, 0.5 + 0.5 * sin(age * 12.0 + phase))
        draw_circle(Vector2.ZERO, radius * 0.62, Color(a.r, a.g, a.b, fade * 0.10))
        draw_arc(Vector2.ZERO, radius, phase, phase + TAU, 42, Color(primary.r, primary.g, primary.b, fade * 0.71), 1.4 + tier * 0.3, true)
        draw_arc(Vector2.ZERO, radius * 0.74, -phase, -phase + TAU, 40, Color(secondary.r, secondary.g, secondary.b, fade * 0.42), 1.1, true)
        var count: int = 8 + 3 * style + 2 * tier
        for i in range(count):
            var angle: float = TAU * float(i) / float(count) + phase + (t * 1.5 if style % 2 == 1 else 0.0)
            var dist: float = (9.0 + float(i % 3) * 4.0) + t * (44.0 + float(style) * 7.0)
            var p: Vector2 = Vector2.from_angle(angle) * dist
            var c: Color = primary if i % 2 == 0 else secondary
            if style == 1 or style == 4:
                draw_line(p - Vector2.from_angle(angle) * 5.0, p + Vector2.from_angle(angle) * 5.0, Color(c.r,c.g,c.b,fade * 0.82), 1.8, true)
            elif style == 2:
                draw_arc(p, 4.2, angle, angle + PI * 1.55, 8, Color(c.r,c.g,c.b,fade * 0.79), 1.7, true)
            elif style == 3:
                draw_line(p + Vector2(-5,0),p + Vector2(5,0),Color(c.r,c.g,c.b,fade * 0.83),1.3,true)
                draw_line(p + Vector2(0,-5),p + Vector2(0,5),Color(c.r,c.g,c.b,fade * 0.83),1.3,true)
            else:
                draw_circle(p, 2.0 + float(i % 3), Color(c.r,c.g,c.b,fade * 0.8))
        if style >= 3 and tier >= 2:
            for j in range(6):
                var angle: float = phase + TAU * float(j) / 6.0 + t * 0.7
                var p: Vector2 = Vector2.from_angle(angle) * (radius * 0.77)
                draw_line(Vector2.ZERO, p, Color(secondary.r, secondary.g, secondary.b, 0.10 * fade), 1.0, true)
