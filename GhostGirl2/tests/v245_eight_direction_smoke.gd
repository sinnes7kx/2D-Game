extends SceneTree
const DIR = preload("res://scripts/direction_controller_v245.gd")
const PLAYER_SCRIPT = preload("res://scripts/player.gd")
const PLAYER = preload("res://scenes/player.tscn")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var actor: CharacterBody2D = PLAYER.instantiate() as CharacterBody2D
	# set_facing needs the onready hand; enter the tree in preview-only mode.
	actor.set("equipment_preview_only", true)
	root.add_child(actor)
	for i in range(8):
		var expected: Vector2 = DIR.heading(i)
		actor.call("set_facing", expected)
		if int(actor.get("facing_octant")) != i or str(actor.get("facing_eight_name")) != DIR.NAMES[i] or not (actor.get("facing") as Vector2).is_equal_approx(expected):
			_fail("Wrong logical facing: " + str(i))
			return
		if str(actor.get("facing_name")) != DIR.pose_name(i):
			_fail("Unsafe visual fallback")
			return
		var art: AnimatedSprite2D = actor.get_node("Ghost") as AnimatedSprite2D
		if not art.sprite_frames.has_animation("idle_" + DIR.pose_name(i)):
			_fail("Missing original idle art")
			return
	# Changing the visual heading cannot alter a committed jump travel vector.
	actor.set("jump_direction", Vector2.LEFT)
	actor.set("jump_strike_direction", Vector2.RIGHT)
	actor.call("set_facing", Vector2.RIGHT)
	assert(actor.get("jump_direction") == Vector2.LEFT)
	assert(actor.get("jump_strike_direction") == Vector2.RIGHT)
	var before: Vector2 = actor.get("facing")
	actor.call("set_facing", Vector2.ZERO)
	if not (actor.get("facing") as Vector2).is_equal_approx(before):
		_fail("Idle input lost facing")
		return
	if not is_equal_approx(DIR.movement(Vector2(1,1), Vector2.ZERO).length(), 1.0):
		_fail("Diagonal speed multiplier")
		return
	if DIR.octant(Vector2.from_angle(deg_to_rad(23.0)), 0) != 0 or DIR.octant(Vector2.from_angle(deg_to_rad(30.0)), 0) != 1:
		_fail("Facing hysteresis")
		return
	if DIR.movement(Vector2.LEFT, Vector2(0.5, 0.5)) != Vector2(0.5, 0.5):
		_fail("Touch input not shared")
		return
	for i in range(8):
		var raw: Vector2 = DIR.heading(i).rotated(0.12)*0.63
		assert(DIR.movement(Vector2.ZERO,Vector2.ZERO,raw).is_equal_approx(DIR.heading(i)*0.63))
	assert(DIR.movement(Vector2.LEFT,Vector2.ZERO,Vector2.RIGHT)==Vector2.LEFT)
	assert(DIR.movement(Vector2.ZERO,Vector2.ZERO,Vector2.ZERO)==Vector2.ZERO)
	# Mouse aim is independent of movement, with a stable near-cursor zone.
	for i in range(8):
		var aim: Vector2 = DIR.heading(i)
		assert(DIR.cursor_heading(aim * 120.0, -aim).is_equal_approx(aim))
		assert(DIR.cursor_heading(aim * 8.0, -aim).is_equal_approx(-aim))
		assert(DIR.octant(DIR.cursor_heading(aim * 120.0, Vector2.DOWN)) == i)
	var precise: Vector2 = Vector2(100.0, 29.0)
	assert(DIR.cursor_heading(precise, Vector2.DOWN).is_equal_approx(precise.normalized()))
	assert(DIR.cursor_heading(Vector2.ZERO, Vector2.LEFT) == Vector2.LEFT)
	assert(DIR.movement(Vector2.LEFT, Vector2.ZERO) == Vector2.LEFT)
	# All octants use the same timed frontal contact rules.
	for i in range(8):
		var aim: Vector2 = DIR.heading(i)
		assert(PLAYER_SCRIPT.parry_result(0.10,aim,aim*60.0)==2)
		assert(PLAYER_SCRIPT.parry_result(0.24,aim,aim*60.0)==1)
		assert(PLAYER_SCRIPT.parry_result(0.34,aim,aim*60.0)==0)
		assert(PLAYER_SCRIPT.parry_result(0.10,aim,-aim*60.0)==0)
		assert(PLAYER_SCRIPT.parry_result(0.10,aim,Vector2.ZERO)==0)
	DIR.install_controller()
	assert(InputMap.action_get_events("parry").size()==2)
	var event_count: int = InputMap.action_get_events("attack_light").size()
	DIR.install_controller()
	assert(InputMap.action_get_events("attack_light").size()==event_count)
	var dummy: Node2D = preload("res://scripts/training_dummy_v260.gd").new()
	root.add_child(dummy)
	assert(dummy.is_in_group("enemies"))
	dummy.call("hit",12.5)
	dummy.call("hit",7.5)
	assert(int(dummy.get("hits"))==2 and is_equal_approx(float(dummy.get("total_damage")),20.0))
	dummy.call("_process",5.0)
	assert(int(dummy.get("hits"))==0)
	dummy.free()
	actor.free()
	print("v2.45 PASS: eight logical headings, original pose fallback, input and hysteresis")
	quit(0)

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
