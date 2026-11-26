extends Node2D
## A limited-range universal Moonrose Hook:
## Q pulls loose RigidBody2D objects and briefly yanks enemies.
## F reels the player toward ANY solid surface
## hit by a ray (or a rose anchor node), except objects in "hook_blocker".
## Set this group on StaticBody2D, Area2D, or RigidBody2D in Godot's Node tab.

@export_range(60.0, 1000.0, 10.0) var maximum_range: float = 450.0
@export var object_pull_speed: float = 500.0
@export var object_settle_distance: float = 82.0
@export var player_pull_speed: float = 520.0
@export var cast_time: float = 0.20
@export var max_hold_time: float = 2.3
@export_flags_2d_physics var target_mask: int = 22  # World (2), movable (4), enemies (16)

@onready var hook_tip: AnimatedSprite2D = $HookTip
@onready var moon_thread: Line2D = $MoonThread
@onready var impact_petals: CPUParticles2D = $ImpactPetals
@onready var girl: CharacterBody2D = get_parent() as CharacterBody2D

const MODE_NONE: int = 0
const MODE_OBJECT: int = 1
const MODE_ANCHOR: int = 2
const MODE_SWITCH: int = 3
const PHASE_IDLE: int = 0
const PHASE_CAST: int = 1
const PHASE_PULL: int = 2
const PHASE_RETRACT: int = 3

var mode: int = MODE_NONE
var phase: int = PHASE_IDLE
var target: Node2D
var fixed_point: Vector2 = Vector2.ZERO
var start_point: Vector2 = Vector2.ZERO
var end_point: Vector2 = Vector2.ZERO
var clock: float = 0.0
var cooldown: float = 0.0
var safe_cast_origin: Vector2 = Vector2.ZERO
var normal_player_collision_mask: int = 6
var yanked_enemy: bool = false

func _ready() -> void:
    hook_tip.visible = false
    moon_thread.visible = false
    impact_petals.emitting = false
    normal_player_collision_mask = girl.collision_mask

func try_cast_object() -> bool:
    return _cast(MODE_OBJECT)

func try_cast_anchor() -> bool:
    return _cast(MODE_ANCHOR)

func _cast(new_mode: int) -> bool:
    if phase != PHASE_IDLE or cooldown > 0.0 or girl.get("carrying") != null:
        return false
    var from: Vector2 = girl.get_node("Hand").global_position
    var mouse_direction: Vector2 = get_global_mouse_position() - from
    if mouse_direction.length_squared() < 9.0:
        return false
    var destination: Vector2 = from + mouse_direction.normalized() * _effective_range()
    var hit: Dictionary = _raycast(from, destination)
    var point: Vector2 = Vector2.ZERO
    var picked: Node2D = null

    if new_mode == MODE_OBJECT:
        # A wall in front of a crate blocks the hook. No special "hookable"
        # tag is needed on loose rigid bodies.
        if hit.is_empty():
            return false
        var collider: Object = hit.get("collider")
        if _blocked(collider as Node):
            return false
        if not collider is RigidBody2D and not (collider is CharacterBody2D and (collider as Node).is_in_group("enemies")):
            return false
        picked = collider as Node2D
        if picked.is_in_group("carryable") and bool(picked.get("held")):
            return false
        point = hit["position"] as Vector2
    else:
        # Hand-placed rose anchors are optional helpers; normal architecture
        # with real collision is already hookable by default.
        var anchor: Node2D = _find_visible_rose_anchor(from, destination)
        if anchor != null:
            picked = anchor
            point = anchor.global_position
        elif not hit.is_empty():
            var collider: Object = hit.get("collider")
            if not collider is Node2D or _blocked(collider as Node):
                return false
            # A support's physical collider is often a nested HookBody.
            # Resolve its scripted parent so the hook triggers the intended
            # mechanism rather than pulling Ghost Girl into the wall.
            var mechanism: Node2D = _hook_switch_ancestor(collider as Node)
            picked = mechanism if mechanism != null else collider as Node2D
            point = hit["position"] as Vector2
        else:
            return false

    if from.distance_to(point) > _effective_range() + 0.5 or from.distance_to(point) < 45.0:
        return false
    safe_cast_origin = girl.global_position
    target = picked
    yanked_enemy = false
    fixed_point = point
    start_point = from
    end_point = point
    mode = MODE_SWITCH if picked != null and picked.is_in_group("hook_switch") else new_mode
    phase = PHASE_CAST
    clock = 0.0
    hook_tip.visible = true
    hook_tip.global_position = from
    hook_tip.rotation = (point - from).angle()
    hook_tip.play("cast")
    moon_thread.visible = true
    moon_thread.clear_points()
    return true

func _raycast(from: Vector2, to: Vector2) -> Dictionary:
    var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, to)
    query.collision_mask = target_mask
    query.exclude = [girl.get_rid()]
    query.collide_with_areas = false
    return get_world_2d().direct_space_state.intersect_ray(query)

func _hook_switch_ancestor(hit_node: Node) -> Node2D:
    var cursor: Node = hit_node
    while cursor != null and cursor != girl:
        if cursor is Node2D and cursor.is_in_group("hook_switch") and cursor.has_method("on_hook_latched"):
            return cursor as Node2D
        cursor = cursor.get_parent()
    return null

func _blocked(hit_node: Node) -> bool:
    var cursor: Node = hit_node
    while cursor != null:
        if cursor.is_in_group("hook_blocker"):
            return true
        cursor = cursor.get_parent()
    return false

