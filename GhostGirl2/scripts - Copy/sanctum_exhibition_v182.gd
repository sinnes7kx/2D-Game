@tool
extends Node2D
## Editor-positionable, non-pickup display. The actual item remains in the vault.
const MODEL = preload("res://scripts/collector_lens_model_v179.gd")
@export_range(0, 5) var slot: int = 0
var inventory: Node
var model: Node2D
var displayed: GhostItemInstance
var caption: Label
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
	caption.position = Vector2(-88, 9)
	caption.size = Vector2(176, 42)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_font_size_override("font_size", 12)
	caption.add_theme_color_override("font_color", Color("e0c7d9"))
	add_child(caption)
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
	caption.text = "%02d  ·  %s" % [slot + 1, displayed.definition.display_name if displayed != null else "Empty display"]
	queue_redraw()

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
