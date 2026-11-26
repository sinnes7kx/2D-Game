extends Control
## Collector's Lens: modal, read-only inspection. Never equips, rerolls,
## changes a save or creates a gameplay attack.
const MODEL = preload("res://scripts/collector_lens_model_v179.gd")
const ROLL_CODE = preload("res://scripts/collector_roll_code_v1931.gd")
const SCYTHE_GLOW = preload("res://scripts/scythe_glow_layer_v211.gd")
const MARKUP = preload("res://scripts/item_rich_text.gd")
const SHARE_CARD = preload("res://scripts/v209_collector_share_card.gd")
var model: Node2D
var stage: Control
var heading: Label
var anomaly_title: Label
var info: RichTextLabel
var status: Label
var glow_button: CheckButton
var motion_button: CheckButton
var options_menu: MenuButton
var advanced_info: bool = false
var scythe_glow_choices: OptionButton
var inspected: GhostItemInstance
var owned_inventory: Node = null

func bind_inventory(value: Node) -> void:
	owned_inventory = value
var angle: float = -0.35
var zoom: float = 1.0
var motion_time: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade: ColorRect = ColorRect.new()
	shade.color = Color(0.04, 0.025, 0.055, 0.92)
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var center: CenterContainer = CenterContainer.new()
	add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(760, 540)
	center.add_child(panel)
	var frame: StyleBoxFlat = StyleBoxFlat.new()
	frame.bg_color = Color("211b29")
	frame.border_color = Color("a08567")
	frame.set_border_width_all(1)
	frame.set_corner_radius_all(4)
	frame.shadow_color = Color(0.0, 0.0, 0.0, 0.65)
	frame.shadow_size = 12
	frame.content_margin_left = 18
	frame.content_margin_right = 18
	frame.content_margin_top = 16
	frame.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", frame)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	panel.add_child(layout)
	var eyebrow: Label = Label.new()
	eyebrow.text = "❦  COLLECTOR'S LENS"
	eyebrow.add_theme_color_override("font_color", Color("d5ad8c"))
	eyebrow.add_theme_font_size_override("font_size", 13)
	layout.add_child(eyebrow)
	heading = Label.new()
	heading.add_theme_font_size_override("font_size", 24)
	var header: HBoxContainer = HBoxContainer.new()
	layout.add_child(header)
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	header.add_child(heading)
	anomaly_title = Label.new()
	anomaly_title.text = "Anomalous"
	anomaly_title.add_theme_font_size_override("font_size", 22)
	anomaly_title.add_theme_color_override("font_color", Color("e8d0ac"))
	anomaly_title.add_theme_color_override("font_shadow_color", Color("63477d"))
	anomaly_title.add_theme_constant_override("shadow_outline_size", 2)
	header.add_child(anomaly_title)
	anomaly_title.hide()
	var columns: HBoxContainer = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(columns)
	var well: PanelContainer = PanelContainer.new()
	well.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var well_style: StyleBoxFlat = StyleBoxFlat.new()
	well_style.bg_color = Color("100e19")
	well_style.border_color = Color("51404b")
	well_style.set_border_width_all(1)
	well_style.set_corner_radius_all(6)
	well.add_theme_stylebox_override("panel", well_style)
	columns.add_child(well)
	stage = Control.new()
	stage.custom_minimum_size = Vector2(365, 350)
	stage.clip_contents = true
	stage.mouse_filter = Control.MOUSE_FILTER_STOP
	well.add_child(stage)
	model = MODEL.new()
	stage.add_child(model)
	stage.resized.connect(_position_model)
	stage.gui_input.connect(_stage_input)
	info = RichTextLabel.new()
	info.bbcode_enabled = true
	info.custom_minimum_size = Vector2(310, 350)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(info)
	var controls: HBoxContainer = HBoxContainer.new()
	controls.add_theme_constant_override("separation", 12)
	layout.add_child(controls)
	glow_button = CheckButton.new()
	glow_button.text = "Illumination"
	glow_button.button_pressed = true
	controls.add_child(glow_button)
	glow_button.toggled.connect(_toggle_glow)
	motion_button = CheckButton.new()
	motion_button.text = "Motion preview"
	controls.add_child(motion_button)
	motion_button.hide()
	var glow_row: HBoxContainer = HBoxContainer.new()
	glow_row.name = "ScytheGlowRowV211"
	layout.add_child(glow_row)
	var glow_caption: Label = Label.new()
	glow_caption.text = "SCYTHE AURA · SAVED STYLE"
	glow_caption.add_theme_font_size_override("font_size", 12)
	glow_row.add_child(glow_caption)
	scythe_glow_choices = OptionButton.new()
	scythe_glow_choices.name = "ScytheGlowPreviewV211"
	scythe_glow_choices.tooltip_text = "Choose a saved 0–70% full-scythe aura; Natural retains the original seed roll"
	scythe_glow_choices.add_item("Natural (seeded)")
	for step in range(8):
		scythe_glow_choices.add_item("%d%% glow" % (step * 10))
	scythe_glow_choices.item_selected.connect(_select_scythe_glow)
	glow_row.add_child(scythe_glow_choices)
	glow_row.hide()
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(spacer)
	options_menu = MenuButton.new()
	options_menu.text = "Options"
	var menu: PopupMenu = options_menu.get_popup()
	menu.add_check_item("Motion preview", 0)
	menu.add_item("Reset view", 1)
	menu.add_separator()
	menu.add_item("Copy look code", 2)
	menu.add_item("Copy roll", 3)
	menu.add_item("Copy collector card (offline)", 4)
	menu.id_pressed.connect(_on_option_selected)
	controls.add_child(options_menu)
	var close: Button = Button.new()
	close.text = "Close  ·  Esc"
	controls.add_child(close)
	close.pressed.connect(close_lens)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 12)
	status.add_theme_color_override("font_color", Color("b1a5ba"))
	layout.add_child(status)
	hide()

