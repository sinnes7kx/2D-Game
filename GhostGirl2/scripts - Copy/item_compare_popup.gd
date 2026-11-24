extends Control
## Content-aware height with independent scrollbars; never resizes the inventory.
const ITEM_MARKUP = preload("res://scripts/item_rich_text.gd")
const SINGLE_WIDTH: float = 328.0
const DOUBLE_WIDTH: float = 664.0

@onready var current_panel: PanelContainer = $Columns/Current
@onready var equipped_panel: PanelContainer = $Columns/Equipped
@onready var current_title: Label = $Columns/Current/Layout/Name
@onready var current_body: RichTextLabel = $Columns/Current/Layout/Body
@onready var equipped_title: Label = $Columns/Equipped/Layout/Name
@onready var equipped_body: RichTextLabel = $Columns/Equipped/Layout/Body

func _ready() -> void:
    current_body.bbcode_enabled = true
    equipped_body.bbcode_enabled = true
    mouse_filter = Control.MOUSE_FILTER_IGNORE

func display_item(item: Variant, equipped: Variant = null, advanced: bool = false) -> void:
    if item == null:
        hide()
        return
    var comparing: bool = equipped != null and equipped != item
    equipped_panel.visible = comparing
    current_title.text = item.display_name()
    current_title.add_theme_color_override("font_color", item.quality_color())
    current_body.text = ITEM_MARKUP.item_info(item, advanced)
    current_body.scroll_to_line(0)
    var lines: int = current_body.text.count("\n") + 2
    if comparing:
        equipped_title.text = "EQUIPPED · " + equipped.display_name()
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
    show()
    _place_popup()

func _process(_delta: float) -> void:
    if visible:
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
