extends PanelContainer
signal item_hovered(item: Variant, equipped: Variant)
signal item_hover_cleared
signal edit_eyes_requested(item: GhostItemInstance)
signal slot_clicked_v285(slot: String)
## Eight equipment slots (legacy wings key remains head accessories); sword and wand are mutually exclusive.
var inventory
@onready var slots: Control = $Layout/EquipmentSlots
@onready var summary: RichTextLabel = $Layout/Details
const PREVIEW = preload("res://scripts/equipment_preview_v1924.gd")
const FX_SETTING = preload("res://scripts/fx_intensity_v1924.gd")
var live_preview: SubViewportContainer
var fx_value: Label
var fx_slider: HSlider
var eye_edit_button: Button
var stats_toggle: Button
const SLOT_NAMES = ["dress", "wings", "helm", "trinket", "charm", "wand", "sword", "companion"]

func _display_icon(item: Variant) -> Texture2D:
	if item == null or item.definition == null or item.definition.icon == null:
		return null
	# Keep the authored icon intact in equipment slots. The mythic badge stays
	# in the details UI instead of swapping the slot icon for a flipped texture.
	return item.definition.icon


func _ready() -> void:
	preload("res://scripts/gothic_ui_v273.gd").apply(self)
	var trim: Control = preload("res://scripts/gothic_frame_v241.gd").new()
	trim.name = "GothicEngraving"
	trim.top_level = true
	add_child(trim)
	trim.global_position = global_position
	trim.size = size
	resized.connect(func() -> void: trim.size = size)
	item_rect_changed.connect(func() -> void: trim.global_position = global_position)
	visible = false
	_install_live_preview()
	_install_stats_toggle()
	for i in range(SLOT_NAMES.size()):
		var button: Button = slots.get_node(SLOT_NAMES[i].capitalize()) as Button
		button.pressed.connect(_on_slot_pressed.bind(SLOT_NAMES[i]))
		button.mouse_entered.connect(_on_slot_hovered.bind(SLOT_NAMES[i]))
		button.mouse_exited.connect(_on_slot_hover_cleared)
		# A real enamel palette chip for equipped equipment, independent from rarity.
		var swatch: ColorRect = ColorRect.new()
		swatch.name = "PaletteSwatch"
		swatch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		swatch.anchor_left = 1.0
		swatch.anchor_right = 1.0
		swatch.anchor_top = 1.0
		swatch.anchor_bottom = 1.0
		swatch.offset_left = -17.0
		swatch.offset_right = -7.0
		swatch.offset_top = -17.0
		swatch.offset_bottom = -7.0
		swatch.visible = false
		button.add_child(swatch)

func bind_inventory(value: Node) -> void:
	inventory = value
	live_preview.call("bind_inventory", value)
	if not inventory.equipment_changed.is_connected(refresh):
		inventory.equipment_changed.connect(refresh)
	refresh()

func toggle() -> void:
	visible = not visible
	if visible:
		refresh()