func open_item(value: GhostItemInstance) -> void:
	if value == null or value.definition == null:
		return
	inspected = value
	model.call("set_item", value)
	heading.text = value.display_name()
	var appearance: Dictionary = value.collector_appearance()
	var is_anomaly: bool = maxi(int(appearance.get("material", 0)), int(appearance.get("particle_tier", 0))) == 6
	anomaly_title.visible = is_anomaly
	anomaly_title.text = "Anomalous · Test" if ROLL_CODE.debug_active(value) else "Anomalous"
	heading.add_theme_color_override("font_color", value.quality_color())
	advanced_info = Input.is_key_pressed(KEY_ALT)
	_refresh_info()
	glow_button.disabled = false
	motion_button.disabled = false
	scythe_glow_choices.get_parent().visible = value.weapon_style() == "scythe"
	scythe_glow_choices.select(clampi(value.glow_level_override + 1, 0, 8))
	scythe_glow_choices.disabled = owned_inventory == null or not (owned_inventory.contents.has(value) or owned_inventory.vault.has(value))
	glow_button.set_pressed_no_signal(true)
	motion_button.set_pressed_no_signal(false)
	options_menu.get_popup().set_item_checked(options_menu.get_popup().get_item_index(0), false)
	model.set("glow_enabled", true)
	_reset_view()
	show()
	_position_model()
	status.text = "Drag to rotate · Wheel to zoom · Hold Alt for colors & roll"
	if value.weapon_style() == "scythe":
		status.text = "Curved blade highlights · full-scythe glow %d%% · Natural keeps the original seed" % (SCYTHE_GLOW.rolled_level(value) * 10)

func close_lens() -> void:
	hide()
	inspected = null
	model.call("set_item", null)

