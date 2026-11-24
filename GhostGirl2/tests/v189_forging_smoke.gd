extends SceneTree
const LOOK = preload("res://scripts/collector_appearance_v177.gd")
const ART = preload("res://scripts/modular_weapon_art_v178.gd")
const INV = preload("res://scripts/inventory.gd")
func _initialize() -> void:
	var seen: Dictionary = {}
	var keys: Array[String] = ["guard_style", "grip_style", "inset_style", "etch_style", "width_scale", "shoulder", "taper", "guard_span", "grip_width", "wrap_count", "etch_count"]
	for key in keys:
		seen[key] = {}
	for n in range(512):
		var uid: String = "%032x" % n
		var look: Dictionary = LOOK.roll(uid, 189001)
		var p: Dictionary = ART.profile(look)
		if p != ART.profile(LOOK.roll(uid, 189002)):
			_fail("Forging depends on combat seed")
			return
		for key in keys:
			seen[key][p[key]] = true
		for id in ["rosemirror_twinblade_v170", "eclipse_twinblade_v170"]:
			var blade: Dictionary = ART.weapon_profile(look, id)
			var root: Vector2 = Vector2(0,0)
			var tip: Vector2 = Vector2(60,0)
			for side in [-1.0, 1.0]:
				var edge: PackedVector2Array = ART.edge_points(root, tip, 4.6, blade, side)
				if edge.size() != 4 or edge[3] != tip:
					_fail("Blade lost sharp authored point")
					return
				for i in range(3):
					if edge[i].y * side <= 0.0 or absf(edge[i].y) > 6.0:
						_fail("Blade exceeded slender contour")
						return
	if seen["guard_style"].size() != 8 or seen["grip_style"].size() != 6 or seen["inset_style"].size() != 7 or seen["etch_style"].size() != 5 or seen["width_scale"].size() < 450:
		_fail("Insufficient independent forging diversity")
		return
	var inv: Node = INV.new()
	var item: GhostItemInstance = GhostItemGenerator.create(load("res://items/rosemirror_twinblade_v170.tres") as GhostItemData, 189001, "rare")
	item.cosmetic_uid = "123456789abcdef0123456789abcdef0"
	var stats: Dictionary = item.all_stats()
	var profile: Dictionary = ART.weapon_profile(item.collector_appearance(), item.definition.item_id)
	var restored: GhostItemInstance = inv._deserialize_item(inv._serialize_item(item, Vector2i.ZERO))
	if restored == null or restored.all_stats() != stats or ART.weapon_profile(restored.collector_appearance(), restored.definition.item_id) != profile:
		_fail("Forged identity or stats changed on save roundtrip")
		return
	inv.free()
	print("v1.89 PASS: 512 UID profiles, independent forged dimensions and ornaments, exact pointed tips and saved identity")
	quit(0)
func _fail(message: String) -> void:
	push_error(message)
	quit(1)
