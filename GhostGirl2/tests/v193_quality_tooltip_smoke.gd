extends SceneTree
const POPUP = preload("res://scenes/item_compare_popup.tscn")
const ITEM = preload("res://scripts/item_rich_text.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var node: Control = POPUP.instantiate()
    root.add_child(node)
    var title: Label = node.get_node("Columns/Current/Layout/Name")
    var star: Button = node.get_node("Columns/Current/Layout/TitleRow/RareStar")
    var body: RichTextLabel = node.get_node("Columns/Current/Layout/Body")
    if title == null or star == null or body == null:
        _fail("Tooltip title, star or body is missing")
        return
    var template: GhostItemData = load("res://items/rosemirror_twinblade_v170.tres") as GhostItemData
    var item: GhostItemInstance = GhostItemGenerator.create(template, 193001, "set")
    node.call("display_item", item, null, true)
    var frame: StyleBoxFlat = node.get_node("Columns/Current").get_theme_stylebox("panel") as StyleBoxFlat
    if frame == null or not frame.border_color.is_equal_approx(item.quality_color()):
        _fail("Border does not match quality color")
        return
    if body.text.contains("—  ADVANCED  —"):
        _fail("Advanced header is still present")
        return
    if star.visible:
        _fail("Cosmetic star should not replace six-dot indicator")
        return
    node.call("set_pinned", true)
    var anchored: Vector2 = node.position
    node.call("_process", 0.016)
    if node.position != anchored:
        _fail("Pinned tooltip moved")
        return
    node.call("set_pinned", false)
    if bool(node.get("pinned")):
        _fail("Tooltip did not unpin")
        return
    node.free()
    print("PASS: quality border, clean advanced view, rare star gate, ALT pin")
    quit(0)

func _fail(message: String) -> void:
    push_error(message)
    quit(1)
