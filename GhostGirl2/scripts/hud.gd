extends CanvasLayer
const COLLECTOR_LENS = preload("res://scripts/collector_lens_v179.gd")
const COMBAT_JUICE = preload("res://scripts/combat_juice_v194.gd")
const SILK_V226 = preload("res://scripts/silk_motion_v226.gd")
const PERF_V230 = preload("res://scripts/performance_profiles_v230.gd")
var collector_lens: Control
const CODEX_PANEL = preload("res://scripts/codex_panel.gd")
var codex_panel: Control
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
var controls_window: PanelContainer
var inventory_panel: PanelContainer
var equipment_panel: PanelContainer
var item_compare_popup: Control
var hovered_item: Variant = null
var hovered_equipped: Variant = null
var hover_ctrl_down: bool = false
var hover_alt_down: bool = false
var tooltip_pinned: bool = false
var inventory_data: Node
var cursor_item_index: int = -1
var cursor_identity_v284: GhostItemInstance
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
var fps_readout: Label
var fps_refresh_left: float = 0.0
var fps_peak_ms: float = 0.0

# Both panel scenes attach their own controllers (editor-safe native layouts).
func _ready() -> void:
	inventory_panel = $Overlay/InventoryPanel as PanelContainer
	equipment_panel = $Overlay/EquipmentPanel as PanelContainer
	item_compare_popup = $Overlay/ItemComparePopup as Control
	inventory_panel.connect("item_hovered", Callable(self, "_show_item_hover"))
	inventory_panel.connect("item_hover_cleared", Callable(self, "_hide_item_hover"))
	equipment_panel.connect("item_hovered", Callable(self, "_show_item_hover"))
	equipment_panel.connect("item_hover_cleared", Callable(self, "_hide_item_hover"))
	equipment_panel.connect("edit_eyes_requested", Callable(self, "_open_eye_editor"))
	inventory_panel.connect("cursor_pick_requested", Callable(self, "_take_cursor_item"))
	inventory_panel.connect("cursor_place_requested", Callable(self, "_place_cursor_item"))
	inventory_panel.connect("cursor_cancel_requested", Callable(self, "_cancel_cursor_item"))
	inventory_panel.connect("cursor_drop_requested", Callable(self, "_drop_selected_item"))
	inventory_panel.connect("inspect_requested", Callable(self, "_open_collector_lens"))
	vigil_label.visible = false
	prompt_label.visible = false
	carrying_label.visible = false
	help_panel.visible = false
	_build_controls_window()
	pickup_toast.visible = false
	health_meter.visible = false
	stamina_meter.visible = false
	portrait.texture = EMOTIONS["neutral"]
	fps_readout = Label.new()
	fps_readout.name = "FPSReadoutV223"
	fps_readout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fps_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fps_readout.add_theme_font_size_override("font_size", 13)
	fps_readout.add_theme_color_override("font_color", Color("d8cddd"))
	fps_readout.add_theme_color_override("font_shadow_color", Color(0.05, 0.03, 0.07, 0.9))
	fps_readout.z_index = 110
	$Overlay.add_child(fps_readout)
	fps_readout.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	fps_readout.offset_left = -250.0
	fps_readout.offset_right = -12.0
	fps_readout.offset_top = 10.0
	fps_readout.offset_bottom = 80.0
	fps_readout.hide()
	collector_lens = COLLECTOR_LENS.new()
	collector_lens.name = "CollectorLensV179"
	$Overlay.add_child(collector_lens)
	collector_lens.z_index = 100
	collection_vault = COLLECTION_VAULT.new()
	collection_vault.name = "CollectionVaultV181"
	$Overlay.add_child(collection_vault)
	collection_vault.z_index = 90
	$Overlay.move_child(collector_lens, -1) # Inspector also owns GUI input above vault.
	collection_vault.connect("inspect_requested", Callable(self, "_open_collector_lens"))
	var stash_grid: Control = collection_vault.get("physical_grid")
	stash_grid.connect("item_hovered",Callable(self,"_show_item_hover"))
	stash_grid.connect("item_hover_cleared",Callable(self,"_hide_item_hover"))
	item_compare_popup.z_index=180
	inventory_panel.connect("vault_requested", Callable(self, "_open_collection_vault"))
	_build_codex_bar()

