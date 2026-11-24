extends SceneTree
const LENS = preload("res://scripts/collector_lens_v179.gd")
const ART = preload("res://scripts/modular_weapon_art_v178.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var lens: Control = LENS.new()
	root.add_child(lens)
	var item: GhostItemInstance = GhostItemInstance.new()
	item.definition = load("res://items/eclipse_twinblade_v170.tres") as GhostItemData
	item.item_seed = 179001
	item.cosmetic_uid = "0123456789abcdef0123456789abcdef"
	var before: Dictionary = item.cosmetic_snapshot()
	var damage: float = item.weapon_damage()
	lens.call("open_item", item)
	var model: Node2D = lens.get("model")
	var profiles: Array = model.get("profiles")
	if not lens.visible or not bool(model.call("is_modular")) or profiles.size() != 2 or profiles[0] != ART.weapon_profile(item.collector_appearance(), str(item.definition.item_id), 0):
		push_error("Collector Lens does not use the equipped appearance profile")
		quit(1)
		return
	lens.call("_toggle_glow", false)
	if bool(model.get("glow_enabled")):
		push_error("Glow toggle failed")
		quit(1)
		return
	await process_frame
	lens.call("close_lens")
	if lens.visible or model.get("item") != null or item.cosmetic_snapshot() != before or item.weapon_damage() != damage:
		push_error("Inspection altered item or did not close")
		quit(1)
		return
	item.definition = load("res://items/dusk_needle.tres") as GhostItemData
	lens.call("open_item", item)
	if bool(model.call("is_modular")):
		push_error("Legacy blade should display base artwork fallback")
		quit(1)
		return
	lens.call("close_lens")
	lens.queue_free()
	print("v1.79 PASS: read-only modal, matching profile, glow toggle, legacy artwork fallback")
	quit(0)
