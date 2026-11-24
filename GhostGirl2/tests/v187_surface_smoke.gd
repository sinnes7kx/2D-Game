extends SceneTree
const SURFACE = preload("res://scripts/living_metal_v187.gd")
const LOOK = preload("res://scripts/collector_appearance_v177.gd")
const ART = preload("res://scripts/modular_weapon_art_v178.gd")
const INV = preload("res://scripts/inventory.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var uid: String = "0123456789abcdef0123456789abcdef"
	var look: Dictionary = LOOK.roll(uid, 1)
	if look != LOOK.roll(uid, 999):
		_fail("Surface rolls depend on gameplay seed")
		return
	for tier in range(7):
		var found: Dictionary = {}
		for ticket in range(100):
			found[SURFACE.surface_for_ticket(ticket, tier)] = true
		if found.size() != mini(tier+2,7):
			_fail("Surface rarity gate incorrect")
			return
	var p: Dictionary = ART.weapon_profile(look,"rosemirror_twinblade_v170")
	for mode in range(7):
		p["surface_mode"] = mode
		var changed: bool = false
		for i in range(12):
			var u: float = float(i)/12.0
			if not SURFACE.surface_color(p,u,0.3,0.0).is_equal_approx(SURFACE.surface_color(p,u,0.3,2.5)):
				changed = true
		if changed != SURFACE.animated(mode):
			_fail("Surface animation state incorrect: " + str(mode))
			return
	var a: Vector2 = Vector2(-17,25)
	var b: Vector2 = Vector2(20,-65)
	var left: PackedVector2Array = ART.edge_points(a,b,5.8,p,-1.0)
	var right: PackedVector2Array = ART.edge_points(a,b,5.8,p,1.0)
	for u in [0.0,0.30,0.76,1.0]:
		var cross: Vector2 = SURFACE.at_edge(left,u).lerp(SURFACE.at_edge(right,u),0.5)
		if not cross.is_equal_approx(a.lerp(b,u)):
			_fail("Surface not contained within blade cross section")
			return
	var inv: Node = INV.new()
	var template: GhostItemData = load("res://items/rosemirror_twinblade_v170.tres") as GhostItemData
	var item: GhostItemInstance = GhostItemGenerator.create(template, 187001, "rare")
	item.cosmetic_uid = uid
	var original: Dictionary = item.collector_appearance()
	var stats: Dictionary = item.all_stats()
	item.debug_surface_mode = 6
	if OS.is_debug_build() and item.collector_appearance()["surface_mode"] != 6:
		_fail("Surface debug selection did not apply")
		return
	var restored: GhostItemInstance = inv._deserialize_item(inv._serialize_item(item,Vector2i.ZERO))
	if restored == null or restored.collector_appearance() != original or restored.all_stats() != stats or restored.debug_surface_mode != -1:
		_fail("Surface preview persisted or changed gameplay stats")
		return
	var model: Node2D = preload("res://scripts/collector_lens_model_v179.gd").new()
	root.add_child(model)
	model.call("set_item",item)
	model.set("glow_enabled",false)
	var before: float = model.get("elapsed")
	await process_frame
	await process_frame
	if float(model.get("elapsed")) <= before:
		_fail("Animated metal stopped with illumination disabled")
		return
	model.free()
	inv.free()
	print("v1.87 PASS: seven surface families, seed independence, rarity gates, blade outline, debug isolation and glow-independent motion")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