func _build_codex_bar() -> void:
	var bar: HBoxContainer = HBoxContainer.new()
	bar.name = "CodexUtilityBar"
	$Overlay.add_child(bar)
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	bar.offset_left = 20.0
	bar.offset_right = 224.0
	bar.offset_top = -54.0
	bar.offset_bottom = -12.0
	for entry in [["Menu","Menu","menu"],["Effects","Effects","effects"],["Codex","Discoveries","codex"],["Reliquary","Reliquary","reliquary"]]:
		var button: Button = Button.new()
		button.tooltip_text = str(entry[0])
		button.icon = load("res://assets/ui/codex/"+str(entry[2])+".svg") as Texture2D
		button.expand_icon = true
		button.custom_minimum_size = Vector2(44,40)
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_color_override("font_color",Color("d8b98f"))
		button.button_down.connect(_open_codex_section.bind(str(entry[1])))
		bar.add_child(button)
	codex_panel = CODEX_PANEL.new()
	codex_panel.name = "CodexPanel"
	$Overlay.add_child(codex_panel)
	codex_panel.z_index = 85

func _open_codex_section(section: String) -> void:
	if is_menu_open() or has_cursor_item():
		return
	_hide_item_hover()
	codex_panel.call("show_section",section)

func bind_inventory(value: Node) -> void:
	inventory_data = value
	if is_instance_valid(codex_panel):
		codex_panel.set("inventory",value)
	if inventory_panel.has_method("bind_inventory"):
		inventory_panel.call("bind_inventory", value)
	if equipment_panel.has_method("bind_inventory"):
		equipment_panel.call("bind_inventory", value)
	if collector_lens != null and collector_lens.has_method("bind_inventory"):
		collector_lens.call("bind_inventory", value)

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
	if is_instance_valid(fps_readout) and fps_readout.visible:
		fps_peak_ms = maxf(fps_peak_ms, delta * 1000.0)
		fps_refresh_left -= delta
		if fps_refresh_left <= 0.0:
			fps_refresh_left = 0.25
			var fps: float = float(Engine.get_frames_per_second())
			var texture_mib: float = float(Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)) / 1048576.0
			var draw_calls: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
			fps_readout.text = "%s  ·  %d FPS\nAvg %.1f ms  ·  Peak %.1f ms\nDraws: %d  ·  Tex: %.0f MiB" % [PERF_V230.label(), roundi(fps), 1000.0 / maxf(1.0, fps), fps_peak_ms, draw_calls, texture_mib]
			fps_peak_ms = 0.0
	# ALT locks the tooltip at its last position so its star and color
	# details can be inspected without the panel chasing the pointer.
	if item_compare_popup != null and item_compare_popup.visible:
		var alt_now: bool = Input.is_key_pressed(KEY_ALT)
		var ctrl_now: bool = Input.is_key_pressed(KEY_CTRL)
		if alt_now != tooltip_pinned:
			tooltip_pinned = alt_now
			item_compare_popup.call("set_pinned", tooltip_pinned)
			if not tooltip_pinned and hovered_item == null:
				item_compare_popup.hide()
		if hovered_item != null and (ctrl_now != hover_ctrl_down or alt_now != hover_alt_down):
			hover_ctrl_down = ctrl_now
			hover_alt_down = alt_now
			item_compare_popup.call("display_item", hovered_item, hovered_equipped if ctrl_now else null, alt_now)
	if drop_click_guard > 0:
		drop_click_guard -= 1
	if cursor_item_index >= 0 and inventory_data != null:
		cursor_item_index=inventory_data.contents.find(cursor_identity_v284)
		inventory_panel.call("set_cursor_item",cursor_item_index)
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
	cursor_identity_v284=item
	inventory_panel.call("set_cursor_item", index)
	held_icon.texture = item.definition.icon if item.definition != null else null
	held_treasure.show()
	_hide_item_hover()

