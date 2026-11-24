extends CanvasLayer
const COLLECTOR_LENS = preload("res://scripts/collector_lens_v179.gd")
var collector_lens: Control
const COLLECTION_VAULT = preload("res://scripts/collection_vault_v181.gd")
var collection_vault: Control
## Minimal node-authored HUD. No dialogue, no lore overlays, no objectives.
## Every onscreen element can be selected, moved or styled in hud.tscn.

const EMOTIONS: Dictionary = {
	"neutral": preload("res://assets/ui/neutral.png"),
	"crying": preload("res://assets/ui/crying.png"),
	"smiling": preload("res://assets/ui/smiling.png"),
	"surprised": preload("res://assets/ui/surprised.png"),
	"worried": preload("res://assets/ui/worried.png")
}

@onready var location_label: Label = $Overlay/LocationLabel
@onready var vigil_label: Label = $Overlay/VigilStatus
@onready var prompt_label: Label = $Overlay/ContextHint
@onready var carrying_label: Label = $Overlay/CarryingHint
@onready var portrait: TextureRect = $Overlay/ExpressionPortrait
@onready var help_panel: Label = $Overlay/ControlsGuide
var inventory_panel: PanelContainer
var equipment_panel: PanelContainer
var item_compare_popup: Control
var hovered_item: Variant = null
var hovered_equipped: Variant = null
var hover_ctrl_down: bool = false
var hover_alt_down: bool = false
var inventory_data: Node
var cursor_item_index: int = -1
var drop_click_guard: int = 0
@onready var held_treasure: PanelContainer = $Overlay/HeldTreasure
@onready var held_icon: TextureRect = $Overlay/HeldTreasure/HeldIcon
@onready var pickup_toast: Label = $Overlay/PickupToast
@onready var health_meter: ProgressBar = $Overlay/HealthMeter
@onready var stamina_meter: ProgressBar = $Overlay/StaminaMeter
@onready var dew_label: Label = $Overlay/HealingDew
@onready var lock_label: Label = $Overlay/LockHint
var pickup_time: float = 0.0
var location_time: float = 0.0
var expression_time: float = 0.0

# Both panel scenes attach their own controllers (editor-safe native layouts).
func _ready() -> void:
	inventory_panel = $Overlay/InventoryPanel as PanelContainer
	equipment_panel = $Overlay/EquipmentPanel as PanelContainer
	item_compare_popup = $Overlay/ItemComparePopup as Control
	inventory_panel.connect("item_hovered", Callable(self, "_show_item_hover"))
	inventory_panel.connect("item_hover_cleared", Callable(self, "_hide_item_hover"))
	equipment_panel.connect("item_hovered", Callable(self, "_show_item_hover"))
	equipment_panel.connect("item_hover_cleared", Callable(self, "_hide_item_hover"))
	inventory_panel.connect("cursor_pick_requested", Callable(self, "_take_cursor_item"))
	inventory_panel.connect("cursor_place_requested", Callable(self, "_place_cursor_item"))
	inventory_panel.connect("cursor_cancel_requested", Callable(self, "_cancel_cursor_item"))
	inventory_panel.connect("cursor_drop_requested", Callable(self, "_drop_selected_item"))
	inventory_panel.connect("inspect_requested", Callable(self, "_open_collector_lens"))
	vigil_label.visible = false
	prompt_label.visible = false
	carrying_label.visible = false
	help_panel.visible = false
	pickup_toast.visible = false
	health_meter.visible = false
	stamina_meter.visible = false
	portrait.texture = EMOTIONS["neutral"]
	collector_lens = COLLECTOR_LENS.new()
	collector_lens.name = "CollectorLensV179"
	$Overlay.add_child(collector_lens)
	collector_lens.z_index = 100
	collection_vault = COLLECTION_VAULT.new()
	collection_vault.name = "CollectionVaultV181"
	$Overlay.add_child(collection_vault)
	collection_vault.z_index = 90
	collection_vault.connect("inspect_requested", Callable(self, "_open_collector_lens"))
	inventory_panel.connect("vault_requested", Callable(self, "_open_collection_vault"))

