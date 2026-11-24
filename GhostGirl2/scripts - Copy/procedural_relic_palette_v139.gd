extends RefCounted
class_name GhostProceduralRelicV139
## A style grammar, not hand-authored per-item effects. Every channel uses its
## own seeded PRNG stream; visuals do not re-roll each frame or change stats.
## Works for bows, scythes, swords, halberds and wands.
static func build(seed_value: int, quality: String, element_hint: int = 0) -> Dictionary:
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = absi(seed_value) * 71 + 139001
    var quality_tier: int = GhostWeaponFXLibrary.tier(quality)
    var hue: float = rng.randf()
    var hue_delta: float = rng.randf_range(0.09, 0.48)
    var saturation: float = rng.randf_range(0.27, 0.86)
    var brightness: float = rng.randf_range(0.64, 0.99)
    if element_hint == 1:
        hue = rng.randf_range(0.015, 0.105) # fire
    elif element_hint == 2:
        hue = rng.randf_range(0.50, 0.63) # frost
    elif element_hint == 3:
        hue = rng.randf_range(0.10, 0.19) # warm light
        saturation *= 0.55
    var primary: Color = Color.from_hsv(hue, saturation, brightness)
    var secondary: Color = Color.from_hsv(fposmod(hue + hue_delta, 1.0), saturation * rng.randf_range(0.4, 0.95), minf(1.0, brightness + 0.06))
    return {
        "primary": primary.to_html(false),
        "secondary": secondary.to_html(false),
        "gradient_angle": rng.randf_range(-PI, PI),
        "gradient_speed": rng.randf_range(0.16, 1.15),
        "pulse_speed": rng.randf_range(0.7, 3.8),
        "spark_size": rng.randf_range(0.8, 3.2),
        "spark_count": mini(24, 3 + quality_tier * 3 + rng.randi_range(0, 7)),
        "orbit_radius": rng.randf_range(9.0, 29.0) + quality_tier * 2.0,
        "ribbon_count": rng.randi_range(1, mini(5, 1 + quality_tier)),
        "geometry": rng.randi_range(0, 5),
        "motion": rng.randi_range(0, 4),
        "spin": rng.randf_range(-2.3, 2.3),
        "phase": rng.randf_range(0.0, TAU),
        "rare": quality_tier >= 2,
        "tier": quality_tier,
    }

static func color_at(look: Dictionary, time: float, ratio: float = 0.5) -> Color:
    var base: Color = Color(str(look.get("primary", "dba2eb")))
    var second: Color = Color(str(look.get("secondary", "badbfb")))
    var angle: float = float(look.get("gradient_angle", 0.0))
    var speed: float = float(look.get("gradient_speed", 0.5))
    var shift: float = 0.5 + 0.5 * sin(time * speed + angle + ratio * PI)
    return base.lerp(second, shift)