func _find_visible_rose_anchor(from: Vector2, ray_end: Vector2) -> Node2D:
    var ray: Vector2 = ray_end - from
    var best: Node2D = null
    var best_angle: float = 0.87
    var candidates: Array[Node] = get_tree().get_nodes_in_group("hook_anchor")
    candidates.append_array(get_tree().get_nodes_in_group("hook_switch"))
    for candidate in candidates:
        if not is_instance_valid(candidate) or not candidate is Node2D:
            continue
        if _blocked(candidate):
            continue
        var anchor: Node2D = candidate as Node2D
        var vector: Vector2 = anchor.global_position - from
        var distance: float = vector.length()
        if distance > _effective_range() or distance < 50.0:
            continue
        var alignment: float = vector.normalized().dot(ray.normalized())
        if alignment < best_angle:
            continue
        var obstruction: Dictionary = _raycast(from, anchor.global_position)
        if not obstruction.is_empty() and obstruction["position"].distance_to(anchor.global_position) > 24.0:
            continue
        best = anchor
        best_angle = alignment
    return best

func _physics_process(delta: float) -> void:
    cooldown = maxf(0.0, cooldown - delta)
    # Gap-only blockers (collision layer 8) stop walking but not a hook traverse.
    girl.collision_mask = normal_player_collision_mask & ~8 if is_pulling_player() else normal_player_collision_mask
    if phase == PHASE_IDLE:
        return
    if target == null or not is_instance_valid(target):
        _start_retract()
    clock += delta
    if phase == PHASE_CAST:
        var progress: float = clampf(clock / cast_time, 0.0, 1.0)
        hook_tip.global_position = start_point.lerp(end_point, progress)
        if progress >= 1.0:
            phase = PHASE_PULL
            clock = 0.0
            hook_tip.play("latch")
            impact_petals.global_position = end_point
            impact_petals.restart()
            impact_petals.emitting = true
            if is_instance_valid(target) and target.has_method("on_hook_latched"):
                target.call("on_hook_latched")
            if mode == MODE_SWITCH:
                _start_retract()
                return
            if mode == MODE_OBJECT and is_instance_valid(target) and target.is_in_group("enemies"):
                if target.has_method("on_hook_yank"):
                    target.call("on_hook_yank", girl.global_position, object_pull_speed * 0.64)
                yanked_enemy = true
    elif phase == PHASE_PULL:
        if is_instance_valid(target):
            if mode == MODE_OBJECT:
                if target.is_in_group("enemies"):
                    _start_retract()
                    return
                var body: RigidBody2D = target as RigidBody2D
                if body == null or (body.is_in_group("carryable") and bool(body.get("held"))):
                    _start_retract()
                elif body.global_position.distance_to(girl.global_position) < object_settle_distance:
                    body.linear_velocity *= 0.15
                    if body.has_method("on_hook_pulled_to_player"):
                        body.call("on_hook_pulled_to_player", girl.global_position)
                    _start_retract()
                else:
                    end_point = body.global_position
                    hook_tip.global_position = end_point
                    body.sleeping = false
                    body.linear_velocity = (girl.global_position - body.global_position).normalized() * object_pull_speed * (1.0 + _stat("hook_pull_pct") / 100.0)
            else:
                # A fixed world-contact point, not the center of a giant wall.
                end_point = fixed_point
                hook_tip.global_position = fixed_point
                if girl.global_position.distance_to(fixed_point) < 73.0:
                    _start_retract()
        if clock > max_hold_time:
            _start_retract()
    elif phase == PHASE_RETRACT:
        var t: float = clampf(clock / 0.20, 0.0, 1.0)
        var hand: Vector2 = girl.get_node("Hand").global_position
        hook_tip.global_position = end_point.lerp(hand, t)
        if t >= 1.0:
            _finish()
    if phase != PHASE_IDLE:
        var from: Vector2 = to_local(girl.get_node("Hand").global_position)
        var to: Vector2 = to_local(hook_tip.global_position)
        moon_thread.points = PackedVector2Array([from,to])

func _start_retract() -> void:
    if phase == PHASE_IDLE or phase == PHASE_RETRACT:
        return
    end_point = hook_tip.global_position
    phase = PHASE_RETRACT
    clock = 0.0
    hook_tip.play("retract")

func _finish() -> void:
    phase = PHASE_IDLE
    # If the tether was interrupted inside a traversal gap, return to last safe ground.
    if mode == MODE_ANCHOR and _inside_traversal_gap(girl.global_position):
        girl.global_position = safe_cast_origin
        if girl.has_method("snap_render_after_teleport"):
            girl.call("snap_render_after_teleport")
    girl.collision_mask = normal_player_collision_mask
    var finished_mode: int = mode
    mode = MODE_NONE
    target = null
    hook_tip.visible = false
    moon_thread.visible = false
    moon_thread.clear_points()
    cooldown = 0.60 if yanked_enemy else (0.40 if finished_mode == MODE_SWITCH else 0.28)
    yanked_enemy = false

func is_pulling_player() -> bool:
    return phase == PHASE_PULL and mode == MODE_ANCHOR and is_instance_valid(target)

func pull_velocity() -> Vector2:
    if not is_pulling_player():
        return Vector2.ZERO
    return (fixed_point - girl.global_position).normalized() * player_pull_speed * (1.0 + _stat("hook_pull_pct") / 100.0)

func cancel_hook() -> void:
    _finish()

func _inside_traversal_gap(where: Vector2) -> bool:
    var query: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
    query.position = where
    query.collision_mask = 8
    query.exclude = [girl.get_rid()]
    return not get_world_2d().direct_space_state.intersect_point(query, 8).is_empty()

func _stat(stat_id: String) -> float:
    var root: Node = girl.get("world") as Node
    if root == null or not root.has_node("Inventory"):
        return 0.0
    return float(root.get_node("Inventory").call("get_stat_total", stat_id))

func _effective_range() -> float:
    return maximum_range * (1.0 + _stat("hook_range_pct") / 100.0)
