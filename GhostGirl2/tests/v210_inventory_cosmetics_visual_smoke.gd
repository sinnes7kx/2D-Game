extends SceneTree
## v2.10 local Godot smoke: cosmetic UI and rendering changes are presentation only.
const INV = preload("res://scripts/inventory.gd")
const PANEL = preload("res://scenes/inventory_panel.tscn")
const MARKUP = preload("res://scripts/item_rich_text.gd")
const BOW = preload("res://scripts/bow_palette_overlay_v139.gd")
const EYES = preload("res://scripts/head_cosmetics_v202.gd")
const SURFACE = preload("res://scripts/weapon_surface_v190.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var inv: Node = INV.new()
	var resource: GhostItemData = load("res://items/thornrose_bow.tres") as GhostItemData
	if resource == null:
		_fail("Missing bow fixture")
		return
	var item: GhostItemInstance = GhostItemGenerator.create(resource, 210024, "rare")
	inv.contents.append(item)
	inv.grid_positions.append(Vector2i.ZERO)
	var original: Dictionary = inv._serialize_item(item, Vector2i.ZERO)
	var panel: Control = PANEL.instantiate() as Control
	root.add_child(panel)
	panel.bind_inventory(inv)
	panel.show()
	panel.call("_on_slot_pressed", 0)
	if panel.get_node("Layout/DetailsHeader").visible or panel.get_node("Layout/DetailsWell/DetailsVBox/ItemDescription").visible:
		_fail("Old SELECTED ITEM label or redundant bottom stats are still visible")
		return
	if panel.get("cosmetic_radio_panel") == null or panel.get("seed_row") == null:
		_fail("Categorized cosmetic controls or saved looks are missing")
		return
	if OS.is_debug_build() and not (panel.get("cosmetic_radio_panel") as ScrollContainer).visible:
		_fail("Debug cosmetic radio groups are missing")
		return
	# Godot has CheckBox + ButtonGroup, not a RadioButton class.
	var choices: Array[Dictionary] = panel.get("cosmetic_radio_options")
	var groups: Dictionary = {}
	for choice in choices:
		var control: CheckBox = choice["button"] as CheckBox
		if control == null or control.button_group == null:
			_fail("Cosmetic option is not a grouped Godot CheckBox")
			return
		var category: String = str(choice["category"])
		if groups.has(category) and groups[category] != control.button_group:
			_fail("Cosmetic category has inconsistent radio group")
			return
		groups[category] = control.button_group
	if groups.size() != 8:
		_fail("Expected eight independent cosmetic categories")
		return
	var tooltip: String = MARKUP.item_info(item, false)
	if tooltip.count("●") != 6 or tooltip.contains("[url=visual:") or tooltip.contains("ROLL ·"):
		_fail("Expected six cosmetic dots with no extra labels")
		return
	var eye_front: Array[Vector2] = EYES.eye_centers("front")
	if eye_front.size() != 2 or eye_front[0].y < -50.0 or EYES.eye_centers("back").size() != 0:
		_fail("Luminous-eye anchors still sit above the pupils")
		return
	var eye_node: Node2D = EYES.new()
	root.add_child(eye_node)
	if not eye_node.material is CanvasItemMaterial or (eye_node.material as CanvasItemMaterial).blend_mode != CanvasItemMaterial.BLEND_MODE_MIX:
		_fail("Eye backing is not rendered with opaque alpha blending")
		return
	var left: Dictionary = BOW.idle_hold_pose("left")
	var right: Dictionary = BOW.idle_hold_pose("right")
	if (left["wrist_correction"] as Vector2).x <= 16.0 or (right["wrist_correction"] as Vector2).x >= -3.0:
		_fail("Side bows did not move slightly toward the back")
		return
	var shader_mat: ShaderMaterial = ShaderMaterial.new()
	SURFACE.configure(shader_mat, item.collector_appearance(), Vector2(256, 220), true, SURFACE.bow_pigment(item, item.collector_appearance()))
	if float(shader_mat.get_shader_parameter("strength")) < 0.90:
		_fail("Bow overlay cannot reach a full pigment coverage")
		return
	if inv._serialize_item(item, Vector2i.ZERO) != original:
		_fail("Preview/palette changes touched the collectible item save")
		return
	eye_node.free()
	panel.free()
	inv.free()
	print("v2.10 PASS: radio cosmetics, compact tooltip, full bow pigment, side bow/eye anchors and immutable item")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
