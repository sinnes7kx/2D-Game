extends SceneTree
const DIR = preload("res://scripts/direction_controller_v245.gd")
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
	actor.free()
	print("v2.45 PASS: eight logical headings, original pose fallback, input and hysteresis")
	quit(0)

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
