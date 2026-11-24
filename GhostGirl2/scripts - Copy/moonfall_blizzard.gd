extends Node2D
## v1.25 Moonfall Blizzard — an original area spell. Falling shards are visual.
## Damage is delivered once per enemy at each fixed storm pulse, never once
## per snowflake, and is stopped by solid walls.
@export var storm_radius: float = 190.0
@export var life_seconds: float = 4.2
@export var pulse_seconds: float = 0.70
var damage_per_pulse: float = 7.8
var slow_duration: float = 1.25
var slow_multiplier: float = 0.58
var main_color: Color = Color("bddbff")
var accent_color: Color = Color("ddc6fa")
var appearance_seed: int = 125101
var style_index: int = 0
var age: float = 0.0
var pulse_left: float = 0.22
var pulse_flash: float = 0.0
var snow: Array[Vector2] = []
var dust_phase: Array[float] = []
var frozen_hits: int = 0
# Non-damaging impact diamonds, short-lived and capped per pulse.
var pulse_feedback: Array[Dictionary] = []
var water_checked: bool = false

func _ready() -> void:
    z_index = 30
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = absi(appearance_seed) + 125506
    for i in range(56):
        var a: float = rng.randf_range(0.0, TAU)
        var r: float = sqrt(rng.randf()) * storm_radius * 0.94
        snow.append(Vector2.from_angle(a) * r)
        dust_phase.append(rng.randf_range(0.0, TAU))
    queue_redraw()

func _physics_process(delta: float) -> void:
    var world: Node = get_tree().current_scene
    if world != null and world.has_node("HUD") and world.get_node("HUD").call("is_menu_open"):
        return
    age += delta
    for i in range(pulse_feedback.size() - 1, -1, -1):
        var imprint: Dictionary = pulse_feedback[i]
        imprint["time"] = float(imprint["time"]) - delta
        if float(imprint["time"]) <= 0.0:
            pulse_feedback.remove_at(i)
        else:
            pulse_feedback[i] = imprint
    if not water_checked:
        water_checked = true
        _freeze_nearby_water()
    pulse_left -= delta
    pulse_flash = maxf(0.0, pulse_flash - delta * 2.8)
    if pulse_left <= 0.0 and age <= life_seconds:
        pulse_left += pulse_seconds
        pulse_flash = 1.0
        _apply_storm_pulse()
    if age >= life_seconds + 0.20:
        queue_free()

func _freeze_nearby_water() -> void:
    var frozen_any: bool = false
    for candidate in get_tree().get_nodes_in_group("water_body"):
        if is_instance_valid(candidate) and candidate.has_method("freeze_near"):
            if candidate.call("freeze_near", global_position, storm_radius, life_seconds + 1.1):
                frozen_any = true
    # v1.30 optional relics react only if the caster can reach them without
    # casting through masonry. No extra enemy damage or extra storm pulses.
    var world_space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
    var frost_targets: Array[Node] = get_tree().get_nodes_in_group("v130_triune_relay")
    frost_targets.append_array(get_tree().get_nodes_in_group("v135_frost_targets"))
    for candidate in frost_targets:
        if not is_instance_valid(candidate) or not candidate is Node2D:
            continue
        var relay: Node2D = candidate as Node2D
        if relay.global_position.distance_squared_to(global_position) > pow(storm_radius + 60.0, 2.0):
            continue
        var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, relay.global_position)
        ray.collision_mask = 2
        var obstruction: Dictionary = world_space.intersect_ray(ray)
        var obstacle: Node = obstruction.get("collider") as Node
        if (obstruction.is_empty() or (obstacle != null and (obstacle == relay or relay.is_ancestor_of(obstacle)))) and relay.has_method("on_moonfall"):
            relay.call("on_moonfall")
    if frozen_any:
        var game: Node = get_tree().current_scene
        if game != null and game.has_node("HUD"):
            game.get_node("HUD").call("show_pickup", "MOONFALL FREEZES THE SHALLOW WATER", Color("c6e7ff"))

func _apply_storm_pulse() -> void:
    var physics: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
    for entity in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(entity) or not entity is Node2D:
            continue
        var enemy: Node2D = entity as Node2D
        if enemy.is_queued_for_deletion() or enemy.global_position.distance_squared_to(global_position) > storm_radius * storm_radius:
            continue
        var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, enemy.global_position)
        ray.collision_mask = 2
        if not physics.intersect_ray(ray).is_empty():
            continue
        # Only one hit() per target per storm pulse. A larger sprite effect
        # must never multiply damage, regardless of item quality or color.
        if enemy.has_method("hit"):
            var frost_point: Vector2 = enemy.global_position - global_position + Vector2(0.0, -24.0)
            enemy.call("hit", damage_per_pulse, 0.45)
            frozen_hits += 1
            if pulse_feedback.size() < 8:
                pulse_feedback.append({"point": frost_point, "time": 0.33, "seed": posmod(frozen_hits, 8)})
        if is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and enemy.has_method("apply_frost_slow"):
            enemy.call("apply_frost_slow", slow_duration, slow_multiplier)

