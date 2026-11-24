extends Control
## Collector's Lens: modal, read-only inspection. Never equips, rerolls,
## changes a save or creates a gameplay attack.
const MODEL = preload("res://scripts/collector_lens_model_v179.gd")
const MARKUP = preload("res://scripts/item_rich_text.gd")
var model: Node2D
var stage: Control
var heading: Label
var info: RichTextLabel
var status: Label
var glow_button: CheckButton
var motion_button: CheckButton
var inspected: GhostItemInstance
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
	frame.border_color = Color("746077")
	frame.set_border_width_all(1)
	frame.set_corner_radius_all(8)
	frame.content_margin_left = 18
	frame.content_margin_right = 18
	frame.content_margin_top = 16
	frame.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", frame)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.add_theme_constant_override("separation", 10)
	panel.add_child(layout)
	var eyebrow: Label = Label.new()
	eyebrow.text = "COLLECTOR'S LENS"
	eyebrow.add_theme_color_override("font_color", Color("d5ad8c"))
	eyebrow.add_theme_font_size_override("font_size", 13)
	layout.add_child(eyebrow)
	heading = Label.new()
	heading.add_theme_font_size_override("font_size", 24)
	layout.add_child(heading)
	var columns: HBoxContainer = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(columns)
	var well: PanelContainer = PanelContainer.new()
	well.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var well_style: StyleBoxFlat = StyleBoxFlat.new()
	well_style.bg_color = Color("100e19")
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
	var reset: Button = Button.new()
	reset.text = "Reset view"
	controls.add_child(reset)
	reset.pressed.connect(_reset_view)
	var copy: Button = Button.new()
	copy.text = "Copy look code"
	controls.add_child(copy)
	copy.pressed.connect(_copy_code)
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
	if value == null or value.definition == null or value.get_slot() not in ["sword", "wand"]:
		return
	inspected = value
	model.call("set_item", value)
	heading.text = value.display_name()
	heading.add_theme_color_override("font_color", value.quality_color())
	var look: Dictionary = value.collector_appearance()
	info.text = "[color=#dfc38e]MATERIAL  ·  %s[/color]\n[color=#c8b6db]PARTICLES  ·  %s[/color]\n\n" % [value.collector_material_label().to_upper(), ["Standard", "Unusual", "Enchanted", "Animated", "Celestial", "Ethereal", "Anomaly"][clampi(int(look.get("particle_tier", 0)), 0, 6)]]
	info.text += MARKUP.item_info(value, true)
	info.scroll_to_line(0)
	glow_button.disabled = not bool(model.call("is_modular"))
	motion_button.disabled = glow_button.disabled
	glow_button.set_pressed_no_signal(true)
	motion_button.set_pressed_no_signal(false)
	model.set("glow_enabled", true)
	_reset_view()
	show()
	_position_model()
	status.text = "Drag to rotate  ·  Wheel to zoom  ·  Display-only motion" if not glow_button.disabled else "Base artwork preview  ·  This weapon is not yet modular"

func close_lens() -> void:
	hide()
	inspected = null
	model.call("set_item", null)

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
	if not visible or not motion_button.button_pressed:
		return
	motion_time += delta
	model.rotation = angle + sin(motion_time * 2.0) * 0.75

func _copy_code() -> void:
	if inspected == null:
		return
	var identity: String = inspected.cosmetic_uid if not inspected.cosmetic_uid.is_empty() else "legacy-%d" % inspected.visual_seed()
	DisplayServer.clipboard_set("GG1:%s:%s" % [inspected.definition.item_id, identity])
	status.text = "Appearance code copied  ·  no combat stats included"
