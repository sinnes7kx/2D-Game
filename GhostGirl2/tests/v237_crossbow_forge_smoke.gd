extends SceneTree
const CROSS = preload("res://scripts/crossbow_v236.gd")
func _initialize() -> void:
	var profile: Dictionary = {"width_scale": 1.0, "ornament": 3, "wrap_count": 8}
	var ids: Array[String] = ["blackthorn_crossbow_v236", "silver_reliquary_crossbow_v236", "vesper_latch_crossbow_v237", "ossuary_arbalest_v237"]
	var widths: Dictionary = {}
	for i in range(ids.size()):
		var build: Dictionary = CROSS.construction(profile, ids[i])
		if int(build["style"]) != i or int(build["wraps"]) != 6 or int(build["ornament"]) != 3:
			_fail("Construction profile mismatch")
			return
		widths[build["width"]] = true
		var definition: GhostItemData = load("res://items/" + ids[i] + ".tres") as GhostItemData
		if definition == null or definition.weapon_style != "crossbow" or definition.icon == null:
			_fail("Missing base or icon")
			return
	if widths.size() != 4 or CROSS.action_sample(0.2, 0.2) != Vector2.ZERO or CROSS.action_sample(0.1, 0.2) != Vector2(4, 0) or CROSS.action_sample(0.0, 0.2) != Vector2(7, 1):
		_fail("Timing or distinct construction failed")
		return
	var body: AnimatedSprite2D = AnimatedSprite2D.new()
	body.position = Vector2(30, 42)
	body.rotation = 0.23
	body.scale = Vector2(1.2, 1.2)
	var points: PackedVector2Array = PackedVector2Array([Vector2(12, 14), Vector2(44, 14)])
	var heading: Vector2 = Vector2(1, -1).normalized()
	var aimed: PackedVector2Array = CROSS.aimed_span(body, points, heading)
	var actual: Vector2 = (body.to_global(aimed[1]) - body.to_global(aimed[0])).normalized()
	body.free()
	if aimed[0] != points[0] or not is_equal_approx(aimed[0].distance_to(aimed[1]), 32.0) or actual.dot(heading) < 0.999:
		_fail("Aim detached from grip or heading")
		return
	print("v2.37 PASS: four construction profiles, deterministic ornaments, timed poses and shared muzzle aim")
	quit(0)
func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