func _cancel_cursor_item() -> void:
	cursor_item_index = -1
	cursor_identity_v284=null
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
	if inventory_data.place_or_swap_v284(cursor_item_index,page,col,row):
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

func _build_controls_window() -> void:
	controls_window=PanelContainer.new()
	controls_window.name="ControlsCodex"
	$Overlay.add_child(controls_window)
	controls_window.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	controls_window.offset_left=80.0
	controls_window.offset_right=-80.0
	controls_window.offset_top=48.0
	controls_window.offset_bottom=-48.0
	controls_window.z_index=105
	var panel: StyleBoxFlat=StyleBoxFlat.new()
	panel.bg_color=Color("211b25")
	panel.border_color=Color("9b7d65")
	panel.set_border_width_all(1)
	panel.set_content_margin_all(18.0)
	controls_window.add_theme_stylebox_override("panel",panel)
	var stack: VBoxContainer=VBoxContainer.new()
	controls_window.add_child(stack)
	var top: HBoxContainer=HBoxContainer.new()
	stack.add_child(top)
	var heading: Label=Label.new()
	heading.text="CONTROLS  /  Combat & Exploration"
	heading.add_theme_font_size_override("font_size",22)
	heading.add_theme_color_override("font_color",Color("e1c4a0"))
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	top.add_child(heading)
	var close: Button=Button.new()
	close.text="H / Esc   Close"
	close.pressed.connect(controls_window.hide)
	top.add_child(close)
	var scroll: ScrollContainer=ScrollContainer.new()
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	stack.add_child(scroll)
	var rows: VBoxContainer=VBoxContainer.new()
	rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.add_child(rows)
	var sections: Array=[
		["MOVEMENT", [["WASD / Arrows","Move independently of cursor"],["Mouse","Aim / face cursor"],["Shift","Sprint"],["Space","Backstep away from aim"],["C","Jump"],["L / Wheel","Target lock / cycle"]]],
		["COMBAT", [["Mouse1","Light attack"],["Mouse2","Heavy attack / hold charge where supported"],["F / Mouse4 / P / Mouse3","Parry · time incoming melee contact"],["Shift + Mouse2","Equipped unique skill"],["WASD + held charge","Backpedal or strafe at 45% walking speed"],["Space during grounded charge","Cancel supported charge into dodge"],["Mouse1 / Mouse2 (wand)","Normal / strong weapon shot"],["N","Heal"]]],
		["COMBOS", [["Mouse1 × 3","Light chain"],["Mouse1 × 2 → Mouse2","Heavy finisher"],["Backstep → Mouse2","Lunge in follow-up window"],["Successful parry → Attack","Counter window"],["Jump → Mouse2","Aerial attack"]]],
		["EXPLORATION", [["E","Interact / collect"],["Q / R","Pull item / grapple"],["G / Y","Drop / throw object"]]],
		["INVENTORY & CODEX", [["B / I / Tab","Inventory and equipment"],["P / Shift + Mouse2 (inventory)","Collector Lens"],["Ctrl / Alt (hover)","Compare / advanced details"],["Bottom-left icons","Menu · Effects · Codex · Reliquary"]]],
		["PRESENTATION", [["Shift + F2","FPS display"],["Shift + F3","Graphics profile"],["Shift + F4","Hair and dress motion"],["Shift + F5 / F6","Atmosphere / gothic filter"],["F8 / F9","Camera shake / impact sound"]]]
	]
	for section in sections:
		var label: Label=Label.new()
		label.text=str(section[0])
		label.add_theme_font_size_override("font_size",17)
		label.add_theme_color_override("font_color",Color("d9b990"))
		rows.add_child(label)
		for entry in section[1]:
			var line: HBoxContainer=HBoxContainer.new()
			rows.add_child(line)
			var key: Label=Label.new()
			key.text=str(entry[0])
			key.custom_minimum_size.x=238.0
			key.add_theme_color_override("font_color",Color("c4add8"))
			line.add_child(key)
			var description: Label=Label.new()
			description.text=str(entry[1])
			description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
			description.size_flags_horizontal=Control.SIZE_EXPAND_FILL
			line.add_child(description)
		rows.add_child(HSeparator.new())
	controls_window.hide()

