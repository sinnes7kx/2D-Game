extends SceneTree
## Compact tooltip contract: six dots, no hit/roll labels, skill detail only on hover.
const POPUP = preload("res://scenes/item_compare_popup.tscn")
const MARKUP = preload("res://scripts/item_rich_text.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var template: GhostItemData = load("res://items/eclipse_twinblade_v170.tres") as GhostItemData
    assert(template != null)
    var item: GhostItemInstance = GhostItemGenerator.create(template, 196001, "unique")
    var compact: String = MARKUP.item_info(item, false)
    var detailed: String = MARKUP.item_info(item, true)
    assert(compact.contains("Grants Crimson Eclipse"))
    for value in [compact, detailed]:
        assert(not value.contains("UNIQUE SKILL"))
        assert(not value.contains("ROLL ·"))
        assert(not value.contains("Advancing blade dance"))
        assert(value.count("●") == 6)
        assert(value.ends_with("[/font_size]"))
    assert(MARKUP.impact_text(item).is_empty())
    assert(MARKUP.skill_hover_details(item, "visual:glow").is_empty())
    assert(MARKUP.skill_hover_details(item, "skill:granted").contains("Advancing blade dance"))
    assert(MARKUP.skill_hover_details(item, "skill:granted").contains("Shift + Mouse2"))
    var stats: Dictionary = item.all_stats()
    item.rainbow_skin = true
    assert(MARKUP.special_title(item) == "Prism")
    assert(MARKUP.cosmetic_indicator(item).size() == 6)
    assert(item.all_stats() == stats)
    item.rainbow_skin = false
    item.cosmetic_uid = "0000000000000000000000000005a282"
    assert(item.white_stop_mask() == 63 and item.has_six_white_glow())
    for ink in MARKUP.cosmetic_indicator(item):
        assert(ink == Color.WHITE)
    assert(item.collector_appearance()["six_white"])
    assert(item.all_stats() == stats)

    var popup: Control = POPUP.instantiate()
    root.add_child(popup)
    popup.call("display_item", item, null, false)
    var help: Label = popup.get_node("Columns/Current/Layout/VisualHint") as Label
    assert(not help.visible)
    popup.call("_on_current_dot_hover", "skill:granted")
    assert(not help.visible)
    popup.call("set_pinned", true)
    popup.call("_on_current_dot_hover", "visual:glow")
    assert(not help.visible)
    popup.call("_on_current_dot_hover", "skill:granted")
    assert(help.visible and help.text.contains("Crimson Eclipse"))
    popup.call("_on_current_dot_exit", "skill:granted")
    assert(not help.visible)
    popup.free()
    print("PASS: compact tooltip, Prism title, six dots and Alt-pinned skill hover")
    quit(0)