func _select_scythe_glow(index: int) -> void:
	if inspected == null or inspected.weapon_style() != "scythe" or owned_inventory == null:
		return
	# Only an exact owned instance in backpack or vault can be personalized.
	if not (owned_inventory.contents.has(inspected) or owned_inventory.vault.has(inspected)):
		return
	var value: int = clampi(index - 1, -1, 7)
	var previous: int = inspected.glow_level_override
	inspected.glow_level_override = value
	if not owned_inventory.save_game():
		inspected.glow_level_override = previous
		scythe_glow_choices.select(previous + 1)
		status.text = "Could not save glow · original appearance restored"
		return
	model.call("set_glow_preview_override", -1)
	model.queue_redraw()
	owned_inventory.contents_changed.emit()
	owned_inventory.equipment_changed.emit()
	var current: int = SCYTHE_GLOW.rolled_level(inspected)
	status.text = "Saved scythe aura · %d%% · original seed unchanged" % (current * 10)

func _toggle_glow(active: bool) -> void:
	model.set("glow_enabled", active)
	model.queue_redraw()

func _reset_view() -> void:
	angle = -0.35
	zoom = 1.0
	motion_time = 0.0
	_position_model()

func _position_model() -> void:
	if stage == null or model == null:
		return
	model.position = stage.size * 0.5
	var factor: float = minf(stage.size.x, stage.size.y) / 146.0 * zoom
	model.scale = Vector2.ONE * maxf(0.5, factor)
	model.rotation = angle

func _stage_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		angle += event.relative.x * 0.012
		_position_model()
		stage.accept_event()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			zoom = clampf(zoom * (1.12 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.89), 0.6, 2.5)
			_position_model()
			stage.accept_event()

func _process(delta: float) -> void:
	if not visible:
		return
	if anomaly_title.visible:
		var pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.0014)
		anomaly_title.modulate = Color(1.0, 0.90 + pulse * 0.10, 0.82 + pulse * 0.18, 0.78 + pulse * 0.22)
	var alt: bool = Input.is_key_pressed(KEY_ALT)
	if alt != advanced_info:
		advanced_info = alt
		_refresh_info()
	if not motion_button.button_pressed:
		return
	motion_time += delta
	model.rotation = angle + sin(motion_time * 2.0) * 0.75

func _copy_code() -> void:
	if inspected == null:
		return
	var identity: String = inspected.cosmetic_uid if not inspected.cosmetic_uid.is_empty() else "legacy-%d" % inspected.visual_seed()
	DisplayServer.clipboard_set("GG1:%s:%s" % [inspected.definition.item_id, identity])
	status.text = "Base appearance seed copied · saved custom choices and stats not included"

func _copy_roll() -> void:
	if inspected == null:
		return
	var code: String = ROLL_CODE.share(inspected)
	if code.is_empty():
		status.text = "Roll Code unavailable for this item family"
		return
	DisplayServer.clipboard_set(code)
	status.text = "Genuine V1 roll copied · not verified ownership"

# Copies a human-readable offline showcase, not an owned item or minted seed.
func _copy_card() -> void:
	if inspected == null:
		return
	var card: String = SHARE_CARD.compose(inspected)
	if card.is_empty():
		status.text = "Collector card unavailable"
		return
	DisplayServer.clipboard_set(card)
	status.text = "Offline collector card copied · ownership is not verified"

func _refresh_info() -> void:
	if inspected == null:
		return
	info.text = MARKUP.item_info(inspected, advanced_info)
	var impact: String = MARKUP.impact_text(inspected)
	if not impact.is_empty():
		info.text += "\n[right][color=%s]%s[/color][/right]" % [MARKUP.color_to_tag(MARKUP.impact_color(inspected)), MARKUP.escape(impact)]
	info.scroll_to_line(0)

func _on_option_selected(id: int) -> void:
	match id:
		0:
			motion_button.set_pressed_no_signal(not motion_button.button_pressed)
			var menu: PopupMenu = options_menu.get_popup()
			menu.set_item_checked(menu.get_item_index(0), motion_button.button_pressed)
			if not motion_button.button_pressed:
				_position_model()
		1: _reset_view()
		2: _copy_code()
		3: _copy_roll()
		4: _copy_card()
