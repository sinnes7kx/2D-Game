extends Control
## D2 backpack: click item to lift; click an empty cell to place; right-click equip.
signal item_pick_requested(index: int)
signal item_place_requested(page: int, col: int, row: int)
signal item_cancel_requested
signal item_activated(index: int)
signal item_hovered(index: int)
const CELL: float = 46.0
const COLS: int = 10
const ROWS: int = 6
var inventory = null
var page: int = 0
var selected_index: int = -1
var cursor_index: int = -1
var hover_index: int = -1
var hover_cell: Vector2i = Vector2i(-1,-1)

func _display_icon(item: Variant) -> Texture2D:
	if item == null or item.definition == null or item.definition.icon == null:
		return null
	# Keep the real icon in inventory slots. The mythic flipped-icon indicator
	# remains available in the details/appearance UI instead of replacing the
	# source art and turning some imported icons into white boxes.
	return item.definition.icon


func _ready() -> void:
	custom_minimum_size = Vector2(COLS * CELL, ROWS * CELL)
	mouse_filter = Control.MOUSE_FILTER_STOP

func setup(source: Node) -> void:
	inventory = source
	if not inventory.contents_changed.is_connected(queue_redraw):
		inventory.contents_changed.connect(queue_redraw)
	queue_redraw()

func set_page(next_page: int) -> void:
	page = clampi(next_page, 0, 7)
	queue_redraw()

func set_selected(index: int) -> void:
	selected_index = index
	queue_redraw()

func set_cursor_item(index: int) -> void:
	cursor_index = index
	queue_redraw()

func _cell_at(point: Vector2) -> Vector2i:
	return Vector2i(int(floor(point.x / CELL)), int(floor(point.y / CELL)))

func _gui_input(event: InputEvent) -> void:
	if inventory == null:
		return
	if event is InputEventMouseMotion:
		var cell: Vector2i = _cell_at(event.position)
		hover_cell=cell
		if cursor_index>=0:
			queue_redraw()
		var index: int = inventory.get_grid_index(page, cell.x, cell.y)
		if index != hover_index:
			hover_index = index
			item_hovered.emit(index)
	if event is InputEventMouseButton and event.pressed:
		var cell: Vector2i = _cell_at(event.position)
		if cell.x < 0 or cell.y < 0 or cell.x >= COLS or cell.y >= ROWS:
			return
		var index: int = inventory.get_grid_index(page, cell.x, cell.y)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if cursor_index >= 0:
				item_place_requested.emit(page, cell.x, cell.y)
			elif index >= 0:
				item_pick_requested.emit(index)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if cursor_index >= 0:
				item_cancel_requested.emit()
			elif index >= 0:
				item_activated.emit(index)
			accept_event()

func _notification(what: int) -> void:
	if what == NOTIFICATION_MOUSE_EXIT:
		hover_index = -1
		hover_cell=Vector2i(-1,-1)
		queue_redraw()
		item_hovered.emit(-1)

