extends RefCounted
## Lightweight, reusable hazard avoidance for existing enemies.
## Called only on *uncommitted movement*, never during an attack windup,
## stagger, or a scripted lunge. No extra damage or new enemies.
static func avoid_fire(enemy: CharacterBody2D, desired_velocity: Vector2) -> Vector2:
    if desired_velocity.length_squared() < 1.0:
        return desired_velocity
    var tree: SceneTree = enemy.get_tree()
    if tree.get_first_node_in_group("v146_live_fire") == null:
        return desired_velocity
    var speed: float = desired_velocity.length()
    var direction: Vector2 = desired_velocity / speed
    var repulsion: Vector2 = Vector2.ZERO
    for source in tree.get_nodes_in_group("v146_live_fire"):
        if not is_instance_valid(source) or not (source is Node2D) or source.is_queued_for_deletion():
            continue
        var radius: float = 155.0
        var radius_value: Variant = source.get("fire_avoid_radius")
        if radius_value != null:
            radius = clampf(float(radius_value), 70.0, 260.0)
        var away: Vector2 = enemy.global_position - source.global_position
        var distance: float = away.length()
        if distance >= radius:
            continue
        if distance <= 0.001:
            away = Vector2.RIGHT.rotated(float(posmod(enemy.get_instance_id(), 17)) * 0.36)
            distance = 1.0
        var weight: float = 1.0 - distance / radius
        # Steering tapers off smoothly. Creatures already running away are
        # not pushed back toward the fire by arbitrary orbit behavior.
        repulsion += away / distance * weight * 2.3
    if repulsion.length_squared() < 0.0001:
        return desired_velocity
    var blended: Vector2 = direction + repulsion
    if blended.length_squared() < 0.0001:
        return -direction * speed
    return blended.normalized() * speed
