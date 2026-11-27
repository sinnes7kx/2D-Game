extends Control
## Two physical grids; the cursor reserves its source until a valid drop.
const CELL: float = 32.0
const STASH_ORIGIN: Vector2 = Vector2(0,30)
const BAG_ORIGIN: Vector2 = Vector2(410,30)
var inventory: Node
var access: Callable
var stash_page: int = 0
var bag_page: int = 0
var held: GhostItemInstance
var held_stash: bool = false
var mouse: Vector2 = Vector2(-100,-100)
var note: Label
var tabs: Label

func _ready() -> void:
	custom_minimum_size=Vector2(744,430)
	mouse_filter=Control.MOUSE_FILTER_STOP
	mouse_exited.connect(func():
		mouse=Vector2(-100,-100)
		queue_redraw())

func setup(source: Node,gate: Callable) -> void:
	inventory=source
	access=gate
	inventory.sync_stash_v284()
	cancel()

func allowed() -> bool:
	return access.is_valid() and bool(access.call())

func cancel() -> void:
	held=null
	queue_redraw()

func step_page(stash: bool,step: int) -> void:
	if stash:
		stash_page=clampi(stash_page+step,0,inventory.STASH_PAGES-1)
	else:
		bag_page=clampi(bag_page+step,0,inventory.GRID_PAGES-1)
	queue_redraw()

func _zone(at: Vector2) -> Dictionary:
	for stash in [true,false]:
		var origin: Vector2 = STASH_ORIGIN if stash else BAG_ORIGIN
		var cols: int = 12 if stash else 10
		var rows: int = 12 if stash else 6
		var local: Vector2 = (at-origin)/CELL
		var cell: Vector2i = Vector2i(floori(local.x),floori(local.y))
		if cell.x>=0 and cell.y>=0 and cell.x<cols and cell.y<rows:
			var page: int = stash_page if stash else bag_page
			return {"stash":stash,"cell":cell,"pos":Vector2i(cell.x,page*rows+cell.y),"page":page}
	return {}

func _item(zone: Dictionary) -> GhostItemInstance:
	if bool(zone["stash"]):
		return inventory.stash_at_v284(zone["page"],zone["cell"].x,zone["cell"].y)
	return inventory.get_item(inventory.get_grid_index(zone["page"],zone["cell"].x,zone["cell"].y))

func _valid(zone: Dictionary) -> bool:
	if held==null or zone.is_empty() or not allowed():
		return false
	var stash: bool = zone["stash"]
	if stash:
		if not held_stash and (inventory.equipment.values().has(inventory.contents.find(held)) or held.definition.item_class=="quest" or inventory.vault.size()+inventory.unresolved_vault.size()>=inventory.VAULT_CAPACITY):
			return false
		return bool(inventory.stash_placement_v284(held,zone["pos"]).get("ok",false)) if held_stash else inventory.stash_fits_v284(held,zone["pos"])
	if held_stash:
		return inventory._fits(held,zone["pos"])
	return bool(inventory.placement_v284(inventory.contents.find(held),zone["page"],zone["cell"].x,zone["cell"].y).get("ok",false))

func _say(message: String) -> void:
	if note!=null:
		note.text=message

func _gui_input(event: InputEvent) -> void:
	if inventory==null:
		return
	if event is InputEventMouseMotion:
		mouse=event.position
		queue_redraw()
	if not event is InputEventMouseButton or not event.pressed:
		return
	if event.button_index==MOUSE_BUTTON_RIGHT:
		cancel()
		accept_event()
		return
	if event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		step_page(event.position.x<400,-1 if event.button_index==MOUSE_BUTTON_WHEEL_UP else 1)
		accept_event()
		return
	if event.button_index!=MOUSE_BUTTON_LEFT:
		return
	var z: Dictionary = _zone(event.position)
	if z.is_empty():
		return
	accept_event()
	if not allowed():
		_say("Return to the town stash.")
		return
	if held!=null:
		if not _valid(z):
			_say("Item will not fit here.")
			return
		var target_stash: bool = z["stash"]
		var ok: bool = false
		if target_stash!=held_stash:
			ok=inventory.transfer_grid_v284(held,target_stash,z["pos"])
		elif target_stash:
			ok=inventory.move_stash_v284(held,z["pos"])
		else:
			ok=inventory.place_or_swap_v284(inventory.contents.find(held),z["page"],z["cell"].x,z["cell"].y)
		if ok:
			cancel()
			_say("Item placed.")
		else:
			_say("Transfer failed; original item preserved.")
		return
	var item: GhostItemInstance = _item(z)
	if item==null:
		return
	if event.ctrl_pressed:
		var to_stash: bool = not bool(z["stash"])
		var pos: Vector2i = inventory.stash_open_v284(item,stash_page) if to_stash else inventory._first_open(item)
		if pos.x>=0 and inventory.transfer_grid_v284(item,to_stash,pos):
			_say("Item transferred.")
		else:
			_say("No fitting space, equipped item or save unavailable.")
	else:
		held=item
		held_stash=bool(z["stash"])
		_say(item.display_name()+" · choose destination")
	queue_redraw()

