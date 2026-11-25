extends SceneTree
## Regression for GOLD being referenced by item tooltip markup but undeclared.
## This preload must parse successfully in Godot on a clean main checkout.
const MARKUP = preload("res://scripts/item_rich_text.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    if MARKUP.GOLD != "#dfc38e":
        _fail("Missing or changed tooltip GOLD color constant")
        return
    var definition: GhostItemData = load("res://items/rosemirror_twinblade_v170.tres") as GhostItemData
    if definition == null:
        _fail("Could not load tooltip regression item fixture")
        return
    var item: GhostItemInstance = GhostItemGenerator.create(definition, 199001, "rare")
    var compact: String = MARKUP.item_info(item, false)
    var expanded: String = MARKUP.item_info(item, true)
    if not compact.contains("[color=%s]" % MARKUP.GOLD) or not expanded.contains("[color=%s]" % MARKUP.GOLD):
        _fail("Tooltip gold markup was not produced")
        return
    print("PASS: GOLD constant resolves in compact and extended item tooltips")
    quit(0)

func _fail(message: String) -> void:
    push_error(message)
    quit(1)
