extends RefCounted
## Existing particle seed selects motion independently from color and rarity.
const FX = preload("res://scripts/fx_intensity_v1924.gd")
const RNG = preload("res://scripts/cosmetic_rng_v152.gd")
static func offset(pattern: int, u: float, phase: float, radius: Vector2) -> Vector2:
    var a: float = u * TAU + phase
    var travel: float = fposmod(u + phase / TAU, 1.0)
    var p: Vector2
    match posmod(pattern, 8):
        0: p = Vector2(cos(a), sin(a))
        1: # Zigzag: sweep across the weapon with alternating angular turns.
            p = Vector2(2.0 * travel - 1.0, 0.52 * sin(travel * TAU * 2.0))
        2: # Expanding spiral; particles fade at the wrap point.
            p = Vector2(cos(a * 1.5), sin(a * 1.5)) * (0.18 + 0.82 * travel)
        3: p = Vector2(sin(a), sin(a * 2.0) * 0.8) # Figure eight.
        4: p = Vector2(cos(a), sin(a)) * (0.58 + 0.42 * cos(a * 3.0)) # Rose.
        5: p = Vector2(sin(a * 1.0), cos(a * 2.0) * 0.65) # Woven currents.
        6: p = Vector2(2.0 * travel - 1.0, sin(travel * TAU * 2.0 + phase)) # Traveling wave.
        _: p = Vector2(cos(a), sin(a)) * (0.50 + 0.50 * sin(phase * 2.0 + u * TAU)) # Breathing burst.
    return p * radius

static func draw_pattern(canvas: Node2D, center: Vector2, axis: Vector2, radius: Vector2, colors: Array[Color], look: Dictionary, time: float, strength: float = 1.0) -> void:
    if colors.is_empty() or strength <= 0.0 or FX.intensity <= 0.0:
        return
    var tier: int = clampi(int(look.get("particle_tier", 0)), 0, 6)
    var prism: bool = bool(look.get("prism", false))
    var pattern: int = posmod(int(look.get("particle", 0)), 8) if prism else 0
    var motif: int = int(look.get("glow_motif", 0))
    var count: int = 2 + mini(tier / 2, 3)
    var phase: float = time * (0.40 + float(tier) * 0.035)
    var tangent: Vector2 = axis.normalized() if not axis.is_zero_approx() else Vector2.RIGHT
    var normal: Vector2 = tangent.orthogonal()
    for i in range(count):
        var u: float = float(i) / float(count)
        var at: Vector2 = offset(pattern, u, phase, radius)
        at.y += sin(time * 0.43 + u * TAU) * 1.4
        var point: Vector2 = center + tangent * at.x + normal * at.y
        var f: float = fposmod(u + phase / TAU, 1.0)
        var fade: float = sin(f * PI) if pattern in [1,2,6] else 0.85
        var ink: Color = (RNG.sample_palette(colors, u + time * 0.13, true) if prism else colors[i % colors.size()]).lerp(Color.WHITE, 0.18)
        ink.a = FX.edge_alpha(canvas, clampf(0.52 * strength * fade, 0.0, 1.0))
        var previous: Vector2 = offset(pattern, u, phase - 0.22, radius)
        if previous.distance_to(at) < radius.length() * 0.4:
            var trail: Color = ink
            trail.a *= 0.20
            canvas.draw_line(center + tangent * previous.x + normal * previous.y, point, trail, 2.1, true)
        # Layered translucent wisp, without bright insect-like crosses.
        var pulse: float = 0.80 + 0.20 * sin(time * 0.7 + u * TAU)
        canvas.draw_circle(point, 7.5, Color(ink.r, ink.g, ink.b, ink.a * 0.055 * pulse))
        canvas.draw_circle(point, 4.7, Color(ink.r, ink.g, ink.b, ink.a * 0.12 * pulse))
        canvas.draw_circle(point, 2.4, Color(ink.r, ink.g, ink.b, ink.a * 0.22 * pulse))
        canvas.draw_circle(point, 0.85 + float(motif % 3) * 0.10, Color(ink.r, ink.g, ink.b, ink.a * 0.48 * pulse))
