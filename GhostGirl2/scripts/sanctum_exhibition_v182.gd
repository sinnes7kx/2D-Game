@tool
extends Node2D
## Editor-positionable, non-pickup display. The actual item remains in the vault.
const MODEL = preload("res://scripts/collector_lens_model_v179.gd")
@export_range(0, 5) var slot: int = 0
var inventory: Node
var model: Node2D
var displayed: GhostItemInstance
var caption: Label
var provenance: Label
var time: float = 0.0

func _ready() -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return
	add_to_group("interactable")
	add_to_group("v182_exhibition")
	model = MODEL.new()
	model.position = Vector2(0, -94)
	model.rotation = -0.35
	add_child(model)
	caption = Label.new()
	caption.position = Vector2(-90, 12)
	caption.size = Vector2(180, 38)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_font_size_override("font_size", 12)
	caption.add_theme_color_override("font_color", Color("e0c7d9"))
	add_child(caption)
	provenance = Label.new()
	provenance.position = Vector2(-90, 46)
	provenance.size = Vector2(180, 32)
	provenance.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	provenance.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	provenance.add_theme_font_size_override("font_size", 10)
	provenance.add_theme_color_override("font_color", Color("b6a6b9"))
	add_child(provenance)
	_refresh()

func bind_inventory(value: Node) -> void:
	if inventory != null and inventory.contents_changed.is_connected(_refresh):
		inventory.contents_changed.disconnect(_refresh)
	inventory = value
	if inventory != null:
		inventory.contents_changed.connect(_refresh)
	_refresh()

func get_displayed_item() -> GhostItemInstance:
	return inventory.exhibition_item(slot) if is_instance_valid(inventory) else null

func _refresh() -> void:
	if not is_instance_valid(model):
		return
	displayed = get_displayed_item()
	# Render a display-only snapshot of the genuine stored look. Debug
	# preview overrides do not leak into the permanent exhibition.
	var view: GhostItemInstance = null
	if displayed != null:
		view = inventory._deserialize_item(inventory._serialize_item(displayed, Vector2i(-1, -1)))
	model.call("set_item", view)
	caption.text = display_caption(displayed, slot)
	caption.add_theme_color_override("font_color", displayed.quality_color().lerp(Color("f5e6ec"), 0.32) if displayed != null else Color("a99ba9"))
	provenance.text = display_provenance(displayed)
	queue_redraw()

# Read-only labels always use the actual stored instance, not the icon's
# base name or a generated replacement. No seed is presented as ownership proof.
static func display_caption(item: GhostItemInstance, display_slot: int) -> String:
	if item == null:
		return "%02d  ·  Empty display" % [display_slot + 1]
	return "%02d  ·  %s" % [display_slot + 1, item.display_name()]

static func display_provenance(item: GhostItemInstance) -> String:
	if item == null:
		return "Awaiting a cherished find"
	var location: String = item.origin_label()
	var material: String = item.collector_material_label()
	if location.is_empty():
		return material
	return "%s  ·  %s" % [material, location]

func _process(delta: float) -> void:
	if Engine.is_editor_hint() or not is_instance_valid(model):
		return
	time += delta
	model.position.y = -94.0 + sin(time * 1.25 + float(slot)) * 3.0
	queue_redraw()

func _draw() -> void:
	# Small carved plinth and gilded frame; original room painting untouched.
	draw_set_transform(Vector2(0, -5), 0.0, Vector2(1.0, 0.34))
	draw_circle(Vector2.ZERO, 54.0, Color(0.045, 0.025, 0.065, 0.55))
	draw_set_transform(Vector2.ZERO)
	draw_colored_polygon(PackedVector2Array([Vector2(-44,-13),Vector2(44,-13),Vector2(35,8),Vector2(-35,8)]), Color("302535"))
	draw_rect(Rect2(-42,-17,84,6), Color("806773"))
	draw_line(Vector2(-35,7),Vector2(35,7),Color("ab8992"),1.2,true)
	draw_rect(Rect2(-43,-165,86,145), Color(0.09,0.055,0.13,0.65))
	draw_rect(Rect2(-43,-165,86,145), Color("705769"),false,1.2)
	for side in [-1.0, 1.0]:
		var p: Vector2 = Vector2(side * 43.0,-165)
		draw_circle(p,3.2,Color("c0a086"))
	if displayed != null:
		var ink: Color = displayed.quality_color()
		draw_circle(Vector2(0,-22),20.0,Color(ink.r,ink.g,ink.b,0.07))
		# Restrained display illumination; glow only, never edits the owned item.
		var pulse: float = 0.88 + 0.12 * sin(time * 1.4 + float(slot))
		draw_circle(Vector2(0, -107), 39.0, Color(ink.r, ink.g, ink.b, 0.024 * pulse))
		draw_arc(Vector2(0, -107), 39.0, PI * 0.12, PI * 0.88, 24, Color(ink.r, ink.g, ink.b, 0.28 * pulse), 1.4, true)
		for side in [-1.0, 1.0]:
			draw_circle(Vector2(side * 34.0, -143.0), 2.1, Color(ink.r, ink.g, ink.b, 0.47 * pulse))
