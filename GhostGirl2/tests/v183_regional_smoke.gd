extends SceneTree
const REGION = preload("res://scripts/regional_treasures_v183.gd")
const INV = preload("res://scripts/inventory.gd")
const FX = preload("res://scripts/anomalous_steel_fx_v180.gd")

func _initialize() -> void:
	var counts: Array[int] = [0, 0, 0, 0]
	for i in range(10000):
		counts[REGION.rank_for_ticket(i)] += 1
	if counts != [8000, 1600, 350, 50]:
		_fail("Incorrect regional rarity distribution")
		return
	var inv: Node = INV.new()
	var template: GhostItemData = load("res://items/rosemirror_twinblade_v170.tres") as GhostItemData
	var item: GhostItemInstance = GhostItemGenerator.create(template, 183001, "rare")
	item.cosmetic_uid = "0123456789abcdef0123456789abcdef"
	var original: Dictionary = item.collector_appearance()
	var stats: Dictionary = item.all_stats()
	var names: Dictionary = {}
	for room in REGION.REGIONS:
		item.origin_room = room
		item.regional_rank = 3
		var look: Dictionary = item.collector_appearance()
		names[item.regional_imprint_label()] = true
		if look["metal_colors"] == original["metal_colors"] or look["material"] != original["material"] or item.all_stats() != stats:
			_fail("Regional imprint failed or changed stats/base rarity")
			return
		var colors: Array[Color] = item.glow_gradient_colors()
		if FX.color_at(colors, look, 0.4, 0.0) == FX.color_at(colors, look, 0.4, 1.0):
			_fail("Regional animation did not vary")
			return
		var record: Dictionary = inv._serialize_item(item, Vector2i(-1,-1))
		var restored: GhostItemInstance = inv._deserialize_item(JSON.parse_string(JSON.stringify(record)))
		if restored == null or restored.collector_appearance() != look or restored.origin_room != room or restored.regional_rank != 3:
			_fail("Regional save round trip changed appearance")
			return
		restored.stamp_origin("sanctum")
		if restored.origin_room != room:
			_fail("Existing weapon was restamped")
			return
	if names.size() != 6:
		_fail("Regional signatures not distinct")
		return
	item.origin_room = ""
	item.regional_rank = 0
	if item.collector_appearance() != original or REGION.roll_rank("sanctum", item.cosmetic_uid, item.visual_seed()) != 0:
		_fail("Legacy or ineligible weapon received imprint")
		return
	inv.free()
	print("v1.83 PASS: exact rarity buckets, six exclusive signatures, animated light, stat independence and save roundtrip")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
