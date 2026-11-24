extends Node2D
## A quiet dark-ground stain per fallen humanoid; cosmetic only and room-local.
## Created on confirmed death, never by damage ticks. Oldest stains are capped.
var seed_value: int = 0
var size_factor: float = 1.0
var ink: Color = Color("481d2b")
var age: float = 0.0
const LIFETIME: float = 75.0
var outline: PackedVector2Array = PackedVector2Array()
var lobes: Array[Dictionary] = []
var flecks: Array[Vector2] = []

func _ready() -> void:
    z_index = -4  # Above z=-50 room paintings, below actors and foreground.
    add_to_group("v149_blood_pools")
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = maxi(1, absi(seed_value) + absi(roundi(global_position.x * 19.0)) * 13 + absi(roundi(global_position.y * 23.0)) * 11)
    var r: float = 22.0 * clampf(size_factor, 0.6, 2.2)
    for i in range(32):
        var a: float = TAU * float(i) / 32.0
        var v: float = r * rng.randf_range(0.70, 1.21)
        outline.append(Vector2(cos(a) * v, sin(a) * v * 0.40) + Vector2(0.0, 3.0))
    for i in range(5):
        lobes.append({"at": Vector2(rng.randf_range(-r, r), rng.randf_range(-r * 0.30, r * 0.30)), "r": rng.randf_range(r * 0.18, r * 0.38)})
    for i in range(8):
        flecks.append(Vector2(rng.randf_range(-r * 1.5, r * 1.5), rng.randf_range(-r * 0.52, r * 0.52)))

func _process(delta: float) -> void:
    age += delta
    if age >= LIFETIME:
        queue_free()
        return
    # No need to redraw opaque static puddles every frame for a full minute.
    if age < 1.0 or age > LIFETIME - 12.0:
        queue_redraw()

func _draw() -> void:
    var grow: float = clampf(age / 0.92, 0.06, 1.0)
    var fade: float = clampf((LIFETIME - age) / 12.0, 0.0, 1.0)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2(grow, grow))
    draw_colored_polygon(outline, Color(ink.r * 0.63, ink.g * 0.63, ink.b * 0.71, 0.68 * fade))
    for lobe in lobes:
        var at: Vector2 = lobe["at"]
        var r: float = float(lobe["r"])
        draw_set_transform(at * grow, 0.0, Vector2(grow, grow * 0.46))
        draw_circle(Vector2.ZERO, r, Color(ink.r, ink.g, ink.b, 0.40 * fade))
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
    for point in flecks:
        draw_circle(point * grow, 1.5 * size_factor, Color(ink.r, ink.g * 0.75, ink.b, 0.22 * fade))