func refresh() -> void:
	if inventory == null or not is_node_ready():
		return
	live_preview.call("refresh")
	if is_instance_valid(eye_edit_button):
		var eyes: GhostItemInstance = inventory.get_equipped("wings")
		eye_edit_button.visible = false
	var active: Array[String] = []
	for i in range(SLOT_NAMES.size()):
		var key: String = SLOT_NAMES[i]
		var button: Button = slots.get_node(SLOT_NAMES[i].capitalize()) as Button
		var item: Variant = inventory.get_equipped(key)
		button.icon = _display_icon(item) if item != null and item.definition != null else null
		button.text = ("HEAD ACCESSORY" if key == "wings" else ("FAMILIAR" if key=="companion" else key.to_upper())) if item == null else ""
		button.tooltip_text = ""
		button.disabled = false
		button.modulate = Color.WHITE
		# Full item details use the HUD's cursor-following tooltip. Prevent a
		# second Godot-native button tooltip from overlapping it.
		var swatch: ColorRect = button.get_node_or_null("PaletteSwatch") as ColorRect
		if swatch != null:
			swatch.visible = item != null
			if item != null:
				swatch.color = item.palette_color()
		if item != null:
			var label: String = "Head Accessory" if key == "wings" else ("Tiara / Diadem" if key == "helm" else key.capitalize())
			active.append("%s: %s  ·  %s" % [label, item.display_name(), item.palette_name()])
	var totals: Array[String] = []
	for stat in ["vitality_pct", "melee_power_pct", "spell_power_pct", "attack_speed_pct", "find_bonus_pct"]:
		var value: float = inventory.get_stat_total(stat)
		if absf(value) >= 0.05:
			totals.append("+%.1f%% %s" % [value, GhostPaletteLibrary.stat_label(stat)])
	summary.bbcode_enabled = true
	var lines: Array[String] = ["[font_size=15][color=#e6c59b]CHARACTER BONUSES[/color][/font_size]"]
	for bonus in totals:
		lines.append("[font_size=14][color=#c4b7e6]%s[/color][/font_size]" % bonus)
	if totals.is_empty():
		lines.append("[color=#998f9f]No bonuses yet[/color]")
	lines.append("\n[font_size=15][color=#e6c59b]EQUIPPED RELICS[/color][/font_size]")
	for relic in active:
		lines.append("[font_size=13]%s[/font_size]" % relic)
	if active.is_empty():
		lines.append("[color=#998f9f]No equipment worn[/color]")
	summary.text = "\n".join(lines)

func _on_slot_pressed(slot: String) -> void:
	slot_clicked_v285.emit(slot)

func _on_slot_hovered(slot: String) -> void:
	if inventory == null:
		return
	var item: Variant = inventory.get_equipped(slot)
	if item != null:
		item_hovered.emit(item, null)
	else:
		item_hover_cleared.emit()

func _on_slot_hover_cleared() -> void:
	item_hover_cleared.emit()

const SKIN_V246 = preload("res://scripts/rose_nocturne_skin_v246.gd")

