extends Control
signal inspect_requested(item: GhostItemInstance)
const FILTERS = preload("res://scripts/v208_vault_filters.gd")
var inventory: Node
var selected_item: GhostItemInstance
var list: ItemList
var details: Label
var count_label: Label
var search: LineEdit
var favorites: CheckButton
var family_filter: OptionButton
var quality_filter: OptionButton
var order_filter: OptionButton
var equip: Button
var exhibition_row: HBoxContainer
var deposit: Button
var withdraw: Button
var inspect: Button
var favorite: Button
var lock: Button
var shown: Array[GhostItemInstance] = []
var display_slot: OptionButton
var display_button: Button
var clear_display: Button
var source_view: OptionButton
var transfer_access: Callable
var header_title: Label
var physical_grid: Control
var grid_mode: bool = false
var grid_toggle: Button
var grid_tools: HBoxContainer
var grid_note: Label
var stash_tab_picker_v285: OptionButton
var stash_tab_name_v285: LineEdit
var filter_row: HBoxContainer
var advanced_row: HBoxContainer
var action_row: HBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.035, 0.025, 0.05, 0.95)
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center: CenterContainer = CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(810, 565)
	preload("res://scripts/gothic_ui_v273.gd").apply(panel)
	center.add_child(panel)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("19121e")
	style.border_color = Color("9f805c")
	style.set_border_width_all(2)
	style.set_corner_radius_all(3)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", preload("res://scripts/gothic_material_v274.gd").plate(Color("1b131f"),Color("a08056"),18,true))
	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation",10)
	panel.add_child(layout)
	var trim: Control = preload("res://scripts/gothic_frame_v241.gd").new()
	trim.top_level=true
	trim.mouse_filter=Control.MOUSE_FILTER_IGNORE
	panel.add_child(trim)
	var sync_trim: Callable = func() -> void:
		trim.global_position=panel.global_position
		trim.size=panel.size
	panel.item_rect_changed.connect(sync_trim)
	sync_trim.call_deferred()
	var title: Label = Label.new()
	header_title = title
	title.text = "❦  THE COLLECTION VAULT"
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color("dfc38e"))
	layout.add_child(title)
	count_label = Label.new()
	layout.add_child(count_label)
	var filters: HBoxContainer = HBoxContainer.new()
	filter_row=filters
	layout.add_child(filters)
	source_view = OptionButton.new()
	source_view.add_item("Stash")
	source_view.add_item("Backpack")
	filters.add_child(source_view)
	source_view.item_selected.connect(func(_index: int) -> void:
		selected_item = null
		refresh())
	search = LineEdit.new()
	search.placeholder_text = "Find a treasure…"
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filters.add_child(search)
	search.text_changed.connect(func(_value: String) -> void: refresh())
	favorites = CheckButton.new()
	favorites.text = "Favorites"
	filters.add_child(favorites)
	favorites.toggled.connect(func(_value: bool) -> void: refresh())
	var advanced: HBoxContainer = HBoxContainer.new()
	advanced_row=advanced
	advanced.add_theme_constant_override("separation", 10)
	layout.add_child(advanced)
	family_filter = OptionButton.new()
	family_filter.name = "FamilyFilterV208"
	for label_text in ["All equipment", "Swords / bows", "Wands", "Dresses", "Head accessories", "Tiaras / helms", "Trinkets", "Charms", "Familiars"]:
		family_filter.add_item(label_text)
	family_filter.tooltip_text = "Filter by actual equipment slot"
	family_filter.item_selected.connect(func(_i: int) -> void: refresh())
	advanced.add_child(family_filter)
	quality_filter = OptionButton.new()
	quality_filter.name = "QualityFilterV208"
	for label_text in ["Any quality", "Normal", "Magic", "Rare", "Set", "Unique"]:
		quality_filter.add_item(label_text)
	quality_filter.tooltip_text = "Filter by actual item quality"
	quality_filter.item_selected.connect(func(_i: int) -> void: refresh())
	advanced.add_child(quality_filter)
	order_filter = OptionButton.new()
	order_filter.name = "SortFilterV208"
	for label_text in ["Original order", "Highest quality first", "Name A-Z", "Equipment family"]:
		order_filter.add_item(label_text)
	order_filter.tooltip_text = "Only changes this list; never rearranges stored inventory"
	order_filter.item_selected.connect(func(_i: int) -> void: refresh())
	advanced.add_child(order_filter)
	list = ItemList.new()
	list.custom_minimum_size = Vector2(0, 320)
	list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list.fixed_icon_size = Vector2i(40, 40)
	layout.add_child(list)
	list.item_selected.connect(_select)
	list.item_activated.connect(func(_index: int) -> void: _inspect())
	details = Label.new()
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(details)
	var exhibition: HBoxContainer = HBoxContainer.new()
	exhibition_row=exhibition
	layout.add_child(exhibition)
	display_slot = OptionButton.new()
	exhibition.add_child(display_slot)
	display_button = _button(exhibition, "Display in Sanctum", _assign_display)
	clear_display = _button(exhibition, "Remove from display", _remove_display)
	var actions: HBoxContainer = HBoxContainer.new()
	action_row=actions
	layout.add_child(actions)
	equip = _button(actions,"Equip",_equip_selected_v273)
	deposit = _button(actions, "Store", _store)
	withdraw = _button(actions, "Withdraw", _withdraw)
	inspect = _button(actions, "Inspect", _inspect)
	favorite = _button(actions, "Favorite", _favorite)
	lock = _button(actions, "Protect", _lock)
	_button(actions, "Close", hide)
	grid_toggle=Button.new()
	grid_toggle.text="Collection list"
	layout.add_child(grid_toggle)
	grid_toggle.pressed.connect(func(): _set_grid_mode(not grid_mode))
	grid_tools=HBoxContainer.new()
	layout.add_child(grid_tools)
	physical_grid=preload("res://scripts/stash_grid_v284.gd").new()
	layout.add_child(physical_grid)
	stash_tab_picker_v285=OptionButton.new()
	stash_tab_picker_v285.custom_minimum_size.x=125
	grid_tools.add_child(stash_tab_picker_v285)
	stash_tab_picker_v285.item_selected.connect(func(i: int): physical_grid.call("choose_stash_v285",i))
	stash_tab_name_v285=LineEdit.new()
	stash_tab_name_v285.placeholder_text="Rename tab"
	stash_tab_name_v285.max_length=22
	stash_tab_name_v285.custom_minimum_size.x=110
	grid_tools.add_child(stash_tab_name_v285)
	stash_tab_name_v285.text_submitted.connect(func(_value: String): _rename_tab_v285())
	_button(grid_tools,"Rename",_rename_tab_v285)
	physical_grid.connect("page_changed_v285",Callable(self,"_refresh_tabs_v285"))
	_button(grid_tools,"◀ Stash",func(): physical_grid.call("step_page",true,-1))
	_button(grid_tools,"Stash ▶",func(): physical_grid.call("step_page",true,1))
	_button(grid_tools,"◀ Bag",func(): physical_grid.call("step_page",false,-1))
	_button(grid_tools,"Bag ▶",func(): physical_grid.call("step_page",false,1))
	_button(grid_tools,"Close",hide)
	grid_note=Label.new()
	grid_note.text="Click to pick/place · Ctrl-click transfer · right-click cancel"
	layout.add_child(grid_note)
	physical_grid.set("note",grid_note)
	visibility_changed.connect(func():
		if not visible: physical_grid.call("cancel"))
	_set_grid_mode(false)
	hide()

