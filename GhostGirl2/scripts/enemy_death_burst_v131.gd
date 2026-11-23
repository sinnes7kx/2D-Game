extends Node2D
## Short, cosmetic death dissolution, with a different silhouette for each
## enemy family. Does not spawn hitboxes, loot, extra drops, or gameplay rays.
## All motion is pre-seeded; death animations do not reroll while running.
const LIFE: float = 0.84
var kind: String = "wraith"
var seed_value: int = 0
var elite: bool = false
var ink: Color = Color("c8a4d2")
var accent: Color = Color("e7d8ec")
var age: float = 0.0
var shards: Array[Dictionary] = []

func _ready() -> void:
    z_index = 32
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = absi(seed_value) + 131908
    var total: int = 12 if kind == "moth" else (10 if kind == "lantern" else (15 if elite else 9))
    for n in range(total):
        var angle: float = rng.randf_range(0.0, TAU)
        var force: float = rng.randf_range(42.0, 125.0) * (1.20 if elite else 1.0)
        shards.append({
            "velocity": Vector2.from_angle(angle) * force + Vector2(0.0, -22.0),
            "spin": rng.randf_range(-4.0, 4.0),
            "phase": rng.randf_range(0.0, TAU),
            "radius": rng.randf_range(2.4, 6.4)
        })

func _process(delta: float) -> void:
    age += delta
    if age >= LIFE:
        queue_free()
        return
    queue_redraw()

func _draw() -> void:
    var t: float = clampf(age / LIFE, 0.0, 1.0)
    var fade: float = pow(1.0 - t, 1.65)
    var base: Vector2 = Vector2(0, -26)
    var diameter: float = (25.0 + t * 37.0) * (1.25 if elite else 1.0)
    draw_circle(base, diameter, Color(ink.r, ink.g, ink.b, 0.10 * fade))
    draw_arc(base, diameter * 0.68, t * 1.3, t * 1.3 + PI * 1.56, 28, Color(accent.r, accent.g, accent.b, 0.60 * fade), 2.0, true)
    for n in range(shards.size()):
        var part: Dictionary = shards[n]
        var velocity: Vector2 = part["velocity"]
        var phase: float = float(part["phase"]) + float(part["spin"]) * t
        var shard_pos: Vector2 = base + velocity * (age * (1.0 - 0.24 * t))
        shard_pos.y += 60.0 * t * t
        var radius: float = float(part["radius"]) * (1.0 - t * 0.65)
        var c: Color = ink.lerp(accent, float(n % 5) / 4.0)
        c.a = 0.72 * fade
        match kind:
            "moth":
                # Fading translucent wing/petal silhouette.
                var wing: Vector2 = Vector2.from_angle(phase) * radius * 1.8
                draw_colored_polygon(PackedVector2Array([shard_pos - wing, shard_pos + wing.rotated(0.9), shard_pos + wing, shard_pos + wing.rotated(-0.9)]), c)
            "lantern":
                # Tiny broken stained-glass shards, not extra projectiles.
                var corner: Vector2 = Vector2.from_angle(phase) * radius
                draw_colored_polygon(PackedVector2Array([shard_pos + corner * 1.4, shard_pos + corner.rotated(2.2), shard_pos + corner.rotated(4.2)]), c)
                if n % 3 == 0:
                    draw_line(shard_pos, shard_pos - velocity.normalized() * (10.0 * fade), c, 1.3, true)
            "hunter":
                draw_line(shard_pos - Vector2.from_angle(phase) * radius, shard_pos + Vector2.from_angle(phase) * radius, c, 2.0, true)
            _:
                draw_circle(shard_pos, radius * 0.65, c)
                if n % 3 == 0:
                    draw_arc(shard_pos, radius * 1.25, phase, phase + PI * 1.1, 12, c, 1.1, true)
    if elite:
        draw_arc(base, diameter * 1.12, -age * 2.1, PI * 0.95 - age * 2.1, 32, Color(accent.r, accent.g, accent.b, 0.46 * fade), 2.2, true)
