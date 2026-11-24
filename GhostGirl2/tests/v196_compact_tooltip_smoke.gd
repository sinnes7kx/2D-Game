extends SceneTree
## Regression: compact default/ALT tooltip, truthful shader swatches, metadata hover.
const POPUP = preload("res://scenes/item_compare_popup.tscn")
const MARKUP = preload("res://scripts/item_rich_text.gd")
const SURFACE = preload("res://scripts/weapon_surface_v190.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var template: GhostItemData = load("res://items/moonveil_bow.tres") as GhostItemData
    if template == null:
        _fail("Missing Moonveil item fixture")
        return
    var item: GhostItemInstance = GhostItemGenerator.create(template, 196001, "set")
    var compact: String = MARKUP.item_info(item, false)
    var detailed: String = MARKUP.item_info(item, true)
    if compact.contains("VISUAL EFFECTS") or compact.contains("ROLL ·") or compact.contains("Mythic animation"):
        _fail("Default tooltip leaked advanced technical detail")
        return
    if compact != MARKUP.item_info(item, false) or not compact.contains("[url=visual:surface:0]") or not compact.contains("[url=visual:string:0]") or not compact.contains("[url=visual:glow:0]"):
        _fail("The three bow color channels must have distinct hoverable swatches")
        return
    if not compact.contains(MARKUP.FLAVOUR) or not compact.contains(template.description.strip_edges()):
        _fail("Description must be visible in a distinctive flavour color")
        return
    if not detailed.contains("ROLL ·") or not detailed.contains("VISUAL EFFECTS"):
        _fail("Full collector Inspect lost roll or visual information")
        return
    var shader_tint: Array[Color] = SURFACE.bow_pigment(item, item.collector_appearance())
    if MARKUP.visual_colors(item, "surface") != shader_tint:
        _fail("Limb dots do not match the actual shader tint ramp")
        return
    var hint: String = MARKUP.visual_dot_details(item, "visual:surface:1")
    if not hint.contains("BOW LIMB TINT") or not hint.contains("shader") or not hint.contains("#"):
        _fail("Limb dot does not explain mixing with original painted art")
        return
    if MARKUP.visual_dot_details(item, "visual:glow:99") != "":
        _fail("Invalid color dot index displayed metadata")
        return

    var popup: Control = POPUP.instantiate()
    root.add_child(popup)
    popup.call("display_item", item, null, true) # ALT must not expand the body.
    var body: RichTextLabel = popup.get_node("Columns/Current/Layout/Body") as RichTextLabel
    var help: Label = popup.get_node("Columns/Current/Layout/VisualHint") as Label
    if body.text != compact or help.visible:
        _fail("ALT tooltip must begin compact without unsolicited visual text")
        return
    popup.call("set_pinned", true)
    popup.call("_on_current_dot_hover", "visual:glow:0")
    if not help.visible or not help.text.contains("Aura:") or not help.text.contains("FX LIGHT"):
        _fail("Pinned metadata dot did not show the relevant effect descriptions")
        return
    popup.call("_on_current_dot_exit", "visual:glow:0")
    if help.visible:
        _fail("Visual help remained after hover ended")
        return
    popup.call("set_pinned", false)
    popup.call("_on_current_dot_hover", "visual:glow:0")
    if help.visible:
        _fail("Unpinned tooltip allowed detached visual help")
        return
    popup.free()
    print("v1.96 PASS: compact ALT tooltip, labelled large swatches, truthful bow shader tint, flavour styling, pinned dot hover")
    quit(0)

func _fail(message: String) -> void:
    push_error(message)
    quit(1)
