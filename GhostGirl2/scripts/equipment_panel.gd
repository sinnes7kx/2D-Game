extends PanelContainer
signal item_hovered(item: Variant, equipped: Variant)
signal item_hover_cleared
## Six editor-authored equipment slots; sword and wand are mutually exclusive.
var inventory
@onready var slots: Control = $Layout/EquipmentSlots
@onready var summary: RichTextLabel = $Layout/Details
const SLOT_NAMES = ["dress", "wings", "trinket", "charm", "wand", "sword"]

func _display_icon(item: Variant) -> Texture2D:
    if item == null or item.definition == null or item.definition.icon == null:
        return null
    # Keep the authored icon intact in equipment slots. The mythic badge stays
    # in the details UI instead of swapping the slot icon for a flipped texture.
    return item.definition.icon


func _ready() -> void:
    visible = false
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