func bind_inventory(value: Node) -> void:
	inventory_data = value
	if inventory_panel.has_method("bind_inventory"):
		inventory_panel.call("bind_inventory", value)
	if equipment_panel.has_method("bind_inventory"):
		equipment_panel.call("bind_inventory", value)

func set_vigil_status(in_moor: bool, gathered: int, completed: bool) -> void:
	vigil_label.visible = in_moor
	if completed:
		vigil_label.text = "MOOR VIGIL  ·  WARDEN VANQUISHED"
	elif gathered >= 4:
		vigil_label.text = "MOOR VIGIL  ·  4 / 4  ·  SEEK THE WARDEN ALTAR"
	else:
		vigil_label.text = "MOOR VIGIL  ·  %d / 4 LAMENTS" % gathered

# After the Warden falls, reuse the quiet objective line rather than adding
# another HUD panel. The old Four Laments status method stays compatible.
func set_bellglass_status(in_moor: bool, warden_defeated: bool, echoes: int) -> void:
	if not in_moor or not warden_defeated:
		return
	if echoes >= 3:
		vigil_label.text = "BELLGLASS ECHOES  ·  3 / 3  ·  CLAIM THE RELIQUARY"
	else:
		vigil_label.text = "BELLGLASS ECHOES  ·  %d / 3  ·  HOOK  /  FROST  /  JUMP SHOT" % echoes

# Reuse the already-authored quiet objective label only while an optional
# early-room trial is active. No permanent quest HUD or new blocking panel.
func set_echo_trial_progress(active: bool, title_text: String = "", wave: int = 0, waves: int = 0, seconds: float = 0.0, hits: int = 0) -> void:
	if not active:
		vigil_label.visible = false
		return
	vigil_label.visible = true
	vigil_label.text = "%s  ·  %d / %d  ·  %.1f s  ·  HITS %d" % [title_text, wave, waves, seconds, hits]

# v1.48: same restrained objective line as trials, visible only during the run.
func set_rose_run_progress(active: bool, hooked: int = 0, remaining: float = 0.0) -> void:
	if not active:
		vigil_label.visible = false
		return
	vigil_label.visible = true
	vigil_label.text = "ROSE PATH  ·  %d / 3  ·  %.1f s" % [hooked, maxf(0.0, remaining)]

func show_pickup(label_text: String, tint: Color = Color("d9cbd0")) -> void:
	pickup_toast.text = label_text.to_upper()
	pickup_toast.add_theme_color_override("font_color", tint)
	pickup_toast.visible = true
	pickup_toast.modulate.a = 0.90
	pickup_time = 2.6

func _process(delta: float) -> void:
	# Keep CTRL comparisons live even if the mouse stays on the same grid cell.
	if hovered_item != null and item_compare_popup != null and item_compare_popup.visible:
		var ctrl_now: bool = Input.is_key_pressed(KEY_CTRL)
		var alt_now: bool = Input.is_key_pressed(KEY_ALT)
		if ctrl_now != hover_ctrl_down or alt_now != hover_alt_down:
			hover_ctrl_down = ctrl_now
			hover_alt_down = alt_now
			var compare_item: Variant = hovered_equipped if ctrl_now else null
			item_compare_popup.call("display_item", hovered_item, compare_item, alt_now)
	if drop_click_guard > 0:
		drop_click_guard -= 1
	if cursor_item_index >= 0 and inventory_data != null:
		var carried: Variant = inventory_data.get_item(cursor_item_index)
		if carried == null:
			_cancel_cursor_item()
		else:
			var mouse: Vector2 = get_viewport().get_mouse_position()
			var viewport_size: Vector2 = get_viewport().get_visible_rect().size
			held_treasure.position = Vector2(clampf(mouse.x + 19.0, 0.0, viewport_size.x - 78.0), clampf(mouse.y + 20.0, 0.0, viewport_size.y - 84.0))
	if pickup_time > 0.0:
		pickup_time -= delta
		pickup_toast.modulate.a = clampf(pickup_time / 0.7, 0.0, 0.90)
		if pickup_time <= 0.0:
			pickup_toast.visible = false
	if location_time > 0.0:
		location_time -= delta
		location_label.modulate.a = clampf(location_time / 1.2, 0.0, 0.74)
	if expression_time > 0.0:
		expression_time -= delta
		if expression_time <= 0.0:
			portrait.texture = EMOTIONS["neutral"]

