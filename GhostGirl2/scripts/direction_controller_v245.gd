extends RefCounted
## Eight logical directions; existing cardinal artwork and wrist anchors stay intact.
## Mouse/lock-on aiming and analogue travel may still be continuous.
const NAMES: Array[String] = ["right", "front_right", "front", "front_left", "left", "back_left", "back", "back_right"]
const ART_FALLBACK: Array[String] = ["right", "front", "front", "front", "left", "back", "back", "back"]
const STEP: float = PI / 4.0
const DEAD_ZONE_SQUARED: float = 0.0001

static func octant(direction: Vector2, previous: int = -1) -> int:
	if direction.length_squared() < DEAD_ZONE_SQUARED:
		return previous if previous >= 0 and previous < 8 else 2
	var angle: float = direction.angle()
	# A small angular hysteresis suppresses flicker from analogue/aim jitter.
	if previous >= 0 and previous < 8:
		var difference: float = absf(wrapf(angle - float(previous) * STEP, -PI, PI))
		if difference <= STEP * 0.5 + deg_to_rad(3.0):
			return previous
	return posmod(roundi(angle / STEP), 8)

static func heading(index: int) -> Vector2:
	return Vector2.from_angle(float(posmod(index, 8)) * STEP)

static func pose_name(index: int) -> String:
	return ART_FALLBACK[posmod(index, 8)]

static func movement(keyboard: Vector2, touch: Vector2) -> Vector2:
	return (touch if touch.length_squared() > 0.0064 else keyboard).limit_length(1.0)
