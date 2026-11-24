extends Control
## Content-aware height with independent scrollbars; never resizes the inventory.
const ITEM_MARKUP = preload("res://scripts/item_rich_text.gd")
const SINGLE_WIDTH: float = 328.0
const DOUBLE_WIDTH: float = 664.0
var pinned: bool = false

@onready var current_panel: PanelContainer = $Columns/Current
@onready var equipped_panel: PanelContainer = $Columns/Equipped
@onready var current_title: Label = $Columns/Current/Layout/TitleRow/Name
@onready var rare_star: Button = $Columns/Current/Layout/TitleRow/RareStar
@onready var current_body: RichTextLabel = $Columns/Current/Layout/Body
@onready var equipped_title: Label = $Columns/Equipped/Layout/Name
@onready var equipped_body: RichTextLabel = $Columns/Equipped/Layout/Body

func _ready() -> void:
    current_body.bbcode_enabled = true
    equipped_body.bbcode_enabled = true
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    rare_star.mouse_filter = Control.MOUSE_FILTER_STOP

func display_item(item: Variant, equipped: Variant = null, advanced: bool = false) -> void:
    if item == null:
        hide()
        return
    var comparing: bool = equipped != null and equipped != item
    equipped_panel.visible = comparing
    current_title.text = item.display_name()
    _quality_border(current_panel, item)
    rare_star.visible = item.has_method("has_rare_seeded_appearance") and bool(item.call("has_rare_seeded_appearance"))
    rare_star.tooltip_text = _rare_details(item) if rare_star.visible else ""
    current_title.add_theme_color_override("font_color", item.quality_color())
    current_body.text = ITEM_MARKUP.item_info(item, advanced)
    current_body.scroll_to_line(0)
    var lines: int = current_body.text.count("\n") + 2
    if comparing:
        equipped_title.text = "EQUIPPED · " + equipped.display_name()
        _quality_border(equipped_panel, equipped)
        equipped_title.add_theme_color_override("font_color", equipped.quality_color())
        equipped_body.text = ITEM_MARKUP.changes(item, equipped) + "\n\n" + ITEM_MARKUP.item_info(equipped, advanced)
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
