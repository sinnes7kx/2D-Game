extends SceneTree
const INV = preload("res://scripts/inventory.gd")
const PANEL = preload("res://scenes/inventory_panel.tscn")
const MODEL = preload("res://scripts/collector_lens_model_v179.gd")
const FX = preload("res://scripts/anomalous_steel_fx_v180.gd")
const HAND = preload("res://scripts/dagger_thrust_v186.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var inv: Node = INV.new()
	var actor: Node = (load("res://scenes/player.tscn") as PackedScene).instantiate()
	root.add_child(actor)
	actor.set_physics_process(false)
	var body: AnimatedSprite2D = actor.get_node("Ghost")
	var equipment: Node = actor.get_node("EquipmentVisuals")
	var prestige: Node = body.get_node("EquippedPrestigeFX")
	var bow: AnimatedSprite2D = body.get_node("BowPaletteV139")
	equipment.call("bind_inventory", inv)
	prestige.call("bind_inventory", inv)
	bow.call("bind_inventory", inv)
	var panel: Control = PANEL.instantiate()
	root.add_child(panel)
	panel.call("bind_inventory", inv)
	var model: Node2D = MODEL.new()
	root.add_child(model)
	for path in ["res://items/rosemirror_twinblade_v170.tres", "res://items/thornrose_bow.tres", "res://items/moonveil_bow.tres", "res://items/briar_wand.tres"]:
		var item: GhostItemInstance = GhostItemGenerator.create(load(path) as GhostItemData, 192301, "rare")
		item.cosmetic_uid = "0123456789abcdef0123456789abcdef"
		inv.contents.clear()
		inv.grid_positions.clear()
		inv.contents.append(item)
		inv.grid_positions.append(Vector2i.ZERO)
		inv.equipment["sword"] = 0 if item.get_slot() == "sword" else -1
		inv.equipment["wand"] = 0 if item.get_slot() == "wand" else -1
		inv.contents_changed.emit()
		inv.equipment_changed.emit()
		panel.show()
		panel.call("_on_slot_pressed", 0)
		var menu: OptionButton = panel.get_node("Layout/DetailsHeader/TestMythic")
		var saved: Dictionary = item.cosmetic_snapshot()
		var stats: Dictionary = item.all_stats()
		for id in [36, 1, 23, 55, 1]:
			var index: int = menu.get_item_index(id)
			if index < 0:
				_fail("Missing test choice")
				return
			menu.item_selected.emit(index)
			model.call("set_item", item)
			var equipped_look: Dictionary = prestige.get("collector_look")
			if equipped_look != model.get("look") or equipped_look != item.collector_appearance():
				_fail("Equipped and inspected look differ")
				return
			if OS.is_debug_build() and id == 36 and FX.signature_kind(equipped_look) != 10:
				_fail("Anomaly geometry missing")
				return
			if OS.is_debug_build() and id == 23 and FX.signature_kind(equipped_look) != 9:
				_fail("Mythic variant geometry missing")
				return
			if item.weapon_style() == "bow":
				var mat: ShaderMaterial = bow.material as ShaderMaterial
				if int(mat.get_shader_parameter("signature_kind")) != FX.signature_kind(equipped_look) or int(mat.get_shader_parameter("glow_motif")) != int(equipped_look["glow_motif"]):
					_fail("Equipped bow mask ignored selected effects")
					return
		if item.cosmetic_snapshot() != saved or item.all_stats() != stats:
			_fail("Preview mutated saved item")
			return
		var cloth: ShaderMaterial = body.material as ShaderMaterial
		if float(cloth.get_shader_parameter("weapon_strength")) != 0.0 or float(cloth.get_shader_parameter("tint_strength")) != 0.0:
			_fail("Unsafe body recolor still enabled")
			return
	var arc: PackedVector2Array = PackedVector2Array([Vector2.ZERO, Vector2(10, 10), Vector2(20, 0)])
	if FX.point_on_path(arc, 0.5) != Vector2(10, 10) or HAND.hand_anchor("front", 0, 1) != Vector2(51,27):
		_fail("Weapon contour or corrected hand anchor regressed")
		return
	model.free()
	panel.free()
	actor.free()
	inv.free()
	print("v1.92.3 PASS: actual dropdown, equipped/inspect identity, bow mask, neutral body, dagger anchor and unchanged stats")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
