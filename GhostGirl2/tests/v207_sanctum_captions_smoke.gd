extends SceneTree
## v2.07 read-only Sanctum labels and display illumination; synthetic inventory.
## Does not access user:// files or alter actual item instances.
const INV = preload("res://scripts/inventory.gd")
const EXHIBITION = preload("res://scripts/sanctum_exhibition_v182.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var inv: Node = INV.new()
    var definition: GhostItemData = load("res://items/rosemirror_twinblade_v170.tres") as GhostItemData
    if definition == null:
        _fail("Missing exhibition fixture item")
        return
    var item: GhostItemInstance = GhostItemGenerator.create(definition, 207042, "rare")
    item.collector_favorite = true
    item.collector_locked = true
    item.origin_room = "moonwake_crypt"
    item.apply_cosmetic_uid("0123456789abcdef0123456789abcdef")
    item.gradient_version = 2
    inv.vault.append(item)
    if not inv.set_exhibition(item, 0, false):
        _fail("Cannot assign collector item to exhibition")
        return
    var original: Dictionary = inv._serialize_item(item, Vector2i(-1, -1))
    var room: Node2D = (load("res://scenes/rooms/sanctum.tscn") as PackedScene).instantiate()
    root.add_child(room)
    var displays: Node = room.get_node("Gameplay/CollectionExhibition")
    if displays.get_child_count() != 6:
        _fail("Sanctum lost its six pedestals")
        return
    for stand in displays.get_children():
        stand.call("bind_inventory", inv)
    var stand: Node = displays.get_child(0)
    var title: Label = stand.get("caption") as Label
    var source: Label = stand.get("provenance") as Label
    var model: Node2D = stand.get("model") as Node2D
    if title == null or source == null or model == null:
        _fail("Display metadata/visual nodes missing")
        return
    if not title.text.contains(item.display_name()) or title.text.contains("Empty display"):
        _fail("Caption does not use the actual quality-aware item name")
        return
    if item.origin_label().is_empty() or not source.text.contains(item.origin_label()) or not source.text.contains(item.collector_material_label()):
        _fail("Discovery location and material not visible")
        return
    if model.get("item") == item or model.get("item") == null:
        _fail("Display must render a separate read-only snapshot")
        return
    if inv._serialize_item(item, Vector2i(-1, -1)) != original:
        _fail("Refreshing the exhibition changed the owned item")
        return
    if not (stand as CanvasItem).is_in_group("v182_exhibition"):
        _fail("Pedestal lost interactive inspection group")
        return
    if not inv.vault_withdraw(0, false):
        _fail("Synthetic withdrawal failed")
        return
    if not title.text.contains("Empty display") or not source.text.contains("Awaiting") or model.get("item") != null:
        _fail("Removing a displayed item left stale metadata or preview")
        return
    if item.item_seed != 207042 or item.exhibition_slot != -1 or not item.collector_favorite or not item.collector_locked:
        _fail("Withdrawal changed seed, favorite, lock or display state")
        return
    if not EXHIBITION.display_caption(null, 5).contains("06") or not EXHIBITION.display_provenance(null).contains("Awaiting"):
        _fail("Empty display presentation is not stable")
        return
    room.free()
    inv.free()
    print("v2.07 PASS: real item name, region, material, read-only display, empty state and collection fidelity")
    quit(0)

func _fail(message: String) -> void:
    push_error(message)
    quit(1)
