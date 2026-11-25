extends SceneTree
## v2.11: synthetic collection fixtures only; no user:// writes or combat.
const GLOW = preload("res://scripts/scythe_glow_layer_v211.gd")
const MODEL = preload("res://scripts/collector_lens_model_v179.gd")
const LENS = preload("res://scripts/collector_lens_v179.gd")
const BLUNT = preload("res://scripts/blunt_weapon_family_v203.gd")
const INV = preload("res://scripts/inventory.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var inv: Node = INV.new()
	var scythe_data: GhostItemData = load("res://items/rose_reaper_scythe.tres") as GhostItemData
	if scythe_data == null:
		_fail("Missing scythe definition")
		return
	var scythe: GhostItemInstance = GhostItemGenerator.create(scythe_data, 211027, "rare")
	scythe.apply_cosmetic_uid("abcdef0123456789abcdef0123456789")
	scythe.gradient_version = 2
	var original: Dictionary = inv._serialize_item(scythe, Vector2i.ZERO)
	var rank: int = GLOW.rolled_level(scythe)
	if rank < 0 or rank > 5 or not is_equal_approx(GLOW.opacity(rank), float(rank) * 0.10):
		_fail("Rolled scythe aura out of allowed opacity steps")
		return
	if GLOW.rolled_level(scythe) != rank or GLOW.rolled_level(scythe) != GLOW.rolled_level(scythe):
		_fail("Aura is not deterministic")
		return
	var empty: int = 0
	for i in range(256):
		var item: GhostItemInstance = GhostItemGenerator.create(scythe_data, i + 211000, "normal")
		item.apply_cosmetic_uid("%032x" % i)
		if GLOW.rolled_level(item) == 0:
			empty += 1
	if empty <= 128:
		_fail("Most cosmetic seeds should have zero scythe glow")
		return
	var model: Node2D = MODEL.new()
	root.add_child(model)
	model.set_item(scythe)
	var layer: Node2D = model.get_node_or_null("ScytheGlowLayerV211") as Node2D
	if layer == null or not layer.material is CanvasItemMaterial or (layer.material as CanvasItemMaterial).blend_mode != CanvasItemMaterial.BLEND_MODE_ADD:
		_fail("Scythe preview missing separate additive light layer")
		return
	model.call("set_glow_preview_override", 5)
	await process_frame
	if int(layer.get("level")) != 5 or not layer.visible:
		_fail("Forced 50% preview did not reach expanded silhouette layer")
		return
	model.call("set_glow_preview_override", 0)
	await process_frame
	if int(layer.get("level")) != 0 or layer.visible:
		_fail("0% preview left glow visible")
		return
	var lens: Control = LENS.new()
	root.add_child(lens)
	lens.open_item(scythe)
	var selector: OptionButton = lens.get("scythe_glow_choices") as OptionButton
	if selector == null or selector.item_count != 7 or not selector.get_parent().visible:
		_fail("Collector's Lens lacks rolled + six preview opacity steps")
		return
	selector.select(6)
	selector.item_selected.emit(6)
	if int((lens.get("model") as Node2D).get("glow_preview_override")) != 5:
		_fail("Lens 50% preview disconnected")
		return
	lens.close_lens()
	if inv._serialize_item(scythe, Vector2i.ZERO) != original:
		_fail("Scythe previews altered stats or cosmetic seed")
		return
	for id in ["v203_mournful_mace", "v203_rosequartz_morningstar", "v203_nightchain_flail"]:
		var base: GhostItemData = load("res://items/" + id + ".tres") as GhostItemData
		if base == null or base.weapon_style != "maul" or BLUNT.kind_from_id(id).is_empty():
			_fail("Blunt weapon definition or silhouette mapping missing: " + id)
			return
		var item: GhostItemInstance = GhostItemGenerator.create(base, 211048, "rare")
		var record: Dictionary = inv._serialize_item(item, Vector2i.ZERO)
		model.set_item(item)
		if not model.is_modular() or model.get("item") != item:
			_fail("Blunt model preview lost actual item instance: " + id)
			return
		if inv._serialize_item(item, Vector2i.ZERO) != record:
			_fail("Blunt preview changed item: " + id)
			return
	lens.free()
	model.free()
	inv.free()
	print("v2.11 PASS: distinct blunt bases, seed-stable scythe glow 0–50%, preview overrides and no item mutations")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