func has_cursor_item() -> bool:
	return cursor_item_index >= 0 or drop_click_guard > 0

func _take_cursor_item(index: int) -> void:
	if inventory_data == null or cursor_item_index >= 0:
		return
	var item: Variant = inventory_data.get_item(index)
	if item == null:
		return
	cursor_item_index = index
	inventory_panel.call("set_cursor_item", index)
	held_icon.texture = item.definition.icon if item.definition != null else null
	held_treasure.show()
	_hide_item_hover()

func _cancel_cursor_item() -> void:
	cursor_item_index = -1
	inventory_panel.call("set_cursor_item", -1)
	held_treasure.hide()
	held_icon.texture = null
	_hide_item_hover()

func _place_cursor_item(page: int, col: int, row: int) -> void:
	if cursor_item_index < 0 or inventory_data == null:
		return
	var item: Variant = inventory_data.get_item(cursor_item_index)
	if item == null:
		_cancel_cursor_item()
		return
	var existing: int = inventory_data.get_grid_index(page, col, row)
	if existing >= 0 and existing != cursor_item_index:
		show_pickup("SPACE OCCUPIED — CHOOSE EMPTY CELLS")
		return
	if inventory_data.move_item_at(cursor_item_index, page, col, row):
		_cancel_cursor_item()
	else:
		show_pickup("ITEM WILL NOT FIT THERE")

func _drop_selected_item(index: int) -> void:
	if inventory_data == null or index < 0:
		return
	# Do not silently drop a different item from the one being carried.
	if cursor_item_index >= 0 and cursor_item_index != index:
		index = cursor_item_index
	if get_parent().call("drop_inventory_item", index):
		drop_click_guard = 2
		_cancel_cursor_item()
		inventory_panel.call("clear_selection")

func _input(event: InputEvent) -> void:
	if is_instance_valid(collector_lens) and collector_lens.visible:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			collector_lens.call("close_lens")
			get_viewport().set_input_as_handled()
		return
	if is_instance_valid(collection_vault) and collection_vault.visible:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			collection_vault.hide()
			get_viewport().set_input_as_handled()
		return
	if is_menu_open():
		var inspect: bool = false
		if event is InputEventMouseButton:
			inspect = event.pressed and event.shift_pressed and event.button_index == MOUSE_BUTTON_RIGHT
		elif event is InputEventKey:
			inspect = event.pressed and not event.echo and event.physical_keycode == KEY_P
		if inspect:
			var candidate: GhostItemInstance = hovered_item as GhostItemInstance
			if candidate == null or candidate.get_slot() not in ["sword", "wand"]:
				candidate = inventory_panel.call("selected_weapon_for_inspection") as GhostItemInstance
			if candidate != null:
				_open_collector_lens(candidate)
				get_viewport().set_input_as_handled()
				return
	if cursor_item_index < 0 or not (event is InputEventMouseButton):
		return
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	if not mouse_event.pressed:
		return
	if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		_cancel_cursor_item()
		drop_click_guard = 2
		get_viewport().set_input_as_handled()
		return
	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return
	if is_menu_open():
		# Inventory and equipment own their mouse input; only clicks on bare
		# world space (outside both windows) may release a carried treasure.
		if inventory_panel.get_global_rect().has_point(mouse_event.position) or equipment_panel.get_global_rect().has_point(mouse_event.position):
			return
	_drop_selected_item(cursor_item_index)
	get_viewport().set_input_as_handled()