func _draw() -> void:
	if inventory==null:
		return
	var font: Font = get_theme_default_font()
	draw_string(font,Vector2(0,20),"STASH   %d / %d"%[stash_page+1,inventory.STASH_PAGES],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("d9bd90"))
	draw_string(font,Vector2(410,20),"BACKPACK   %d / %d"%[bag_page+1,inventory.GRID_PAGES],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("d9bd90"))
	for stash in [true,false]:
		var origin: Vector2 = STASH_ORIGIN if stash else BAG_ORIGIN
		var cols: int = 12 if stash else 10
		var rows: int = 12 if stash else 6
		var page: int = stash_page if stash else bag_page
		for y in range(rows):
			for x in range(cols):
				var r: Rect2 = Rect2(origin+Vector2(x,y)*CELL,Vector2.ONE*(CELL-1))
				draw_rect(r,Color("18141e"))
				draw_rect(r,Color("51434d"),false,1)
		var items: Array = inventory.vault if stash else inventory.contents
		for i in range(items.size()):
			var item: GhostItemInstance = items[i]
			if item==held:
				continue
			var pos: Vector2i = inventory.stash_position_v284(item) if stash else inventory.get_position(i)
			if pos.x<0 or int(pos.y/rows)!=page:
				continue
			var rect: Rect2 = Rect2(origin+Vector2(pos.x,posmod(pos.y,rows))*CELL+Vector2.ONE,Vector2(inventory.get_item_size(item))*CELL-Vector2.ONE*3)
			_draw_item(item,rect)
			if not stash and inventory.equipment.values().has(i):
				draw_string(font,rect.position+Vector2(3,12),"E",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("cbe4bd"))
	if held!=null:
		var zone: Dictionary = _zone(mouse)
		if not zone.is_empty():
			var origin: Vector2 = STASH_ORIGIN if zone["stash"] else BAG_ORIGIN
			var rect: Rect2 = Rect2(origin+Vector2(zone["cell"])*CELL,Vector2(inventory.get_item_size(held))*CELL)
			var color: Color = Color(0.35,0.65,0.40,0.48) if _valid(zone) else Color(0.75,0.25,0.24,0.48)
			draw_rect(rect,color)
			draw_rect(rect,color.lightened(0.25),false,2)
			_draw_item(held,rect.grow(-3),0.72)
		else:
			_draw_item(held,Rect2(mouse+Vector2(8,8),Vector2(inventory.get_item_size(held))*CELL),0.8)

func _draw_item(item: GhostItemInstance,rect: Rect2,opacity: float=1.0) -> void:
	var ink: Color = item.quality_color()
	draw_rect(rect,Color(ink.r,ink.g,ink.b,0.13*opacity))
	draw_rect(rect,Color(ink.r,ink.g,ink.b,0.85*opacity),false,1.3)
	if item.definition.icon!=null:
		var tex: Texture2D = item.definition.icon
		var original: Vector2 = tex.get_size()
		var factor: float = minf((rect.size.x-6)/maxf(1,original.x),(rect.size.y-6)/maxf(1,original.y))
		var dimensions: Vector2 = original*factor
		draw_texture_rect(tex,Rect2(rect.get_center()-dimensions*0.5,dimensions),false,Color(1,1,1,opacity))