func _input(event: InputEvent) -> void:
	if is_instance_valid(controls_window) and controls_window.visible:
		if event is InputEventKey and event.pressed and not event.echo and (event.physical_keycode==KEY_H or event.keycode==KEY_ESCAPE):
			controls_window.hide()
			get_viewport().set_input_as_handled()
		return
	if is_instance_valid(codex_panel) and codex_panel.visible:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			codex_panel.hide()
			get_viewport().set_input_as_handled()
		return
	if is_instance_valid(collector_lens) and collector_lens.visible:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			collector_lens.call("close_lens")
			get_viewport().set_input_as_handled()
		return
	if is_instance_valid(collection_vault) and collection_vault.visible:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			if bool(collection_vault.get("grid_mode")) and collection_vault.get("physical_grid").get("held")!=null:
				collection_vault.get("physical_grid").call("cancel")
			else:
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
			if candidate == null or candidate.definition == null:
				candidate = inventory_panel.call("selected_item_for_inspection") as GhostItemInstance
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
	if is_instance_valid(controls_window) and controls_window.visible:
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(codex_panel) and codex_panel.visible:
		get_viewport().set_input_as_handled()
		return
	# Session-only accessibility controls; saves and combat are unaffected.
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F5 and event.shift_pressed:
			var mode: String = preload("res://scripts/atmosphere_settings_v278.gd").cycle()
			show_pickup("WORLD ATMOSPHERE  ·  "+mode)
			get_viewport().set_input_as_handled()
			return
		if event.physical_keycode == KEY_F6 and event.shift_pressed:
			var grade: Node = get_parent().get_node_or_null("GothicGradeV277")
			if grade!=null and grade.has_method("cycle"):
				show_pickup("GOTHIC FILTER  ·  "+str(grade.call("cycle")))
				get_viewport().set_input_as_handled()
				return
		if event.physical_keycode == KEY_F3 and event.shift_pressed:
			PERF_V230.cycle()
			show_pickup("GRAPHICS PROFILE  ·  " + PERF_V230.label().to_upper())
			get_viewport().set_input_as_handled()
			return
		if event.physical_keycode == KEY_F4 and event.shift_pressed:
			SILK_V226.enabled = not SILK_V226.enabled
			show_pickup("HAIR / DRESS MOTION  ·  " + ("ON" if SILK_V226.enabled else "OFF"))
			get_viewport().set_input_as_handled()
			return
		if event.physical_keycode == KEY_F2 and event.shift_pressed:
			fps_readout.visible = not fps_readout.visible
			fps_refresh_left = 0.0
			fps_peak_ms = 0.0
			get_viewport().set_input_as_handled()
			return
		if event.physical_keycode == KEY_F8:
			var shake_next: float = 0.5 if COMBAT_JUICE.shake_level > 0.75 else (0.0 if COMBAT_JUICE.shake_level > 0.25 else 1.0)
			COMBAT_JUICE.set_shake_level(shake_next)
			show_pickup("CAMERA SHAKE  ·  %d%%" % roundi(shake_next * 100.0))
			get_viewport().set_input_as_handled()
			return
		if event.physical_keycode == KEY_F9:
			var sound_next: float = 0.5 if COMBAT_JUICE.sound_level > 0.75 else (0.0 if COMBAT_JUICE.sound_level > 0.25 else 1.0)
			COMBAT_JUICE.set_sound_level(sound_next)
			show_pickup("IMPACT SFX  ·  %d%%" % roundi(sound_next * 100.0))
			get_viewport().set_input_as_handled()
			return
	if is_instance_valid(collection_vault) and collection_vault.visible:
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(collector_lens) and collector_lens.visible:
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB or event.physical_keycode in [KEY_I, KEY_B]:
			# A single Diablo-like view contains equipment and backpack together.
			var opening: bool = not (inventory_panel.visible and equipment_panel.visible)
			if not opening:
				_cancel_cursor_item()
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
			if not is_menu_open() and not has_cursor_item():
				controls_window.show()
			get_viewport().set_input_as_handled()