func _set_grid_mode(value: bool) -> void:
	grid_mode=value and _can_transfer()
	if physical_grid==null:
		return
	physical_grid.call("cancel")
	physical_grid.visible=grid_mode
	grid_tools.visible=grid_mode
	grid_note.visible=grid_mode
	for control in [filter_row,advanced_row,list,details,exhibition_row,action_row,count_label]:
		control.visible=not grid_mode
	grid_toggle.visible=_can_transfer()
	grid_toggle.text="Collection list" if grid_mode else "Item grids"
	if grid_mode and inventory!=null:
		physical_grid.call("setup",inventory,transfer_access)
		_refresh_tabs_v285()
	elif inventory!=null:
		refresh()

func _refresh_tabs_v285() -> void:
	if inventory==null or stash_tab_picker_v285==null:
		return
	var current: int = int(physical_grid.get("stash_page"))
	stash_tab_picker_v285.clear()
	for i in range(inventory.STASH_PAGES):
		stash_tab_picker_v285.add_item(inventory.stash_name_v285(i))
	stash_tab_picker_v285.select(current)
	stash_tab_name_v285.text=inventory.stash_name_v285(current)

func _rename_tab_v285() -> void:
	if inventory==null or not _can_transfer():
		return
	if inventory.rename_stash_v285(int(physical_grid.get("stash_page")),stash_tab_name_v285.text):
		_refresh_tabs_v285()
		physical_grid.queue_redraw()
	else:
		grid_note.text="Could not save tab name."

