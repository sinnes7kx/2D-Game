@tool
extends StaticBody2D
## A reusable tree trap. F latches; Q deliberately fells it toward the puller.
const FEEL = preload("res://scripts/impact_spawner_v149.gd")
const AUDIO = preload("res://scripts/combat_juice_v194.gd")
@export var durability: float = 32.0
@export var fall_length: float = 175.0
@export var shape_seed: int = 0
var health: float = 32.0
var broken: bool = false
var activated: bool = false
var falling: bool = false
var elapsed: float = 0.0
var fall_direction: Vector2 = Vector2.LEFT
var landing_length: float = 175.0
var tether_preview: bool = false
var preview_direction: Vector2 = Vector2.LEFT
var preview_length: float = 175.0
const IMPACT_TIME: float = 0.72
const IMPACT_RADIUS: float = 38.0

func _ready() -> void:
    health = durability
    if Engine.is_editor_hint():
        return
    collision_layer = 2
    collision_mask = 0
    add_to_group("hook_switch")
    add_to_group("fellable_tree")
    add_to_group("breakable_cover")

func hook_prompt() -> String:
    return "" if broken else "F  LATCH TREE · Q  PULL WHEN READY"

func on_hook_latched() -> void:
    pass # No automatic collapse.

func preview_felling_hook(source: Vector2) -> void:
    if broken:
        return
    tether_preview = true
    preview_direction = (source - global_position).normalized()
    preview_length = _clear_fall_length(preview_direction)
    queue_redraw()

func clear_felling_preview() -> void:
    tether_preview = false
    queue_redraw()

func pull_felling_hook(source: Vector2) -> void:
    _start_fall(source - global_position)

func receive_damage(amount: float, source: Vector2 = Vector2.ZERO) -> void:
    if broken or amount <= 0.0:
        return
    health -= amount
    if health <= 0.0:
        _start_fall(global_position - source)
    queue_redraw()

func _start_fall(direction: Vector2) -> void:
    if broken or Engine.is_editor_hint():
        return
    fall_direction = direction.normalized() if direction.length_squared() > 0.01 else Vector2.LEFT
    landing_length = _clear_fall_length(fall_direction)
    tether_preview = false
    broken = true
    activated = true
    falling = true
    elapsed = 0.0
    remove_from_group("hook_switch")
    remove_from_group("fellable_tree")
    remove_from_group("breakable_cover")
    AUDIO.play(get_tree().current_scene, global_position, "arrow_wood", -13.0)

func _clear_fall_length(direction: Vector2) -> float:
    var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, global_position + direction * fall_length)
    ray.collision_mask = 2
    ray.exclude = [get_rid()]
    var wall: Dictionary = get_world_2d().direct_space_state.intersect_ray(ray)
    return fall_length if wall.is_empty() else maxf(0.0, global_position.distance_to(wall["position"]) - 4.0)

func _physics_process(delta: float) -> void:
    if Engine.is_editor_hint() or not falling:
        return
    elapsed += delta
    if elapsed >= IMPACT_TIME:
        falling = false
        set_deferred("collision_layer", 0)
        var end: Vector2 = global_position + fall_direction * landing_length
        FEEL.burst(get_parent(), end, "wood", 1.65, fall_direction, shape_seed)
        FEEL.rumble(end, 5.5)
        AUDIO.play(get_tree().current_scene, end, "arrow_wood", -9.0)
        for candidate in get_tree().get_nodes_in_group("enemies"):
            if not is_instance_valid(candidate) or not candidate is Node2D or candidate.is_queued_for_deletion() or not candidate.has_method("hit"):
                continue
            var point: Vector2 = candidate.global_position
            var closest: Vector2 = Geometry2D.get_closest_point_to_segment(point, global_position, end)
            if point.distance_to(closest) <= IMPACT_RADIUS:
                var probe: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(closest, point)
                probe.collision_mask = 2
                probe.exclude = [get_rid()]
                if closest.is_equal_approx(point) or get_world_2d().direct_space_state.intersect_ray(probe).is_empty():
                    candidate.call("hit", 28.0, 0.85)
    queue_redraw()

func _draw() -> void:
    var progress: float = clampf(elapsed / IMPACT_TIME, 0.0, 1.0) if broken else 0.0
    var tip: Vector2 = Vector2(0, -fall_length).lerp(fall_direction * landing_length, progress * progress)
    draw_ellipse_shadow()
    if falling or tether_preview:
        var end: Vector2 = fall_direction * landing_length if falling else preview_direction * preview_length
        var ink: Color = Color("d6a168") if falling else Color("b99bd0")
        draw_line(Vector2.ZERO, end, Color(ink.r, ink.g, ink.b, 0.16), IMPACT_RADIUS * 2.0, true)
        draw_line(Vector2.ZERO, end, Color(ink.r, ink.g, ink.b, 0.72), 1.4, true)
        draw_arc(end, IMPACT_RADIUS, 0, TAU, 40, Color(ink.r, ink.g, ink.b, 0.45), 1.2, true)
    var axis: Vector2 = tip.normalized()
    var n: Vector2 = axis.orthogonal()
    draw_colored_polygon(PackedVector2Array([-n*14, n*14, tip+n*4, tip-n*4]), Color("302a36"))
    draw_line(n*7, tip, Color("76606a"), 4.0, true)
    for i in range(5):
        var t: float = 0.40 + float(i) * 0.115
        var root: Vector2 = tip * t
        var sign_value: float = -1.0 if (i + shape_seed) % 2 == 0 else 1.0
        var branch: Vector2 = root + n * sign_value * (43.0 - i * 4.0) + axis * 26.0
        draw_line(root, branch, Color("443944"), 8.0 - i, true)
        draw_line(root, branch, Color("85716e"), 1.5, true)
        draw_line(branch, branch + n * sign_value * 13.0 + axis * 17.0, Color("54434d"), 3.0, true)
        draw_circle(branch, 17.0 - i, Color(0.17, 0.23, 0.23, 0.6))
    if broken:
        draw_circle(Vector2.ZERO, 12.0, Color("72565a"))
        draw_arc(Vector2.ZERO, 7.0, 0, TAU, 18, Color("ac8b76"), 1.0, true)
    elif health < durability:
        draw_line(Vector2(-12, -12), Vector2(9, -18), Color("c29a77"), 3.0, true)

func draw_ellipse_shadow() -> void:
    draw_set_transform(Vector2(0, 9), 0.0, Vector2(1.0, 0.48))
    draw_circle(Vector2.ZERO, 37.0, Color(0.02, 0.02, 0.04, 0.28))
    draw_set_transform(Vector2.ZERO)
