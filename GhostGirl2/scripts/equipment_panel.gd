extends PanelContainer
signal item_hovered(item: Variant, equipped: Variant)
signal item_hover_cleared
## Six editor-authored equipment slots; sword and wand are mutually exclusive.
var inventory
@onready var slots: Control = $Layout/EquipmentSlots
@onready var summary: RichTextLabel = $Layout/Details
const PREVIEW = preload("res://scripts/equipment_preview_v1924.gd")
const FX_SETTING = preload("res://scripts/fx_intensity_v1924.gd")
var live_preview: SubViewportContainer
var fx_value: Label
var fx_slider: HSlider
const SLOT_NAMES = ["dress", "wings", "trinket", "charm", "wand", "sword"]

func _display_icon(item: Variant) -> Texture2D:
    if item == null or item.definition == null or item.definition.icon == null:
        return null
    # Keep the authored icon intact in equipment slots. The mythic badge stays
    # in the details UI instead of swapping the slot icon for a flipped texture.
    return item.definition.icon


func _ready() -> void:
    visible = false
    _install_live_preview()
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
    var active: Array[String] = []
    for i in range(SLOT_NAMES.size()):
        var key: String = SLOT_NAMES[i]
        var button: Button = slots.get_node(SLOT_NAMES[i].capitalize()) as Button
        var item: Variant = inventory.get_equipped(key)
        button.icon = _display_icon(item) if item != null and item.definition != null else null
        button.text = key.to_upper() if item == null else ""
        button.tooltip_text = ""
        button.disabled = item == null
        button.modulate = Color.WHITE
        # Full item details use the HUD's cursor-following tooltip. Prevent a
        # second Godot-native button tooltip from overlapping it.
        var swatch: ColorRect = button.get_node_or_null("PaletteSwatch") as ColorRect
        if swatch != null:
            swatch.visible = item != null
            if item != null:
                swatch.color = item.palette_color()
        if item != null:
            active.append("%s: %s  ·  %s" % [key.capitalize(), item.display_name(), item.palette_name()])
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
    inventory.unequip(slot)

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

func _install_live_preview() -> void:
    var doll: TextureRect = slots.get_node("Doll")
    live_preview = PREVIEW.new()
    live_preview.name = "LiveEquipmentPreview"
    live_preview.position = doll.position
    live_preview.size = doll.size
    live_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
    for face in ["Front", "Right", "Back", "Left"]:
        direction.add_item(face)
    direction.tooltip_text = "View the actual equipped character from any direction"
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
    reset.tooltip_text = "Restore 100% effects intensity"
    reset.pressed.connect(func() -> void: fx_slider.value = 1.0)
    row.add_child(reset)

func _set_fx_intensity(value: float) -> void:
    FX_SETTING.set_intensity(value)
    fx_value.text = "%d%%" % roundi(FX_SETTING.intensity * 100.0)