func _button(parent: HBoxContainer, label_text: String, callback: Callable) -> Button:
	var b: Button = Button.new()
	b.text = label_text
	parent.add_child(b)
	b.pressed.connect(callback)
	return b

func open_vault(value: Node, candidate: GhostItemInstance, preferred_slot: int = -1, access: Callable = Callable()) -> void:
	transfer_access = access
	header_title.text = "❦  LANTERNHAVEN STASH" if _can_transfer() else "❦  TREASURE COLLECTION"
	inventory = value
	selected_item = candidate
	source_view.select(1 if candidate != null and inventory.contents.has(candidate) else 0)
	search.clear()
	favorites.set_pressed_no_signal(false)
	family_filter.select(0)
	quality_filter.select(0)
	order_filter.select(0)
	show()
	_set_grid_mode(_can_transfer() and candidate==null and preferred_slot<0)
	if preferred_slot >= 0 and preferred_slot < display_slot.item_count:
		display_slot.select(preferred_slot)

func refresh() -> void:
	if inventory == null:
		return
	if grid_mode:
		inventory.sync_stash_v284()
		physical_grid.queue_redraw()
		return
	list.clear()
	shown.clear()
	var candidates: Array = inventory.vault if source_view.selected == 0 else inventory.contents
	var filtered: Array[GhostItemInstance] = FILTERS.filtered(candidates, FILTERS.FAMILIES[family_filter.selected], FILTERS.QUALITIES[quality_filter.selected], order_filter.selected, favorites.button_pressed, search.text)
	for item in filtered:
		var worn: bool = inventory.get_equipped(item.get_slot())==item
		var marks: String = ("★ " if item.collector_favorite else "")+("◆ " if item.collector_locked else "")+("✓ " if worn else "")
		var label_text: String = marks+item.display_name()+"   ·   "+item.collector_material_label()
		if item.is_broken():
			label_text+=" · Broken"
		shown.append(item)
		var index: int = list.add_item(label_text, item.definition.icon)
		list.set_item_custom_fg_color(index, item.quality_color())
	count_label.text = "BACKPACK  ·  %d treasures" % candidates.size() if source_view.selected==1 else "STASH  ·  %d / %d" % [inventory.vault.size()+inventory.unresolved_vault.size(),inventory.VAULT_CAPACITY]
	exhibition_row.visible=source_view.selected==0
	withdraw.visible=source_view.selected==0
	deposit.visible=source_view.selected==1
	equip.visible=source_view.selected==1
	if shown.has(selected_item):
		list.select(shown.find(selected_item))
	else:
		# Never let hidden selections trigger item transfers or changes.
		selected_item = null
	_refresh_displays()
	_update_buttons()

func _select(index: int) -> void:
	if index >= 0 and index < shown.size():
		selected_item = shown[index]
	_update_buttons()

