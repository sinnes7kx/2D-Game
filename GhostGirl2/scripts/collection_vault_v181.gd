extends Control
signal inspect_requested(item: GhostItemInstance)
var inventory: Node
var selected_item: GhostItemInstance
var list: ItemList
var details: Label
var count_label: Label
var search: LineEdit
var favorites: CheckButton
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
	panel.custom_minimum_size = Vector2(810, 540)
	center.add_child(panel)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color("211b29")
	style.border_color = Color("a18a9e")
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	var layout: VBoxContainer = VBoxContainer.new()
	panel.add_child(layout)
	var title: Label = Label.new()
	header_title = title
	title.text = "THE COLLECTION VAULT"
	title.add_theme_font_size_override("font_size", 23)
	title.add_theme_color_override("font_color", Color("dfc38e"))
	layout.add_child(title)
	count_label = Label.new()
	layout.add_child(count_label)
	var filters: HBoxContainer = HBoxContainer.new()
	layout.add_child(filters)
	source_view = OptionButton.new()
	source_view.add_item("Stored")
	source_view.add_item("Backpack")
	filters.add_child(source_view)
	source_view.item_selected.connect(func(_index: int) -> void:
		selected_item = null
		refresh())
	search = LineEdit.new()
	search.placeholder_text = "Search weapon, rarity or region"
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filters.add_child(search)
	search.text_changed.connect(func(_value: String) -> void: refresh())
	favorites = CheckButton.new()
	favorites.text = "Favorites only"
	filters.add_child(favorites)
	favorites.toggled.connect(func(_value: bool) -> void: refresh())
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
	layout.add_child(exhibition)
	display_slot = OptionButton.new()
	exhibition.add_child(display_slot)
	display_button = _button(exhibition, "Display in Sanctum", _assign_display)
	clear_display = _button(exhibition, "Remove from display", _remove_display)
	var actions: HBoxContainer = HBoxContainer.new()
	layout.add_child(actions)
	deposit = _button(actions, "Store selected", _store)
	withdraw = _button(actions, "Withdraw", _withdraw)
	inspect = _button(actions, "Inspect", _inspect)
	favorite = _button(actions, "Favorite", _favorite)
	lock = _button(actions, "Protect", _lock)
	_button(actions, "Close", hide)
	hide()

func _button(parent: HBoxContainer, label_text: String, callback: Callable) -> Button:
	var b: Button = Button.new()
	b.text = label_text
	parent.add_child(b)
	b.pressed.connect(callback)
	return b

func open_vault(value: Node, candidate: GhostItemInstance, preferred_slot: int = -1, access: Callable = Callable()) -> void:
	transfer_access = access
	header_title.text = "LANTERNHAVEN STASH" if _can_transfer() else "COLLECTION VIEW · STASH IN TOWN"
	inventory = value
	selected_item = candidate
	source_view.select(1 if candidate != null and inventory.contents.has(candidate) else 0)
	search.clear()
	favorites.set_pressed_no_signal(false)
	show()
	refresh()
	if preferred_slot >= 0 and preferred_slot < display_slot.item_count:
		display_slot.select(preferred_slot)

func refresh() -> void:
	if inventory == null:
		return
	list.clear()
	shown.clear()
	var query: String = search.text.strip_edges().to_lower()
	var candidates: Array = inventory.vault if source_view.selected == 0 else inventory.contents
	for item in candidates:
		if item.get_slot() not in ["sword", "wand"]:
			continue
		if favorites.button_pressed and not item.collector_favorite:
			continue
		var label_text: String = "%s%s%s  ·  %s%s" % ["★ " if item.collector_favorite else "", "[Protected] " if item.collector_locked else "", item.display_name(), item.collector_material_label(), " · Display %d" % (item.exhibition_slot + 1) if item.exhibition_slot >= 0 else ""]
		if item.ethereal:
			label_text += " · Broken" if item.is_broken() else " · %d/%d durability" % [item.durability, item.max_durability]
		if not item.regional_imprint_label().is_empty():
			label_text += " · " + item.regional_imprint_label()
		shown.append(item)
		var index: int = list.add_item(label_text, item.definition.icon)
		list.set_item_custom_fg_color(index, item.quality_color())
	count_label.text = "%d / %d weapons and wands stored" % [inventory.vault.size() + inventory.unresolved_vault.size(), inventory.VAULT_CAPACITY]
	if shown.has(selected_item):
		list.select(shown.find(selected_item))
	_refresh_displays()
	_update_buttons()

func _select(index: int) -> void:
	if index >= 0 and index < shown.size():
		selected_item = shown[index]
	_update_buttons()

func _update_buttons() -> void:
	var stored: bool = selected_item != null and inventory.vault.has(selected_item)
	var carried: bool = selected_item != null and inventory.contents.has(selected_item)
	deposit.disabled = not _can_transfer() or not carried or (selected_item.get_slot() not in ["sword", "wand"] if carried else true)
	display_button.disabled = not stored
	clear_display.disabled = not stored or selected_item.exhibition_slot < 0 if stored else true
	withdraw.disabled = not stored or not _can_transfer()
	inspect.disabled = not (stored or carried)
	favorite.disabled = not (stored or carried)
	lock.disabled = not (stored or carried)
	if stored or carried:
		details.text = "%s  ·  %s  ·  %s" % [selected_item.display_name(), selected_item.collector_material_label(), "Stored safely" if stored else "In backpack — unequip to store"]
		favorite.text = "Unfavorite" if selected_item.collector_favorite else "Favorite"
		lock.text = "Unlock" if selected_item.collector_locked else "Protect"
		if stored and selected_item.exhibition_slot >= 0:
			details.text += " · Sanctum display %d" % (selected_item.exhibition_slot + 1)
			display_slot.select(selected_item.exhibition_slot)
	else:
		details.text = "Choose Stored or Backpack above, then select an item. Transfers require the town stash."
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
		details.text = "Cannot withdraw: backpack full or save unavailable. Weapon remains in vault."

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
