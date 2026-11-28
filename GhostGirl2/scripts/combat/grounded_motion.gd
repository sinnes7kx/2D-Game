extends RefCounted
## Pure movement policy; input, stamina, collision and animation stay with player.
const WALK_SPEED: float = 175.0
const SPRINT_SPEED: float = 246.0
const MOVE_ACCELERATION: float = 1700.0
const MOVE_BRAKE: float = 2700.0
const TURN_ACCELERATION: float = 1900.0
const CHARGE_WALK_FACTOR: float = 0.45

static func walking_velocity(current: Vector2, direction: Vector2, speed: float, delta: float) -> Vector2:
	var moving: bool = direction.length_squared() > 0.01
	var target: Vector2 = direction.normalized() * speed if moving else Vector2.ZERO
	var turn: bool = moving and current.length_squared() > 50.0 and current.normalized().dot(direction.normalized()) < 0.22
	var response: float = TURN_ACCELERATION if turn else (MOVE_ACCELERATION if moving else MOVE_BRAKE)
	return current.move_toward(target,response*delta)

static func charge_target(direction: Vector2, speed: float) -> Vector2:
	return direction.limit_length(1.0)*maxf(0.0,speed)*CHARGE_WALK_FACTOR

static func charge_velocity(current: Vector2, direction: Vector2, speed: float, delta: float) -> Vector2:
	var target: Vector2 = charge_target(direction,speed)
	var result: Vector2 = current.move_toward(target,(MOVE_ACCELERATION if direction.length_squared()>0.01 else MOVE_BRAKE)*delta)
	return result.limit_length(maxf(0.0,speed)*CHARGE_WALK_FACTOR)

static func channel_velocity(current: Vector2,direction: Vector2,speed: float,delta: float) -> Vector2:
	return current.move_toward(direction.normalized()*speed if direction.length_squared()>0.01 else Vector2.ZERO,MOVE_ACCELERATION*delta)

# Preserve the original multiplication order and per-zone callbacks.
static func terrain_speed(actor: Node2D, speed: float) -> float:
	for water in actor.get_tree().get_nodes_in_group("water_body"):
		if is_instance_valid(water) and water.has_method("movement_multiplier_at"):
			speed*=float(water.call("movement_multiplier_at",actor.global_position))
	return speed
