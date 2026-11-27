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

# Simultaneous key state. Opposite keys cancel; diagonal speed is normalized.
static func digital_vector(left: bool,right: bool,up: bool,down: bool) -> Vector2:
	return Vector2(float(int(right)-int(left)),float(int(down)-int(up))).limit_length(1.0)

static func keyboard_vector() -> Vector2:
	return digital_vector(
		Input.is_action_pressed("left") or Input.is_physical_key_pressed(KEY_A),
		Input.is_action_pressed("right") or Input.is_physical_key_pressed(KEY_D),
		Input.is_action_pressed("up") or Input.is_physical_key_pressed(KEY_W),
		Input.is_action_pressed("down") or Input.is_physical_key_pressed(KEY_S))

static func movement(keyboard: Vector2, touch: Vector2, pad: Vector2 = Vector2.ZERO) -> Vector2:
	if touch.length_squared() > 0.0064:
		return touch.limit_length(1.0)
	if keyboard.length_squared() > 0.01:
		return keyboard.limit_length(1.0)
	if pad.length_squared() > 0.01:
		return heading(octant(pad)) * minf(pad.length(),1.0)
	return Vector2.ZERO

static func stick(x_axis: int, y_axis: int) -> Vector2:
	var best: Vector2 = Vector2.ZERO
	for device in Input.get_connected_joypads():
		var raw: Vector2 = Vector2(Input.get_joy_axis(device,x_axis),Input.get_joy_axis(device,y_axis))
		var magnitude: float = minf(raw.length(),1.0)
		if magnitude <= 0.22:
			continue
		var scaled: Vector2 = raw.normalized() * ((magnitude-0.22)/0.78)
		if scaled.length_squared() > best.length_squared():
			best = scaled
	return best

static func install_controller() -> void:
	var buttons: Dictionary = {
		"left": JOY_BUTTON_DPAD_LEFT, "right": JOY_BUTTON_DPAD_RIGHT,
		"up": JOY_BUTTON_DPAD_UP, "down": JOY_BUTTON_DPAD_DOWN,
		"jump": JOY_BUTTON_A, "dodge": JOY_BUTTON_B,
		"attack_light": JOY_BUTTON_X, "attack_heavy": JOY_BUTTON_Y,
		"cast_spell": JOY_BUTTON_RIGHT_SHOULDER, "use_dew": JOY_BUTTON_LEFT_SHOULDER,
		"target_lock": JOY_BUTTON_RIGHT_STICK, "sprint": JOY_BUTTON_LEFT_STICK,
		"inventory": JOY_BUTTON_BACK, "interact": JOY_BUTTON_START
	}
	for action in buttons:
		if not InputMap.has_action(action):
			continue
		var event: InputEventJoypadButton = InputEventJoypadButton.new()
		event.device = -1
		event.button_index = buttons[action]
		if not InputMap.action_has_event(action,event):
			InputMap.action_add_event(action,event)

