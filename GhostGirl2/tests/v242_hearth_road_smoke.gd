extends SceneTree
const TOWN = preload("res://scenes/rooms/lanternhaven.tscn")
const ROAD = preload("res://scenes/rooms/westwood_road.tscn")
func _initialize() -> void:
    call_deferred("_verify")

func _verify() -> void:
    var town: Node2D = TOWN.instantiate() as Node2D
    var road: Node2D = ROAD.instantiate() as Node2D
    # Inspect before entering tree; no enemies, saves, or player AI run.
    if town.get_node_or_null("Gameplay/Effects/GatheringHearth") == null or town.get_node_or_null("Collision/Fountain") == null:
        push_error("Hearth or preserved plaza collision missing")
        quit(1)
        return
    if town.get_node("Gameplay/Portals/westwood_road").get("destination") != "westwood_road" or road.get_node("Gameplay/Portals/lanternhaven").get("destination") != "lanternhaven":
        push_error("Westwood return route missing")
        quit(1)
        return
    for path in ["Gameplay/OathTree/Roots", "Gameplay/HearthBenchWest/SeatCollision", "Gameplay/HearthBenchEast/SeatCollision"]:
        if not town.get_node_or_null(path) is CollisionShape2D:
            push_error("Plaza landmark collision missing: " + path)
            quit(1)
            return
    if road.get_node_or_null("Gameplay/Effects/ForestMotes") == null:
        push_error("Forest ambience missing")
        quit(1)
        return
    for room in [town,road]:
        if room.get_node("Gameplay/BreakableContainers").get_child_count() != 6:
            push_error("Existing scenery props lost")
            quit(1)
            return
    town.free()
    road.free()
    print("v2.42 PASS: hearth, plaza collision, ambience, routes and scenery retained")
    quit(0)