func _show_item_hover(item: Variant, equipped: Variant) -> void:
	# Do not swap items while inspecting a pinned tooltip with the mouse.
	if tooltip_pinned and item_compare_popup != null and item_compare_popup.visible:
		return
	hovered_item = item
	hovered_equipped = equipped if item != null and equipped != null and equipped != item and item.get_slot() == equipped.get_slot() else null
	hover_ctrl_down = Input.is_key_pressed(KEY_CTRL)
	hover_alt_down = Input.is_key_pressed(KEY_ALT)
	if (is_menu_open() or (is_instance_valid(collection_vault) and collection_vault.visible)) and cursor_item_index < 0:
		tooltip_pinned = hover_alt_down
		item_compare_popup.call("set_pinned", tooltip_pinned)
		item_compare_popup.call("display_item", item, hovered_equipped if hover_ctrl_down else null, hover_alt_down)

func _hide_item_hover() -> void:
	hovered_item = null
	hovered_equipped = null
	if is_instance_valid(item_compare_popup):
		if tooltip_pinned and Input.is_key_pressed(KEY_ALT):
			return
		tooltip_pinned = false
		item_compare_popup.call("set_pinned", false)
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
	return (is_instance_valid(controls_window) and controls_window.visible) or (is_instance_valid(codex_panel) and codex_panel.visible) or inventory_panel.visible or equipment_panel.visible or (is_instance_valid(collector_lens) and collector_lens.visible) or (is_instance_valid(collection_vault) and collection_vault.visible)

func set_stamina(current: float, maximum: float) -> void:
	stamina_meter.max_value = maximum
	stamina_meter.value = current
	stamina_meter.visible = current < maximum - 0.5

func set_dew(current: int, maximum: int) -> void:
	dew_label.text = "V  EMBER DEW  %d/%d" % [current, maximum]

func set_lock_target(target_name: String) -> void:
	lock_label.text = "L  TARGET  ·  " + target_name if not target_name.is_empty() else ""
	lock_label.visible = not target_name.is_empty()

func _open_eye_editor(item: GhostItemInstance) -> void:
	if item == null or inventory_data == null:
		return
	if cursor_item_index >= 0:
		_cancel_cursor_item()
	inventory_panel.show()
	equipment_panel.show()
	inventory_panel.call("focus_eye_item", item)
	# The old pinned hover must not cover the newly opened eye controls.
	tooltip_pinned = false
	if is_instance_valid(item_compare_popup):
		item_compare_popup.call("set_pinned", false)
		item_compare_popup.hide()
	_hide_item_hover()

func _open_collector_lens(item: GhostItemInstance) -> void:
	if item == null or item.definition == null or not is_instance_valid(collector_lens):
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
	collection_vault.call("open_vault", inventory_data, item, -1, _town_stash_access)

func open_exhibition(slot: int, item: GhostItemInstance) -> void:
	if inventory_data == null:
		return
	_hide_item_hover()
	collection_vault.call("open_vault", inventory_data, item, slot, _town_stash_access)
	if item != null:
		_open_collector_lens(item)

func _town_stash_access() -> bool:
	var world: Node = get_parent()
	return world != null and world.has_method("can_access_town_stash") and bool(world.call("can_access_town_stash"))

func open_town_stash() -> void:
	if _town_stash_access():
		_open_collection_vault(null)

func close_town_stash() -> void:
	if is_instance_valid(collection_vault):
		collection_vault.hide()
