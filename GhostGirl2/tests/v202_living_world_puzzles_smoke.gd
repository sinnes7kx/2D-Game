extends SceneTree
## Two outdoor puzzle styles and the original, quiet ambient wildlife.
const WOODS = preload("res://scenes/rooms/moonthorn_woods.tscn")
const HOLLOW = preload("res://scenes/rooms/briar_hollow.tscn")
const BROOK = preload("res://scenes/rooms/weeping_brook.tscn")
class WorldInventory extends Node:
    var collected_pickups: Dictionary = {}
    var writable: bool = true
    func has_collected(id: String) -> bool:
        return bool(collected_pickups.get(id, false))
    func save_game() -> bool:
        return writable

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    for scene in [WOODS, HOLLOW, BROOK]:
        var room: Node2D = scene.instantiate() as Node2D
        root.add_child(room)
        var wildlife: Node = room.get_node_or_null("Gameplay/V202Wildlife")
        if wildlife == null or wildlife.get_child_count() < 3:
            _fail("Wilderness area missing low-cost ambient critters")
            return
        for critter in wildlife.get_children():
            if critter is CollisionObject2D or critter.is_in_group("enemies"):
                _fail("Ambient critter has enemy AI/collision or new loot")
                return
        room.free()
    var inventory: WorldInventory = WorldInventory.new()
    root.add_child(inventory)
    for scene in [WOODS, HOLLOW]:
        var room: Node2D = scene.instantiate() as Node2D
        root.add_child(room)
        var path: String = "Gameplay/V202WorldPuzzles/MoonrootKnot" if scene == WOODS else "Gameplay/V202WorldPuzzles/ResonantBellstone"
        var device: Node = room.get_node(path)
        var chest: Node2D = device.get_node_or_null(device.get("reward_chest_path")) as Node2D
        device.call("restore_from_inventory", inventory)
        if device.call("is_resolved") or chest == null or chest.visible:
            _fail("Unsolved world puzzle leaked a prize")
            return
        if scene == WOODS:
            if not bool(device.call("on_elemental_arrow_hit", 1, 0, false, false)):
                _fail("Root knot cannot be resolved by fire")
                return
        else:
            if not bool(device.call("on_elemental_arrow_hit", 3, 0, false, false)):
                _fail("Bellstone cannot be resolved by light")
                return
        if not bool(device.call("is_resolved")) or not chest.visible:
            _fail("World puzzle reward did not unlock")
            return
        room.free()
    var flags: Dictionary = inventory.collected_pickups.duplicate(true)
    if flags.size() < 4:
        _fail("Puzzle completion and solution identity flags missing")
        return
    var rollback_room: Node2D = WOODS.instantiate() as Node2D
    root.add_child(rollback_room)
    var fail_inv: WorldInventory = WorldInventory.new()
    fail_inv.writable = false
    root.add_child(fail_inv)
    var failed: Node = rollback_room.get_node("Gameplay/V202WorldPuzzles/MoonrootKnot")
    failed.call("restore_from_inventory", fail_inv)
    if bool(failed.call("on_grasping_roses")) or failed.call("is_resolved") or not fail_inv.collected_pickups.is_empty():
        _fail("World puzzle failed to roll back a denied save")
        return
    rollback_room.free()
    fail_inv.free()
    inventory.free()
    print("v2.02 PASS: original non-combat critters, two multi-solution puzzle styles, persistent caches and rollback")
    quit(0)

func _fail(reason: String) -> void:
    push_error(reason)
    quit(1)
