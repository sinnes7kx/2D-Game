extends SceneTree
## v2.01: physical cave traversal with several solutions, persistent state,
## safe failed writes and no mutation to existing inventory items.
const CAVE = preload("res://scripts/moonlit_cave_boulder_v201.gd")
const BOW = preload("res://scripts/bow_palette_overlay_v139.gd")
const ROOM: PackedScene = preload("res://scenes/rooms/moonthorn_woods.tscn")
const CARRY: PackedScene = preload("res://scenes/carryable.tscn")

class FakeInventory extends Node:
    var collected_pickups: Dictionary = {}
    var writable: bool = true
    var writes: int = 0
    func has_collected(flag: String) -> bool:
        return bool(collected_pickups.get(flag, false))
    func save_game() -> bool:
        writes += 1
        return writable

func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var methods: Array[String] = ["frost_smash", "frost_hook", "patient_hook", "repeated_force", "rose_roots", "aerial_shot", "thermal_shock", "thrown_stone", "frost_crate"]
    for method in methods:
        var inventory: FakeInventory = FakeInventory.new()
        root.add_child(inventory)
        var instance: Node2D = ROOM.instantiate() as Node2D
        root.add_child(instance)
        var cave: Node = instance.get_node("Gameplay/V201WorldPuzzles/MoonlitCaveBoulder")
        var portal: Node2D = instance.get_node("Gameplay/Portals/MoonlitCavePath")
        var chest: Node2D = instance.get_node("Gameplay/TreasureChests/V201MoonlitCaveCache")
        cave.call("restore_from_inventory", inventory)
        if cave.collision_layer != 2 or not cave.is_in_group("breakable_cover") or portal.visible or chest.visible or portal.is_in_group("interactable"):
            _fail("Locked cave has a passable shortcut or visible reward")
            return
        if str(portal.get("destination")) != "briar_hollow":
            _fail("Cave does not connect to the existing hollow")
            return
        match method:
            "frost_smash":
                if not bool(cave.call("on_moonfall")):
                    _fail("Moonfall cannot frost the cave stone")
                    return
                cave.call("receive_damage", 10.0)
            "frost_hook":
                cave.call("on_moonfall")
                cave.call("on_hook_latched")
            "patient_hook":
                for i in range(3):
                    cave.call("on_hook_latched")
            "repeated_force":
                for i in range(3):
                    cave.call("receive_damage", 24.0)
            "rose_roots":
                cave.call("on_grasping_roses")
            "aerial_shot":
                cave.call("on_bow_hit", true, true)
            "thermal_shock":
                cave.call("on_elemental_arrow_hit", 2, 0, false, false)
                cave.call("on_elemental_arrow_hit", 1, 0, false, false)
            "thrown_stone", "frost_crate":
                if method == "frost_crate":
                    cave.call("on_moonfall")
                var thrown: RigidBody2D = CARRY.instantiate() as RigidBody2D
                root.add_child(thrown)
                thrown.set("thrown_timer", 1.0)
                thrown.linear_velocity = Vector2(520.0, 0.0)
                thrown.set("v201_previous_thrown_speed", 520.0)
                thrown.call("_on_body_impact", cave)
                thrown.call("_on_body_impact", cave) # A rebound must not trigger a second hit.
                if not bool(thrown.get("v201_cave_impact_delivered")):
                    _fail("Physical carried stone did not register cave contact")
                    return
                thrown.free()
        if not cave.opened or cave.collision_layer != 0 or cave.is_in_group("breakable_cover") or not portal.visible or not chest.visible or not portal.is_in_group("interactable"):
            _fail("Method did not physically open route and cache: " + method)
            return
        if not inventory.has_collected("v201_moonthorn_cave_cleared") or not inventory.has_collected("v201_moonthorn_cave_cleared_" + method):
            _fail("Solution method not persisted in existing flag dictionary: " + method)
            return
        if inventory.writes != 1:
            _fail("Cave opening wrote multiple times or not at all: " + method)
            return
        var save_copy: Dictionary = inventory.collected_pickups.duplicate(true)
        instance.free()
        var revisit: Node2D = ROOM.instantiate() as Node2D
        root.add_child(revisit)
        var cave_again: Node = revisit.get_node("Gameplay/V201WorldPuzzles/MoonlitCaveBoulder")
        var portal_again: Node2D = revisit.get_node("Gameplay/Portals/MoonlitCavePath")
        cave_again.call("restore_from_inventory", inventory)
        if not cave_again.opened or cave_again.collision_layer != 0 or not portal_again.visible or cave_again.is_in_group("hook_switch"):
            _fail("Revisiting respawned the boulder after a valid discovery")
            return
        if inventory.collected_pickups != save_copy:
            _fail("Room revisit changed the saved solution method")
            return
        revisit.free()
        inventory.free()

    # Failed save cannot silently remove collision or grant the secret chest.
    var blocked: FakeInventory = FakeInventory.new()
    blocked.writable = false
    root.add_child(blocked)
    var fail_room: Node2D = ROOM.instantiate() as Node2D
    root.add_child(fail_room)
    var fail_cave: Node = fail_room.get_node("Gameplay/V201WorldPuzzles/MoonlitCaveBoulder")
    fail_cave.call("restore_from_inventory", blocked)
    if bool(fail_cave.call("on_grasping_roses")) or fail_cave.opened or not blocked.collected_pickups.is_empty():
        _fail("Failed disk write opened a cave or left orphaned flags")
        return
    blocked.writable = true
    if not bool(fail_cave.call("on_grasping_roses")) or not fail_cave.opened:
        _fail("Cave cannot recover once save access returns")
        return
    fail_room.free()
    blocked.free()

    # All bow variants share one physically upright carry transform and pivot.
    for face in ["front", "back", "left", "right"]:
        var pose: Dictionary = BOW.idle_hold_pose(face)
        var degrees: float = float(pose["rotation_deg"])
        if not is_equal_approx(degrees, float(BOW.UPRIGHT_IDLE_ANGLES[face])):
            _fail("Bow idle pose angles drifted on " + face)
            return
        if absf(degrees) < 90.0 or bool(pose["flip_h"]) != (face == "left"):
            _fail("Upright orientation or mirror lost on " + face)
            return
        var attached: Vector2 = pose["position"] + (pose["source_handle"] as Vector2).rotated(deg_to_rad(degrees))
        if attached.distance_to(pose["hand"]) > 0.01:
            _fail("Corrected upright bow moved away from the hand on " + face)
            return

    print("v2.01 PASS: 9 creative cave solutions, physical route/cache, persistence/rollback and upright bow pivots")
    quit(0)

func _fail(message: String) -> void:
    push_error(message)
    quit(1)
