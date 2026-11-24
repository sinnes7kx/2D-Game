extends Node2D
## Slow, visible hostile shot. Dodge backward or take cover; world walls stop it.
var heading: Vector2 = Vector2.DOWN
var speed: float = 345.0
var remaining_distance: float = 680.0
var damage: float = 15.0
var caster_rid: RID
var age: float = 0.0
# v1.59: shallow single-bolt weave; projectile still uses the original wall
# and player raycast and the original damage amount.
var curved_flight: bool = false
var curve_sign: float = 1.0
var travel_heading: Vector2 = Vector2.DOWN

func _physics_process(delta: float) -> void:
    var steer: float = curve_sign * 0.19 * sin(age * 4.8) * exp(-age * 0.65) if curved_flight else 0.0
    travel_heading = heading.rotated(steer).normalized()
    var step: Vector2 = travel_heading * speed * delta
    var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position, global_position + step)
    query.collision_mask = 3 # Player (1) and World (2)
    query.exclude = [caster_rid]
    var result: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
    if not result.is_empty():
        var target: Object = result.get("collider")
        if target != null and target.has_method("receive_damage"):
            if target.has_method("register_confirmed_evade"):
                target.call("register_confirmed_evade", self, global_position)
            target.call("receive_damage", damage, global_position)
        queue_free()
        return
    global_position += step
    remaining_distance -= step.length()
    if remaining_distance <= 0.0:
        queue_free()

func _process(delta: float) -> void:
    age += delta
    queue_redraw()

func _draw() -> void:
    var glow: float = 1.0 + 0.11 * sin(age * 15.0)
    draw_circle(Vector2.ZERO, 19.0 * glow, Color(0.66, 0.36, 0.45, 0.15))
    draw_circle(Vector2.ZERO, 10.0 * glow, Color(0.83, 0.54, 0.54, 0.54))
    draw_circle(Vector2.ZERO, 4.2, Color(1.0, 0.84, 0.72, 0.96))
    draw_line(-travel_heading * 22.0, -travel_heading * 7.0, Color(0.86, 0.50, 0.54, 0.45), 4.0, true)
    if curved_flight:
        # A cool inner comet makes the alternate shot readable in the air.
        draw_circle(Vector2.ZERO, 7.0 * glow, Color(0.60, 0.68, 1.0, 0.24))
        draw_line(-travel_heading * 29.0, -travel_heading * 12.0, Color(0.65, 0.64, 0.99, 0.37), 2.5, true)