func _install_live_preview() -> void:
	var doll: TextureRect = slots.get_node("Doll")
	live_preview = PREVIEW.new()
	live_preview.name = "LiveEquipmentPreview"
	live_preview.position = doll.position
	live_preview.size = doll.size
	live_preview.mouse_filter = Control.MOUSE_FILTER_STOP
	live_preview.tooltip_text = "Wheel to zoom · Drag to pan · Double-click to reset"
	slots.add_child(live_preview)
	slots.move_child(live_preview, doll.get_index())
	doll.hide()
	var layout: VBoxContainer = $Layout
	layout.add_theme_constant_override("separation", 7)
	var row: HBoxContainer = HBoxContainer.new()
	row.name = "PreviewControls"
	layout.add_child(row)
	layout.move_child(row, $Layout/FooterTitle.get_index())
	var direction: OptionButton = OptionButton.new()
	direction.name = "Facing"
	for face in ["Front", "Right", "Back", "Left", "Front-right", "Back-right", "Back-left", "Front-left"]:
		direction.add_item(face)
	direction.tooltip_text = "Eight headings; diagonal original-skin unarmed artwork when installed. Equipped weapons retain their validated cardinal poses."
	direction.item_selected.connect(func(i: int) -> void: live_preview.call("set_direction", i))
	row.add_child(direction)
	var fx_label: Label = Label.new()
	fx_label.text = "FX"
	fx_label.tooltip_text = "Held weapon glow and animated material intensity (session only)"
	row.add_child(fx_label)
	fx_slider = HSlider.new()
	fx_slider.name = "FXIntensity"
	fx_slider.min_value = 0.0
	fx_slider.max_value = 2.0
	fx_slider.step = 0.05
	fx_slider.value = FX_SETTING.intensity
	fx_slider.custom_minimum_size.x = 90
	fx_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fx_slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	fx_slider.tooltip_text = "0% hides adjustable light, 100% original strength, 200% stronger"
	row.add_child(fx_slider)
	fx_value = Label.new()
	fx_value.custom_minimum_size.x = 43
	fx_value.text = "%d%%" % roundi(FX_SETTING.intensity * 100.0)
	row.add_child(fx_value)
	fx_slider.value_changed.connect(_set_fx_intensity)
	var reset: Button = Button.new()
	reset.text = "Reset"
	reset.tooltip_text = "Restore 200% effects intensity"
	reset.pressed.connect(func() -> void: fx_slider.value = FX_SETTING.DEFAULT_INTENSITY)
	row.add_child(reset)
	var zoom_reset: Button = Button.new()
	zoom_reset.text = "1×"
	zoom_reset.tooltip_text = "Reset character preview zoom"
	zoom_reset.pressed.connect(func() -> void: live_preview.call("reset_preview_zoom"))
	row.add_child(zoom_reset)
	var skin_row: HBoxContainer = HBoxContainer.new()
	skin_row.name = "SkinControls"
	layout.add_child(skin_row)
	layout.move_child(skin_row, row.get_index() + 1)
	var skin_label: Label = Label.new()
	skin_label.text = "Skin"
	skin_row.add_child(skin_label)
	var skin_choice: OptionButton = OptionButton.new()
	skin_choice.name = "CharacterSkin"
	skin_choice.add_item("Original", SKIN_V246.ORIGINAL)
	skin_choice.add_item("Rose Nocturne", SKIN_V246.NOCTURNE)
	skin_choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skin_choice.set_item_disabled(1, not SKIN_V246.available())
	skin_choice.tooltip_text = "Rose Nocturne: alternate unarmed locomotion artwork. Original poses for equipped weapons and unsupported actions." if SKIN_V246.available() else "Install the optional Rose Nocturne atlas in assets/ghost/skins/ first."
	skin_choice.select(SKIN_V246.current())
	skin_choice.item_selected.connect(func(index: int) -> void:
		if not SKIN_V246.choose(index):
			skin_choice.select(SKIN_V246.current())
		live_preview.call("refresh")
	)
	skin_row.add_child(skin_choice)
	eye_edit_button = Button.new()
	eye_edit_button.name = "EditEyesV215"
	eye_edit_button.text = "Edit eyes"
	eye_edit_button.tooltip_text = "Open eye shape and color editor for equipped luminous eyes"
	eye_edit_button.visible = false
	eye_edit_button.pressed.connect(_edit_equipped_eyes)
	layout.add_child(eye_edit_button)
	layout.move_child(eye_edit_button, row.get_index() + 1)

func _edit_equipped_eyes() -> void:
	if inventory == null:
		return
	var eyes: GhostItemInstance = inventory.get_equipped("wings")
	if eyes != null and eyes.definition != null and str(eyes.definition.item_id) == "v202_luminous_eyes":
		edit_eyes_requested.emit(eyes)

func _set_fx_intensity(value: float) -> void:
	FX_SETTING.set_intensity(value)
	fx_value.text = "%d%%" % roundi(FX_SETTING.intensity * 100.0)

func _install_stats_toggle() -> void:
	var layout: VBoxContainer = $Layout
	var footer: Label = $Layout/FooterTitle
	footer.hide()
	stats_toggle = Button.new()
	stats_toggle.name = "EquipmentStatsToggle"
	stats_toggle.toggle_mode = true
	stats_toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
	stats_toggle.text = "▸ Character & equipment stats"
	layout.add_child(stats_toggle)
	layout.move_child(stats_toggle, summary.get_index())
	stats_toggle.toggled.connect(_set_stats_expanded)
	_set_stats_expanded(false)

func _set_stats_expanded(expanded: bool) -> void:
	summary.visible = expanded
	stats_toggle.text = ("▾" if expanded else "▸") + " Character & equipment stats"