func _process(_delta: float) -> void:
    queue_redraw()

func _draw() -> void:
    var appear: float = minf(1.0, age / 0.30)
    var fade: float = clampf((life_seconds + 0.20 - age) / 0.65, 0.0, 1.0)
    var alpha: float = appear * fade
    if alpha <= 0.0:
        return
    var pale: Color = main_color.lerp(Color.WHITE, 0.60)
    var secondary: Color = accent_color.lerp(Color.WHITE, 0.30)
    draw_circle(Vector2.ZERO, storm_radius, Color(main_color.r, main_color.g, main_color.b, 0.055 * alpha))
    draw_arc(Vector2.ZERO, storm_radius, 0.0, TAU, 70, Color(secondary.r, secondary.g, secondary.b, 0.30 * alpha), 2.2, true)
    draw_arc(Vector2.ZERO, storm_radius * 0.78, age * 0.22, age * 0.22 + TAU * 0.75, 58, Color(pale.r, pale.g, pale.b, 0.17 * alpha), 1.25, true)
    if pulse_flash > 0.0:
        draw_arc(Vector2.ZERO, storm_radius * (0.72 + (1.0 - pulse_flash) * 0.27), 0.0, TAU, 64, Color(pale.r, pale.g, pale.b, 0.36 * pulse_flash * alpha), 2.8, true)
    for i in range(snow.size()):
        var origin: Vector2 = snow[i]
        var shift: float = fposmod(age * (92.0 + float(i % 7) * 14.0) + dust_phase[i] * 17.0, 175.0)
        var position: Vector2 = origin + Vector2(sin(age * 1.5 + dust_phase[i]) * 7.0, shift - 95.0)
        if position.length_squared() > storm_radius * storm_radius:
            continue
        var tint: Color = main_color if i % 3 != 0 else accent_color
        var shimmer: float = 0.48 + 0.52 * sin(age * (4.0 + float(i % 4)) + dust_phase[i])
        var ink: Color = Color(tint.r, tint.g, tint.b, (0.30 + 0.35 * shimmer) * alpha)
        var length: float = 8.0 + float(i % 5) * 3.5
        # Ornament styles are cosmetic: celestial needles, lace flakes,
        # thorn splinters, and faint crystalline diamonds.
        match style_index % 4:
            0:
                draw_line(position - Vector2(2, length), position + Vector2(1, length * 0.24), ink, 1.6, true)
            1:
                draw_line(position + Vector2(-length * 0.28, 0), position + Vector2(length * 0.28, 0), ink, 1.4, true)
                draw_line(position + Vector2(0, -length * 0.35), position + Vector2(0, length * 0.35), ink, 1.4, true)
            2:
                draw_colored_polygon(PackedVector2Array([position - Vector2(2, length), position + Vector2(3, -length * 0.45), position + Vector2(0, length * 0.5)]), ink)
            _:
                draw_colored_polygon(PackedVector2Array([position + Vector2(0, -length * 0.45), position + Vector2(2.5, 0), position + Vector2(0, length * 0.45), position - Vector2(2.5, 0)]), ink)
    if style_index >= 4:
        for n in range(9):
            var theta: float = age * 0.42 + TAU * float(n) / 9.0
            var p: Vector2 = Vector2.from_angle(theta) * (storm_radius * 0.52)
            draw_arc(p, 7.0, theta, theta + PI * 1.3, 12, Color(secondary.r, secondary.g, secondary.b, 0.22 * alpha), 1.2, true)

    # v1.29: confirmed-pulse crystal fractures. These never call hit() and
    # have no collision shapes; they simply show which enemies were affected.
    for imprint in pulse_feedback:
        var lifetime: float = clampf(float(imprint["time"]) / 0.33, 0.0, 1.0)
        var progress: float = 1.0 - lifetime
        var point: Vector2 = imprint["point"]
        var radius: float = 9.0 + 24.0 * progress
        var tint: Color = pale if int(imprint["seed"]) % 2 == 0 else secondary
        draw_arc(point, radius, 0.0, TAU, 22, Color(tint.r, tint.g, tint.b, alpha * lifetime * 0.48), 1.6, true)
        for arm in range(4):
            var angle: float = float(arm) * PI * 0.5 + float(imprint["seed"]) * 0.19
            var displacement: Vector2 = Vector2.from_angle(angle) * radius
            draw_line(point + displacement * 0.45, point + displacement, Color(tint.r, tint.g, tint.b, alpha * lifetime * 0.60), 1.4, true)
