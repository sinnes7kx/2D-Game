extends Node2D
## Lingering thorn snare: one hit per enemy over the entire cast, then slows.
## Enemy effects use the existing frost-slow interface; item FX never add hits.
@export var radius: float = 165.0
@export var duration: float = 3.10
var one_hit_damage: float = 14.0
var slow_duration: float = 1.35
var slow_speed: float = 0.31
var seed_value: int = 127002
var rarity: int = 0
var primary: Color = Color("d39ab9")
var secondary: Color = Color("c4a7ed")
var age: float = 0.0
var scan_left: float = 0.16
var hit_ids: Dictionary = {}
var relays_checked: bool = false
var stem_angles: Array[float] = []

func _ready() -> void:
    z_index = 25
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = absi(seed_value) + 127703
    for i in range(19):
        stem_angles.append(rng.randf_range(0.0, TAU))

func _physics_process(delta: float) -> void:
    var root: Node = get_tree().current_scene
    if root != null and root.has_node("HUD") and root.get_node("HUD").call("is_menu_open"):
        return
    age += delta
    scan_left -= delta
    if scan_left <= 0.0 and age < duration:
        scan_left += 0.48
        _ensnare()
    if age >= duration + 0.20:
        queue_free()

func _ensnare() -> void:
    var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
    if not relays_checked:
        relays_checked = true
        _awaken_bloom_relays(space)
    for candidate in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(candidate) or not candidate is Node2D:
            continue
        var enemy: Node2D = candidate as Node2D
        if enemy.is_queued_for_deletion() or enemy.global_position.distance_squared_to(global_position) > radius * radius:
            continue
        var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, enemy.global_position)
        ray.collision_mask = 2
        if not space.intersect_ray(ray).is_empty():
            continue
        var identity: int = enemy.get_instance_id()
        if not hit_ids.has(identity):
            hit_ids[identity] = true
            if enemy.has_method("hit"):
                enemy.call("hit", one_hit_damage, 0.50)
        if is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and enemy.has_method("apply_frost_slow"):
            enemy.call("apply_frost_slow", slow_duration, slow_speed)

func _awaken_bloom_relays(space: PhysicsDirectSpaceState2D) -> void:
    # The same spell can wake a nearby rose seal, but never through masonry.
    for candidate in get_tree().get_nodes_in_group("rose_bloom_relay"):
        if not is_instance_valid(candidate) or not (candidate is Node2D):
            continue
        var relay: Node2D = candidate as Node2D
        if relay.is_queued_for_deletion() or not relay.has_method("on_grasping_roses"):
            continue
        var reach: float = radius + float(relay.get("bloom_radius"))
        if relay.global_position.distance_squared_to(global_position) > reach * reach:
            continue
        var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, relay.global_position)
        ray.collision_mask = 2
        var obstruction: Dictionary = space.intersect_ray(ray)
        var obstacle: Node = obstruction.get("collider") as Node
        # A support's own small hook collision must not block its magic
        # activation. Intervening walls still block the spell.
        if obstruction.is_empty() or (obstacle != null and (obstacle == relay or relay.is_ancestor_of(obstacle))):
            relay.call("on_grasping_roses")

func _process(_delta: float) -> void:
    queue_redraw()

func _draw() -> void:
    var alpha: float = minf(1.0, age / 0.28) * clampf((duration + 0.20 - age) / 0.65, 0.0, 1.0)
    if alpha <= 0.0:
        return
    draw_circle(Vector2.ZERO, radius, Color(primary.r, primary.g, primary.b, 0.038 * alpha))
    draw_arc(Vector2.ZERO, radius, 0.0, TAU, 72, Color(secondary.r, secondary.g, secondary.b, alpha * 0.36), 2.0, true)
    for i in range(stem_angles.size()):
        var theta: float = stem_angles[i]
        var r: float = radius * (0.27 + float(i % 6) * 0.11)
        var origin: Vector2 = Vector2.from_angle(theta) * r
        var bloom: float = sin(age * 1.8 + float(i)) * 8.0
        var tip: Vector2 = origin + Vector2.from_angle(theta + 0.25 * sin(age + float(i))) * (20.0 + bloom)
        draw_line(origin, tip, Color(primary.r, primary.g, primary.b, alpha * 0.36), 1.8, true)
        var ink: Color = Color(secondary.r, secondary.g, secondary.b, alpha * 0.47)
        for n in range(3):
            var petal: Vector2 = tip + Vector2.from_angle(theta + float(n) * TAU / 3.0) * 4.0
            draw_circle(petal, 2.2, ink)
        if rarity >= 2 and i % 3 == 0:
            draw_arc(tip, 9.0, age + theta, age + theta + PI * 1.2, 12, ink, 1.2, true)
        if rarity >= 3 and i % 5 == 0:
            draw_circle(tip, 3.2, Color(secondary.r, secondary.g, secondary.b, alpha * 0.60))