func _update_buttons() -> void:
	var stored: bool = selected_item != null and inventory.vault.has(selected_item)
	var carried: bool = selected_item != null and inventory.contents.has(selected_item)
	var worn: bool = carried and inventory.get_equipped(selected_item.get_slot())==selected_item
	equip.disabled = not carried or worn or (selected_item.is_broken() if carried else true)
	equip.text = "Equipped" if worn else "Equip"
	deposit.disabled = not _can_transfer() or not carried or worn or (not inventory.equipment.has(selected_item.get_slot()) if carried else true)
	display_button.disabled = not stored
	clear_display.disabled = not stored or selected_item.exhibition_slot < 0 if stored else true
	withdraw.disabled = not stored or not _can_transfer()
	inspect.disabled = not (stored or carried)
	favorite.disabled = not (stored or carried)
	lock.disabled = not (stored or carried)
	if stored or carried:
		details.text = "%s  ·  %s  ·  %s" % [selected_item.display_name(), selected_item.collector_material_label(), "Stored safely" if stored else ("Equipped" if worn else "In backpack")]
		favorite.text = "Unfavorite" if selected_item.collector_favorite else "Favorite"
		lock.text = "Unlock" if selected_item.collector_locked else "Protect"
		if stored and selected_item.exhibition_slot >= 0:
			details.text += " · Sanctum display %d" % (selected_item.exhibition_slot + 1)
			display_slot.select(selected_item.exhibition_slot)
	else:
		details.text = "Select a treasure to inspect or equip." if source_view.selected==1 else "Select a stored treasure. Transfers require the town stash."
		favorite.text = "Favorite"
		lock.text = "Protect"

func _store() -> void:
	if not _can_transfer():
		details.text = "Return to the town stash to transfer items."
		return
	if selected_item == null:
		return
	var idx: int = inventory.contents.find(selected_item)
	if inventory.vault_store(idx):
		source_view.select(0)
		refresh()
	else:
		details.text = "Cannot store: unequip first, check vault space or save access."

func _withdraw() -> void:
	if not _can_transfer():
		details.text = "Return to the town stash to transfer items."
		return
	var idx: int = inventory.vault.find(selected_item)
	if inventory.vault_withdraw(idx):
		source_view.select(1)
		refresh()
	else:
		details.text = "Cannot withdraw: backpack full or save unavailable. Item remains in vault."

func _inspect() -> void:
	if selected_item != null:
		inspect_requested.emit(selected_item)

func _favorite() -> void:
	if selected_item != null and inventory.set_collector_flag(selected_item, "collector_favorite", not selected_item.collector_favorite):
		refresh()

func _lock() -> void:
	if selected_item != null and inventory.set_collector_flag(selected_item, "collector_locked", not selected_item.collector_locked):
		refresh()

func _refresh_displays() -> void:
	var prior: int = maxi(0, display_slot.selected)
	display_slot.clear()
	for slot in range(inventory.EXHIBITION_CAPACITY):
		var occupant: GhostItemInstance = inventory.exhibition_item(slot)
		var label_text: String = "Display %d — %s" % [slot + 1, occupant.display_name() if occupant != null else ("Unavailable item" if inventory.exhibition_reserved(slot) else "Empty")]
		display_slot.add_item(label_text, slot)
		display_slot.set_item_disabled(slot, inventory.exhibition_reserved(slot))
	display_slot.select(clampi(prior, 0, display_slot.item_count - 1))

func _assign_display() -> void:
	if selected_item != null and inventory.set_exhibition(selected_item, display_slot.selected):
		refresh()
	else:
		details.text = "Could not assign display. The collection remains unchanged."

func _remove_display() -> void:
	if selected_item != null and inventory.set_exhibition(selected_item, -1):
		refresh()

func _can_transfer() -> bool:
	return bool(transfer_access.call()) if transfer_access.is_valid() else true

func _equip_selected_v273() -> void:
	if inventory==null or selected_item==null or not inventory.contents.has(selected_item):
		return
	var idx: int = inventory.contents.find(selected_item)
	if inventory.equip_at(idx):
		refresh()
	else:
		details.text="This treasure cannot be equipped."
