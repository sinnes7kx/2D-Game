extends Node2D
## Original falling-star area spell. All decorative stars are non-colliding.
## Exactly one damage hit is applied per enemy in each timed pulse.
@export var radius: float = 178.0
@export var duration: float = 3.45
@export var pulse_interval: float = 0.66
var pulse_damage: float = 10.5
var seed_value: int = 127001
var rarity: int = 0
var primary: Color = Color("c5b3f5")
var secondary: Color = Color("f5d5fa")
var age: float = 0.0
var next_pulse: float = 0.26
var impact_flash: float = 0.0
var stars: Array[Vector2] = []
var phases: Array[float] = []

func _ready() -> void:
    z_index = 28
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = absi(seed_value) + 127117
    for i in range(36):
        var r: float = sqrt(rng.randf()) * radius * 0.90
        stars.append(Vector2.from_angle(rng.randf_range(0, TAU)) * r)
        phases.append(rng.randf_range(0, TAU))

func _physics_process(delta: float) -> void:
    var root: Node = get_tree().current_scene
    if root != null and root.has_node("HUD") and root.get_node("HUD").call("is_menu_open"):
        return
    age += delta
    next_pulse -= delta
    impact_flash = maxf(0.0, impact_flash - delta * 3.0)
    if next_pulse <= 0.0 and age < duration:
        next_pulse += pulse_interval
        impact_flash = 1.0
        _deal_pulse()
    if age >= duration + 0.18:
        queue_free()

func _deal_pulse() -> void:
    var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
    for candidate in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(candidate) or not candidate is Node2D:
            continue
        var enemy: Node2D = candidate as Node2D
        if enemy.is_queued_for_deletion() or enemy.global_position.distance_squared_to(global_position) > radius * radius:
            continue
        var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, enemy.global_position)
        ray.collision_mask = 2 # No star damage through stone.
        if not space.intersect_ray(ray).is_empty():
            continue
        if enemy.has_method("hit"):
            enemy.call("hit", pulse_damage, 0.38)

func _process(_delta: float) -> void:
    queue_redraw()

func _draw() -> void:
    var alpha: float = minf(1.0, age / 0.28) * clampf((duration + 0.18 - age) / 0.55, 0.0, 1.0)
    if alpha <= 0.0:
        return
    draw_circle(Vector2.ZERO, radius, Color(primary.r, primary.g, primary.b, 0.052 * alpha))
    draw_arc(Vector2.ZERO, radius, 0, TAU, 72, Color(primary.r, primary.g, primary.b, 0.26 * alpha), 1.8, true)
    if impact_flash > 0.0:
        draw_arc(Vector2.ZERO, radius * (0.65 + 0.31 * (1.0 - impact_flash)), 0, TAU, 58, Color(secondary.r, secondary.g, secondary.b, impact_flash * alpha * 0.38), 2.7, true)
    for i in range(stars.size()):
        var base: Vector2 = stars[i]
        var phase: float = phases[i]
        var vertical: float = fposmod(age * (180.0 + float(i % 5) * 29.0) + phase * 23.0, 190.0)
        var p: Vector2 = base + Vector2(sin(age * 1.4 + phase) * 7.0, vertical - 120.0)
        if p.length_squared() > radius * radius:
            continue
        var tint: Color = primary if i % 3 else secondary
        var twinkle: float = 0.45 + 0.55 * sin(age * 4.0 + phase)
        var ink: Color = Color(tint.r, tint.g, tint.b, alpha * (0.25 + 0.40 * twinkle))
        draw_line(p - Vector2(0, 4.5), p + Vector2(0, 4.5), ink, 1.25, true)
        draw_line(p - Vector2(3.0, 0), p + Vector2(3.0, 0), ink, 1.1, true)
        if rarity >= 2 and i % 5 == 0:
            draw_arc(p, 7.0, phase + age, phase + age + PI * 1.3, 14, Color(secondary.r, secondary.g, secondary.b, alpha * 0.25), 1.1, true)
        if rarity >= 3 and i % 7 == 0:
            draw_circle(p, 2.4, Color(1.0, 1.0, 1.0, alpha * 0.47))
