extends SceneTree
## Legitimate three-arrow perfect score: misses are not silently forgiven.
const ROOM = preload("res://scenes/rooms/lanternhaven.tscn")
class RangeInventory extends Node:
    var collected_pickups: Dictionary = {}
    var writable: bool = true
    var writes: int = 0
    var bow: GhostItemInstance = null
    func has_collected(id: String) -> bool:
        return bool(collected_pickups.get(id, false))
    func get_equipped(slot: String) -> GhostItemInstance:
        return bow if slot == "sword" else null
    func save_game() -> bool:
        writes += 1
        return writable

func _initialize() -> void:
    call_deferred("_verify")

func _run_shots(range_node: Node, include_miss: bool) -> bool:
    range_node.call("interact")
    var origin: Vector2 = (range_node as Node2D).global_position
    if include_miss:
        range_node.call("on_player_arrow_launched", origin)
    for i in range(3):
        range_node.call("on_player_arrow_launched", origin)
        var vane: Node = range_node.get_node("Vane%02d" % (i + 1))
        if not bool(vane.call("on_elemental_arrow_hit", 0, 0, i != 0, i == 2)):
            return false
    return true

func _verify() -> void:
    var equipped: GhostItemInstance = GhostItemGenerator.create(load("res://items/thornrose_bow.tres") as GhostItemData, 202222, "rare")
    var inv: RangeInventory = RangeInventory.new()
    inv.bow = equipped
    root.add_child(inv)
    var room: Node2D = ROOM.instantiate() as Node2D
    root.add_child(room)
    var trial: Node = room.get_node("Gameplay/V202Range/FletcherRange")
    var chest: Node2D = room.get_node("Gameplay/TreasureChests/FletcherPerfectChest")
    trial.call("restore_from_inventory", inv)
    if chest.visible or chest.is_in_group("interactable") or inv.has_collected("v202_fletcher_perfect"):
        _fail("Unwon rare fletcher bow is accessible")
        return
    if not _run_shots(trial, false) or int(trial.get("score")) != 300 or not inv.has_collected("v202_fletcher_perfect"):
        _fail("A real three-shot 300/300 perfect run did not unlock reward")
        return
    if inv.writes != 1 or not chest.visible or not chest.is_in_group("interactable"):
        _fail("Perfect reward did not persist exactly once")
        return
    if str((chest.get("loot_data") as GhostItemData).item_id) != "v202_fletcher_moonflight_bow" or str(chest.get("guaranteed_quality")) != "rare":
        _fail("Prize is not the designated fixed rare bow")
        return
    room.free()
    var returned: Node2D = ROOM.instantiate() as Node2D
    root.add_child(returned)
    var replay: Node = returned.get_node("Gameplay/V202Range/FletcherRange")
    replay.call("restore_from_inventory", inv)
    if not bool(replay.get("completed")) or not returned.get_node("Gameplay/TreasureChests/FletcherPerfectChest").visible:
        _fail("Revisited town hid an already earned fletcher bow")
        return
    returned.free()
    var miss_room: Node2D = ROOM.instantiate() as Node2D
    root.add_child(miss_room)
    var miss_inv: RangeInventory = RangeInventory.new()
    miss_inv.bow = equipped
    root.add_child(miss_inv)
    var miss_trial: Node = miss_room.get_node("Gameplay/V202Range/FletcherRange")
    miss_trial.call("restore_from_inventory", miss_inv)
    if not _run_shots(miss_trial, true) or int(miss_trial.get("score")) >= 300 or miss_inv.has_collected("v202_fletcher_perfect"):
        _fail("A missed shot incorrectly earned a perfect prize")
        return
    miss_room.free()
    miss_inv.free()
    var blocked_room: Node2D = ROOM.instantiate() as Node2D
    root.add_child(blocked_room)
    var blocked: RangeInventory = RangeInventory.new()
    blocked.bow = equipped
    blocked.writable = false
    root.add_child(blocked)
    var blocked_trial: Node = blocked_room.get_node("Gameplay/V202Range/FletcherRange")
    blocked_trial.call("restore_from_inventory", blocked)
    if not _run_shots(blocked_trial, false) or blocked.has_collected("v202_fletcher_perfect") or blocked_trial.get("completed"):
        _fail("Blocked disk write granted an unpersisted perfect prize")
        return
    blocked_room.free()
    blocked.free()
    inv.free()
    print("v2.02 PASS: authentic 300/300 range, miss penalty, once-only rare bow, revisit and failed-save rollback")
    quit(0)

func _fail(reason: String) -> void:
    push_error(reason)
    quit(1)