func _unhandled_key_input(event: InputEvent) -> void:
	if is_instance_valid(collection_vault) and collection_vault.visible:
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(collector_lens) and collector_lens.visible:
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB or event.physical_keycode == KEY_I:
			# A single Diablo-like view contains equipment and backpack together.
			var opening: bool = not (inventory_panel.visible and equipment_panel.visible)
			inventory_panel.visible = opening
			equipment_panel.visible = opening
			if opening:
				inventory_panel.call("refresh")
				equipment_panel.call("refresh")
			_hide_item_hover()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and cursor_item_index >= 0:
			_cancel_cursor_item()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and is_menu_open():
			inventory_panel.hide()
			equipment_panel.hide()
			_hide_item_hover()
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_H:
			help_panel.visible = not help_panel.visible
			get_viewport().set_input_as_handled()

func _show_item_hover(item: Variant, equipped: Variant) -> void:
	hovered_item = item
	# Equipment already filters by matching slot; keep this guard in the HUD.
	hovered_equipped = equipped if item != null and equipped != null and equipped != item and item.get_slot() == equipped.get_slot() else null
	hover_ctrl_down = Input.is_key_pressed(KEY_CTRL)
	hover_alt_down = Input.is_key_pressed(KEY_ALT)
	if is_menu_open() and cursor_item_index < 0:
		item_compare_popup.call("display_item", item, hovered_equipped if hover_ctrl_down else null, hover_alt_down)

func _hide_item_hover() -> void:
	hovered_item = null
	hovered_equipped = null
	if is_instance_valid(item_compare_popup):
		item_compare_popup.hide()

func set_location(label_text: String) -> void:
	location_label.text = label_text
	location_time = 3.5
	location_label.modulate.a = 0.74

func set_prompt(label_text: String) -> void:
	prompt_label.text = label_text
	prompt_label.visible = not label_text.is_empty()

func set_carrying(active: bool) -> void:
	carrying_label.visible = active

func set_expression(name: String, duration: float = 0.0) -> void:
	if not EMOTIONS.has(name):
		name = "neutral"
	portrait.texture = EMOTIONS[name]
	expression_time = duration

func get_joystick_vector() -> Vector2:
	# PC-first Act 1 pass. Mobile UI will be a separate editor-authored scene.
	return Vector2.ZERO

func set_health(current: float, maximum: float) -> void:
	health_meter.max_value = maximum
	health_meter.value = current
	health_meter.visible = current < maximum

func is_menu_open() -> bool:
	return inventory_panel.visible or equipment_panel.visible or (is_instance_valid(collector_lens) and collector_lens.visible) or (is_instance_valid(collection_vault) and collection_vault.visible)

func set_stamina(current: float, maximum: float) -> void:
	stamina_meter.max_value = maximum
	stamina_meter.value = current
	stamina_meter.visible = current < maximum - 0.5

func set_dew(current: int, maximum: int) -> void:
	dew_label.text = "V  EMBER DEW  %d/%d" % [current, maximum]

func set_lock_target(target_name: String) -> void:
	lock_label.text = "L  TARGET  ·  " + target_name if not target_name.is_empty() else ""
	lock_label.visible = not target_name.is_empty()

func _open_collector_lens(item: GhostItemInstance) -> void:
	if item == null or item.get_slot() not in ["sword", "wand"] or not is_instance_valid(collector_lens):
		return
	# Clicking an inventory item can leave it on the cursor. Cancel the
	# temporary cursor state, not the actual item, before opening the modal.
	if cursor_item_index >= 0:
		_cancel_cursor_item()
	_hide_item_hover()
	collector_lens.call("open_item", item)

func _open_collection_vault(item: GhostItemInstance) -> void:
	if inventory_data == null:
		return
	if cursor_item_index >= 0:
		_cancel_cursor_item()
	_hide_item_hover()
	collection_vault.call("open_vault", inventory_data, item)
