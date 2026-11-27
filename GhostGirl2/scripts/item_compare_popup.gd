extends Control
## Content-aware height with independent scrollbars; never resizes the inventory.
const ITEM_MARKUP = preload("res://scripts/item_rich_text.gd")
const ANOMALY_TITLE = preload("res://scripts/anomalous_title_v252.gd")
const SINGLE_WIDTH: float = 328.0
const DOUBLE_WIDTH: float = 664.0
var pinned: bool = false
var impact_label: Label
var anomaly_label: Label
var _current_item: Variant = null
var _equipped_item: Variant = null

@onready var current_panel: PanelContainer = $Columns/Current
@onready var equipped_panel: PanelContainer = $Columns/Equipped
@onready var current_title: Label = $Columns/Current/Layout/TitleRow/Name
@onready var rare_star: Button = $Columns/Current/Layout/TitleRow/RareStar
@onready var current_body: RichTextLabel = $Columns/Current/Layout/Body
@onready var current_hint: Label = $Columns/Current/Layout/VisualHint
@onready var equipped_title: Label = $Columns/Equipped/Layout/Name
@onready var equipped_body: RichTextLabel = $Columns/Equipped/Layout/Body
@onready var equipped_hint: Label = $Columns/Equipped/Layout/VisualHint

func _ready() -> void:
    current_body.bbcode_enabled = true
    equipped_body.bbcode_enabled = true
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    rare_star.mouse_filter = Control.MOUSE_FILTER_IGNORE
    impact_label = Label.new()
    impact_label.add_theme_font_size_override("font_size", 11)
    impact_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    impact_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    current_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    current_title.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
    current_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    var title_row: Control = current_title.get_parent() as Control
    var layout: VBoxContainer = current_panel.get_node("Layout") as VBoxContainer
    title_row.add_child(impact_label)
    impact_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    current_title.reparent(layout, false)
    layout.move_child(current_title, title_row.get_index() + 1)
    current_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    anomaly_label = Label.new()
    anomaly_label.add_theme_font_size_override("font_size", 18)
    ANOMALY_TITLE.apply(anomaly_label, 3.0)
    anomaly_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    current_panel.get_node("Layout").add_child(anomaly_label)
    current_panel.get_node("Layout").move_child(anomaly_label, current_body.get_index())
    anomaly_label.hide()
    current_body.meta_hover_started.connect(_on_current_dot_hover)
    current_body.meta_hover_ended.connect(_on_current_dot_exit)
    equipped_body.meta_hover_started.connect(_on_equipped_dot_hover)
    equipped_body.meta_hover_ended.connect(_on_equipped_dot_exit)

func display_item(item: Variant, equipped: Variant = null, _advanced: bool = false) -> void:
    if item == null:
        hide()
        return
    _current_item = item
    _equipped_item = equipped
    current_hint.hide()
    equipped_hint.hide()
    var comparing: bool = equipped != null and equipped != item
    equipped_panel.visible = comparing
    current_title.text = item.display_name()
    _quality_border(current_panel, item)
    rare_star.hide()
    var look: Dictionary = item.collector_appearance()
    anomaly_label.visible = maxi(int(look.get("material", 0)), int(look.get("particle_tier", 0))) == 6
    ANOMALY_TITLE.apply(anomaly_label, Time.get_ticks_msec() * 0.001, item)
    anomaly_label.text = "Anomalous"
    anomaly_label.tooltip_text = "Test appearance — genuine roll unchanged" if preload("res://scripts/collector_roll_code_v1931.gd").debug_active(item) else ""
    impact_label.text = ITEM_MARKUP.impact_text(item)
    impact_label.visible = not impact_label.text.is_empty()
    impact_label.add_theme_color_override("font_color", ITEM_MARKUP.impact_color(item))
    current_title.add_theme_color_override("font_color", item.quality_color())
    # ALT pins the compact tooltip; detailed roll history lives in P/Inspect.
    current_body.text = ITEM_MARKUP.item_info(item, _advanced)
    current_body.scroll_to_line(0)
    var lines: int = current_body.text.count("\n") + 3 + (1 if anomaly_label.visible else 0)
    if comparing:
        equipped_title.text = "EQUIPPED · " + equipped.display_name()
        _quality_border(equipped_panel, equipped)
        equipped_title.add_theme_color_override("font_color", equipped.quality_color())
        equipped_body.text = ITEM_MARKUP.changes(item, equipped) + "\n\n" + ITEM_MARKUP.item_info(equipped, _advanced)
        equipped_body.scroll_to_line(0)
        lines = maxi(lines, equipped_body.text.count("\n") + 2)
    var screen: Vector2 = get_viewport_rect().size
    var allowed_height: float = maxf(220.0, screen.y - 24.0)
    var desired_height: float = minf(allowed_height, clampf(68.0 + lines * 22.0, 160.0, 550.0))
    var desired_width: float = DOUBLE_WIDTH if comparing else SINGLE_WIDTH
    desired_width = minf(desired_width, maxf(260.0, screen.x - 20.0))
    custom_minimum_size = Vector2.ZERO
    size = Vector2(desired_width, desired_height)
    var first_show: bool = not visible
    show()
    if first_show or not pinned:
        _place_popup()