func _draw() -> void:
	var border: Color = Color(0.29, 0.25, 0.27, 0.88)
	for r in range(ROWS):
		for c in range(COLS):
			var rect: Rect2 = Rect2(Vector2(c, r) * CELL, Vector2(CELL - 2, CELL - 2))
			draw_rect(rect, Color(0.07, 0.064, 0.075, 0.96))
			draw_rect(rect, border, false, 1.0)
			var p: Vector2 = rect.position + Vector2(2, 2)
			draw_line(p, p + Vector2(7, 0), Color(0.51, 0.40, 0.33, 0.5), 1.0)
			draw_line(p, p + Vector2(0, 7), Color(0.51, 0.40, 0.33, 0.5), 1.0)
	if inventory == null:
		return
	for index in range(inventory.contents.size()):
		var item: Variant = inventory.get_item(index)
		var pos: Vector2i = inventory.get_position(index)
		var footprint: Vector2i = inventory.get_item_size(item)
		if int(floor(float(pos.y) / float(ROWS))) != page:
			continue
		var origin: Vector2 = Vector2(pos.x, pos.y - page * ROWS) * CELL
		var bounds: Rect2 = Rect2(origin + Vector2(2, 2), Vector2(footprint.x, footprint.y) * CELL - Vector2(6, 6))
		var rarity: Color = item.quality_color()
		var selected: bool = index == selected_index
		var held: bool = index == cursor_index
		draw_rect(bounds, Color(0.13, 0.11, 0.15, 0.67 if held else 0.98))
		draw_rect(bounds, Color(0.86, 0.70, 0.49) if selected else rarity.darkened(0.18), false, 2.0 if selected else 1.0)
		if not held and item.definition != null and item.definition.icon != null:
			var shown_icon: Texture2D = _display_icon(item)
			var source_size: Vector2 = Vector2(shown_icon.get_size())
			var available: Vector2 = bounds.size - Vector2(12, 22)
			var factor: float = minf(available.x / maxf(1.0, source_size.x), available.y / maxf(1.0, source_size.y))
			var image_size: Vector2 = source_size * factor
			draw_texture_rect(shown_icon, Rect2(bounds.position + (bounds.size - image_size) * 0.5 - Vector2(0, 5), image_size), false, Color(1, 1, 1, item.weapon_opacity()))
		if held:
			draw_string(get_theme_default_font(), bounds.position + Vector2(5, bounds.size.y * 0.5), "HELD", HORIZONTAL_ALIGNMENT_CENTER, bounds.size.x - 8, 12, Color(0.96, 0.82, 0.66))
		else:
			var name: String = item.definition.display_name if item.definition != null else "ITEM"
			if name.length() > 9:
				name = name.substr(0, 8) + "…"
			draw_string(get_theme_default_font(), bounds.position + Vector2(4, bounds.size.y - 6), name, HORIZONTAL_ALIGNMENT_LEFT, bounds.size.x - 8, 10, rarity)
		if not held and item.get_slot() != "none":
			# Item palette is a small enamel swatch, independent from rarity border.
			var swatch: Vector2 = bounds.position + Vector2(bounds.size.x - 10.0, bounds.size.y - 11.0)
			draw_circle(swatch, 6.5, Color(0.04, 0.035, 0.05, 0.93))
			draw_circle(swatch, 4.5, item.palette_color())
			if item.get_slot() == "sword" and item.weapon_style() in ["scythe", "halberd"]:
				draw_circle(swatch + Vector2(-12, 0), 5.0, Color(0.04, 0.035, 0.05, 0.93))
				draw_circle(swatch + Vector2(-12, 0), 3.7, item.weapon_gradient_color())
				draw_line(swatch + Vector2(-26, -4), swatch + Vector2(-22, 4), Color("d5c4d7"), 1.8)
				draw_line(swatch + Vector2(-31, 4), swatch + Vector2(-27, -4), Color("8aaec7"), 1.8)
		for socket in range(int(item.sockets)):
			draw_circle(bounds.position + Vector2(bounds.size.x - 9 - socket * 10, 9), 3.5, Color(0.84, 0.65, 0.79) if socket < item.socketed.size() else Color(0.37, 0.32, 0.37))

	if cursor_index>=0 and hover_cell.x>=0 and hover_cell.y>=0 and hover_cell.x<COLS and hover_cell.y<ROWS:
		var item: GhostItemInstance = inventory.get_item(cursor_index)
		if item!=null:
			var plan: Dictionary = inventory.placement_v284(cursor_index,page,hover_cell.x,hover_cell.y)
			var rect: Rect2 = Rect2(Vector2(hover_cell)*CELL,Vector2(inventory.get_item_size(item))*CELL-Vector2.ONE*2)
			var tint: Color = Color(0.35,0.68,0.40,0.30) if bool(plan.get("ok",false)) else Color(0.82,0.27,0.29,0.33)
			draw_rect(rect,tint)
			draw_rect(rect,tint.lightened(0.25),false,2.0)
