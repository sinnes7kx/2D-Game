extends RefCounted
## Existing particle seed selects motion independently from color and rarity.
const FX = preload("res://scripts/fx_intensity_v1924.gd")
static func offset(pattern: int, u: float, phase: float, radius: Vector2) -> Vector2:
    var a: float = u * TAU + phase
    var travel: float = fposmod(u + phase / TAU, 1.0)
    var p: Vector2
    match posmod(pattern, 8):
        0: p = Vector2(cos(a), sin(a))
        1: # Zigzag: sweep across the weapon with alternating angular turns.
            p = Vector2(2.0 * travel - 1.0, 1.0 - 4.0 * absf(fposmod(travel * 3.0, 1.0) - 0.5))
        2: # Expanding spiral; particles fade at the wrap point.
            p = Vector2(cos(a * 2.0), sin(a * 2.0)) * (0.18 + 0.82 * travel)
        3: p = Vector2(sin(a), sin(a * 2.0) * 0.8) # Figure eight.
        4: p = Vector2(cos(a), sin(a)) * (0.58 + 0.42 * cos(a * 5.0)) # Rose.
        5: p = Vector2(sin(a * 2.0), cos(a * 3.0)) # Woven currents.
        6: p = Vector2(2.0 * travel - 1.0, sin(travel * TAU * 2.0 + phase)) # Traveling wave.
        _: p = Vector2(cos(a), sin(a)) * (0.50 + 0.50 * sin(phase * 2.0 + u * TAU)) # Breathing burst.
    return p * radius

static func draw_pattern(canvas: Node2D, center: Vector2, axis: Vector2, radius: Vector2, colors: Array[Color], look: Dictionary, time: float, strength: float = 1.0) -> void:
    if colors.is_empty() or strength <= 0.0 or FX.intensity <= 0.0:
        return
    var tier: int = clampi(int(look.get("particle_tier", 0)), 0, 6)
    var pattern: int = posmod(int(look.get("particle", 0)), 8)
    var motif: int = int(look.get("glow_motif", 0))
    var count: int = 4 + tier
    var phase: float = time * (1.3 + float(tier) * 0.12)
    var tangent: Vector2 = axis.normalized() if not axis.is_zero_approx() else Vector2.RIGHT
    var normal: Vector2 = tangent.orthogonal()
    for i in range(count):
        var u: float = float(i) / float(count)
        var at: Vector2 = offset(pattern, u, phase, radius)
        var point: Vector2 = center + tangent * at.x + normal * at.y
        var f: float = fposmod(u + phase / TAU, 1.0)
        var fade: float = sin(f * PI) if pattern in [1,2,6] else 0.85
        var ink: Color = colors[i % colors.size()].lerp(Color.WHITE, 0.18)
        ink.a = FX.edge_alpha(canvas, clampf(0.52 * strength * fade, 0.0, 1.0))
        var previous: Vector2 = offset(pattern, u, phase - 0.12, radius)
        if previous.distance_to(at) < radius.length() * 0.4:
            var trail: Color = ink
            trail.a *= 0.42
            canvas.draw_line(center + tangent * previous.x + normal * previous.y, point, trail, 1.0, true)
        # Glow remains visible underneath all eight motion patterns.
        canvas.draw_circle(point, 5.0, Color(ink.r, ink.g, ink.b, ink.a * 0.10))
        canvas.draw_circle(point, 2.8, Color(ink.r, ink.g, ink.b, ink.a * 0.27))
        if motif % 3 == 1:
            canvas.draw_line(point - tangent * 2.0, point + tangent * 2.0, ink, 1.0, true)
            canvas.draw_line(point - normal * 2.0, point + normal * 2.0, ink, 1.0, true)
        else:
            canvas.draw_circle(point, 1.15 + tier * 0.10, ink)
