extends SceneTree
const ART = preload("res://scripts/modular_weapon_art_v178.gd")
const LOOK = preload("res://scripts/collector_appearance_v177.gd")
const GAME = preload("res://scripts/game.gd")
const IDS: Array[String] = ["widowglass_twinblade_v231", "cathedral_thorn_twinblade_v231", "vesperthorn_dual_swords_v231", "mourninglace_dual_daggers_v231"]
const OLD_IDS: Array[String] = ["eclipse_twinblade_v170", "rosemirror_twinblade_v170", "gloamrose_dual_swords_v174", "moonlace_dual_daggers_v173"]
const SHAPES: Array[int] = [2, 4, 1, 4]
const GUARDS: Array[int] = [4, 2, 1, 5]

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var seen: Dictionary = {}
	var game: Node = GAME.new()
	var original: GhostItemData = load("res://items/dusk_needle.tres") as GhostItemData
	for i in range(IDS.size()):
		var definition: GhostItemData = load("res://items/" + IDS[i] + ".tres") as GhostItemData
		var old_definition: GhostItemData = load("res://items/" + OLD_IDS[i] + ".tres") as GhostItemData
		if definition == null or old_definition == null or definition.icon == null or definition.item_id != IDS[i] or definition.weapon_style != old_definition.weapon_style or definition.unique:
			_fail("Missing or invalid base definition")
			return
		if definition.min_weapon_damage != old_definition.min_weapon_damage or definition.max_weapon_damage != old_definition.max_weapon_damage or definition.max_sockets != old_definition.max_sockets:
			_fail("Variant introduced a new damage or socket tier")
			return
		var a: GhostItemInstance = GhostItemGenerator.create(definition, 1234, "rare")
		var b: GhostItemInstance = GhostItemGenerator.create(old_definition, 1234, "rare")
		if not is_equal_approx(a.light_swing_duration(), b.light_swing_duration()) or a.weapon_style() != b.weapon_style():
			_fail("Class timing changed")
			return
		var look: Dictionary = LOOK.roll("0123456789abcdef0123456789abcdef", 123)
		var p: Dictionary = ART.weapon_profile(look, IDS[i])
		if p.is_empty() or p["shape"] != SHAPES[i] or p["guard_style"] != GUARDS[i] or p != ART.weapon_profile(look, IDS[i]):
			_fail("Base silhouette not deterministic")
			return
		var points: PackedVector2Array = ART.edge_points(Vector2.ZERO, Vector2(60, 0), 3.1, p, 1.0)
		if points.size() != 4 or points[3] != Vector2(60, 0):
			_fail("Variant changed authored blade endpoint")
			return
	for seed in range(1, 2000):
		var selected: GhostItemData = game.call("_roll_sword_drop", original, seed) as GhostItemData
		if selected.item_id in IDS:
			seen[selected.item_id] = true
			if seed % 7 != 0 or seed % 23 == 0:
				_fail("Variant escaped existing sword lane")
				return
	if seen.size() != IDS.size():
		_fail("Not all variants are obtainable")
		return
	game.free()
	print("v2.31 PASS: four collectible variants, deterministic profiles, existing class timing and loot lane")
	quit(0)

func _fail(reason: String) -> void:
	push_error(reason)
	quit(1)
