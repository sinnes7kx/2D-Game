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
var info: RichTextLabel
var status: Label
var glow_button: CheckButton
var motion_button: CheckButton
var scythe_glow_choices: OptionButton
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
	var glow_row: HBoxContainer = HBoxContainer.new()
	glow_row.name = "ScytheGlowRowV211"
	layout.add_child(glow_row)
	var glow_caption: Label = Label.new()
	glow_caption.text = "SCYTHE AURA · VISUAL ONLY"
	glow_caption.add_theme_font_size_override("font_size", 12)
	glow_row.add_child(glow_caption)
	scythe_glow_choices = OptionButton.new()
	scythe_glow_choices.name = "ScytheGlowPreviewV211"
	scythe_glow_choices.tooltip_text = "Full-scythe aura is separate from the always-available curved blade highlights · previews are not saved"
	scythe_glow_choices.add_item("Rolled aura")
	for step in range(6):
		scythe_glow_choices.add_item("%d%% glow" % (step * 10))
	scythe_glow_choices.item_selected.connect(_select_scythe_glow)
	glow_row.add_child(scythe_glow_choices)
	glow_row.hide()
	var reset: Button = Button.new()
	reset.text = "Reset view"
	controls.add_child(reset)
	reset.pressed.connect(_reset_view)
	var copy: Button = Button.new()
	copy.text = "Copy look code"
	controls.add_child(copy)
	copy.pressed.connect(_copy_code)
	var copy_roll: Button = Button.new()
	copy_roll.text = "Copy roll"
	controls.add_child(copy_roll)
	copy_roll.pressed.connect(_copy_roll)
	# Standalone action row keeps the existing toolbar uncluttered.
	var card_row: HBoxContainer = HBoxContainer.new()
	layout.add_child(card_row)
	var card_button: Button = Button.new()
	card_button.text = "Copy collector card (offline)"
	card_row.add_child(card_button)
	card_button.pressed.connect(_copy_card)
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
	heading.add_theme_color_override("font_color", value.quality_color())
	var look: Dictionary = value.collector_appearance()
	info.text = ""
	if not look.is_empty():
		info.text = "[color=#dfc38e]MATERIAL  ·  %s[/color]\n[color=#c8b6db]PARTICLES  ·  %s[/color]\n\n" % [value.collector_material_label().to_upper(), ["Standard", "Unusual", "Enchanted", "Animated", "Celestial", "Ethereal", "Anomaly"][clampi(int(look.get("particle_tier", 0)), 0, 6)]]
	if (bool(model.call("is_modular")) or bool(model.call("has_painted_surface"))) and not look.is_empty():
		info.text += "[color=#bfc9dd]SURFACE  ·  %s[/color]\n\n" % preload("res://scripts/living_metal_v187.gd").LABELS[clampi(int(look.get("surface_mode", 0)), 0, 6)]
	info.text += MARKUP.item_info(value, true)
	info.scroll_to_line(0)
	glow_button.disabled = false
	motion_button.disabled = false
	scythe_glow_choices.get_parent().visible = value.weapon_style() == "scythe"
	scythe_glow_choices.select(0)
	glow_button.set_pressed_no_signal(true)
	motion_button.set_pressed_no_signal(false)
	model.set("glow_enabled", true)
	_reset_view()
	show()
	_position_model()
	status.text = "Drag to rotate  ·  Wheel to zoom  ·  Display-only motion" if bool(model.call("is_modular")) else "Original artwork + animated effects  ·  Drag to rotate  ·  Wheel to zoom"
	if value.weapon_style() == "scythe":
		status.text = "Curved blade highlights + rolled full-scythe aura %d%% · preview 0–50%% (not saved)" % (SCYTHE_GLOW.rolled_level(value) * 10)

func close_lens() -> void:
	hide()
	inspected = null
	model.call("set_item", null)

func _select_scythe_glow(index: int) -> void:
	if inspected == null or inspected.weapon_style() != "scythe":
		return
	var value: int = index - 1
	model.call("set_glow_preview_override", value)
	var actual: int = SCYTHE_GLOW.rolled_level(inspected)
	status.text = ("Blade highlights + rolled aura %d%%" % (actual * 10)) if value < 0 else ("Blade highlights + preview aura %d%% · not saved" % (value * 10))

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

func _copy_roll() -> void:
	if inspected == null:
		return
	var code: String = ROLL_CODE.share(inspected)
	if code.is_empty():
		status.text = "Roll Code unavailable for this item family"
		return
	DisplayServer.clipboard_set(code)
	status.text = "Genuine V1 roll copied · not verified ownership"

# Purely textual local collection snapshot; never edits item identity.
func _copy_card() -> void:
	if inspected == null:
		return
	var card: String = SHARE_CARD.compose(inspected)
	if card.is_empty():
		status.text = "Collector card unavailable"
		return
	DisplayServer.clipboard_set(card)
	status.text = "Offline collector card copied · ownership is not verified"