func set_pinned(active: bool) -> void:
    pinned = active
    mouse_filter = Control.MOUSE_FILTER_STOP if pinned else Control.MOUSE_FILTER_IGNORE
    current_body.mouse_filter = Control.MOUSE_FILTER_STOP if pinned else Control.MOUSE_FILTER_IGNORE
    equipped_body.mouse_filter = Control.MOUSE_FILTER_STOP if pinned else Control.MOUSE_FILTER_IGNORE
    if not pinned:
        current_hint.hide()
        equipped_hint.hide()

func _display_dot_hint(meta: Variant, item: Variant, target: Label) -> void:
    if not pinned or item == null or target == null:
        return
    var message: String = ITEM_MARKUP.visual_dot_details(item, str(meta))
    if message.is_empty():
        target.hide()
        return
    target.text = message
    target.show()

func _on_current_dot_hover(meta: Variant) -> void:
    _display_dot_hint(meta, _current_item, current_hint)

func _on_equipped_dot_hover(meta: Variant) -> void:
    _display_dot_hint(meta, _equipped_item, equipped_hint)

func _on_current_dot_exit(_meta: Variant) -> void:
    current_hint.hide()

func _on_equipped_dot_exit(_meta: Variant) -> void:
    equipped_hint.hide()

func _quality_border(panel: PanelContainer, item: Variant) -> void:
    var source: StyleBox = panel.get_theme_stylebox("panel")
    if not (source is StyleBoxFlat):
        return
    var frame: StyleBoxFlat = source.duplicate(true) as StyleBoxFlat
    frame.border_color = item.quality_color()
    panel.add_theme_stylebox_override("panel", frame)

func _rare_details(item: Variant) -> String:
    var lines: Array[String] = ["RARE SEEDED APPEARANCE", "Cosmetic seed: %d" % item.cosmetic_seed_number()]
    lines.append("Style: " + item.collector_material_label())
    var fx: Dictionary = item.effect_rolls()
    lines.append("Aura: " + GhostWeaponFXLibrary.motif_name(int(fx.get("motif", 0))))
    lines.append("Trail: " + GhostWeaponFXLibrary.trail_name(int(fx.get("trail", 0))))
    lines.append("On hit: " + GhostWeaponFXLibrary.impact_name(item.get_slot(), int(fx.get("impact", 0))))
    if item.get_slot() == "wand":
        lines.append("Spell: " + GhostWeaponFXLibrary.spell_form_name(int(fx.get("form", 0))))
    if item.visual_signature() > 0:
        lines.append("Signature tier: %d" % item.genuine_visual_signature())
    return "\n".join(lines)

func _process(_delta: float) -> void:
    if visible and is_instance_valid(anomaly_label) and anomaly_label.visible:
        ANOMALY_TITLE.apply(anomaly_label, Time.get_ticks_msec() * 0.001, _current_item)
    if visible and not pinned:
        _place_popup()

func _place_popup() -> void:
    var screen: Vector2 = get_viewport_rect().size
    var mouse: Vector2 = get_viewport().get_mouse_position()
    var x: float = mouse.x + 25.0
    if x + size.x > screen.x - 10.0:
        x = mouse.x - size.x - 25.0
    # Anchor the hovered item's tooltip beside the pointer, not far above it.
    var y: float = mouse.y + 20.0
    if y + size.y > screen.y - 10.0:
        y = mouse.y - size.y - 20.0
    position = Vector2(clampf(x, 10.0, maxf(10.0, screen.x - size.x - 10.0)), clampf(y, 10.0, maxf(10.0, screen.y - size.y - 10.0)))
