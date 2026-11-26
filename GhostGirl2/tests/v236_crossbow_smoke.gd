extends SceneTree
const CROSS = preload("res://scripts/crossbow_v236.gd")
const HAND = preload("res://scripts/dagger_thrust_v186.gd")
const JUICE = preload("res://scripts/combat_juice_v194.gd")
func _initialize() -> void:
	for face in ["front", "back", "left", "right"]:
		for name in ["crossbow_idle_" + face, "crossbow_walk_" + face, "attack_crossbow_fire_" + face, "attack_crossbow_reload_" + face]:
			for i in range(8):
				var wrist: Vector2 = HAND.hand_anchor(face, CROSS.sequence(name, face)[i], 0 if face == "left" else 1)
				var points: PackedVector2Array = CROSS.span(name, face, i)
				if wrist == Vector2.INF:
					if not points.is_empty():
						_fail("Occluded wrist")
						return
				elif points.size() != 2 or points[0] != wrist or not is_equal_approx(points[0].distance_to(points[1]), 32.0):
					_fail("Crossbow wrist drift")
					return
	for id in ["blackthorn_crossbow_v236", "silver_reliquary_crossbow_v236"]:
		var definition: GhostItemData = load("res://items/" + id + ".tres") as GhostItemData
		if definition == null or definition.weapon_style != "crossbow" or definition.icon == null:
			_fail("Missing crossbow")
			return
	if JUICE._render("crossbow_fire").data == JUICE._render("crossbow_reload").data:
		_fail("Identical audio")
		return
	if CROSS.RELEASE_AT >= CROSS.FIRE_TIME or CROSS.HEAVY_RELOAD <= CROSS.RELOAD_TIME:
		_fail("Invalid firing timing")
		return
	print("v2.36 PASS: crossbow spans, bases and foley")
	quit(0)
func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
