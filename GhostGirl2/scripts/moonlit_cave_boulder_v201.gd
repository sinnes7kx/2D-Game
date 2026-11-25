@tool
extends StaticBody2D
## A physical, editor-placed cave obstruction with more than one answer:
## ice + impact, ordinary repeated force, patient rose-hook pulls,
## rose magic, or a difficult charged aerial shot. Uses existing inputs.
## The cave and secret cache remain open after a successful, saved discovery.
const IMPACT = preload("res://scripts/impact_spawner_v149.gd")
const COMPLETED_FLAG: String = "v201_moonlit_cave_open"
@export var portal_path: NodePath
@export var reward_chest_path: NodePath
@export var discovery_id: String = COMPLETED_FLAG
@export_range(35.0, 120.0) var trigger_radius: float = 78.0
@export var impact_required: float = 65.0
@export var hook_pulls_required: int = 3
var inventory: Node = null
var opened: bool = false
var ice_left: float = 0.0
var impact_progress: float = 0.0
var hook_pulls: int = 0
var dissolve: float = 0.0
var age: float = 0.0
var solution: String = ""

func _ready() -> void:
    if Engine.is_editor_hint():
        return
    add_to_group("v201_cave_blocker")
    _refresh_state()
    set_process(true)

func restore_from_inventory(saved_inventory: Node) -> void:
    inventory = saved_inventory
    opened = inventory != null and inventory.has_collected(discovery_id)
    _refresh_state()

func _refresh_state() -> void:
    if opened:
        collision_layer = 0
        set_deferred("collision_layer", 0)
        var blocker: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
        if blocker != null:
            blocker.set_deferred("disabled", true)
    else:
        collision_layer = 2
        var blocker: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
        if blocker != null:
            blocker.set_deferred("disabled", false)
    for name in ["hook_switch", "v135_frost_targets", "v139_elemental_world", "moon_archery_targets", "rose_bloom_relay"]:
        if opened:
            remove_from_group(name)
        else:
            add_to_group(name)
    if opened:
        remove_from_group("interactable")
    else:
        add_to_group("interactable")
    var portal: Node2D = get_node_or_null(portal_path) as Node2D
    if portal != null:
        portal.visible = opened
        if opened:
            portal.add_to_group("interactable")
        else:
            portal.remove_from_group("interactable")
    var cache: Node2D = get_node_or_null(reward_chest_path) as Node2D
    if cache != null:
        cache.visible = opened
        if opened and not bool(cache.get("opened")):
            cache.add_to_group("interactable")
        else:
            cache.remove_from_group("interactable")
    queue_redraw()

func inspect_text() -> String:
    if opened:
        return "AN OLD CAVE TRAIL OPENS BEYOND THE STONE"
    if ice_left > 0.0:
        return "THE BOULDER IS BRITTLE WITH FROST · TRY A FORCEFUL STRIKE"
    if hook_pulls > 0 or impact_progress > 0.0:
        return "CRACKS WIDEN IN THE STONE · KEEP EXPERIMENTING"
    return "A BOULDER BLOCKS THE MOONLIT HOLLOW · SOMETHING MIGHT MOVE IT"

func hook_prompt() -> String:
    return "" if opened else "F  TUG AT THE CRACKED BOULDER"

func on_hook_latched() -> void:
    if opened:
        return
    hook_pulls += 1
    if ice_left > 0.0:
        _complete("frost_hook")
    elif hook_pulls >= maxi(1, hook_pulls_required):
        _complete("patient_hook")
    else:
        _hint("THE STONE SHIFTS UNDER THE ROSE HOOK", Color("cbb3d7"))

func on_moonfall() -> bool:
    if opened:
        return false
    ice_left = 10.0
    _hint("FROST ENTERS THE FRACTURES IN THE STONE", Color("b9dbf5"))
    queue_redraw()
    return true

func on_elemental_arrow_hit(element: int, _formation: int, _charged: bool, _airborne: bool) -> bool:
    if opened:
        return false
    if element == 2:
        return on_moonfall()
    if element == 1 and ice_left > 0.0:
        return _complete("thermal_shock")
    return false

func on_grasping_roses() -> bool:
    return _complete("rose_roots") if not opened else false

func on_bow_hit(charged: bool, airborne: bool) -> bool:
    return _complete("aerial_shot") if charged and airborne and not opened else false

func receive_damage(amount: float, _origin: Vector2 = Vector2.ZERO) -> void:
    if opened or amount <= 0.0:
        return
    if ice_left > 0.0 and amount >= 8.0:
        _complete("frost_smash")
        return
    impact_progress += amount
    if impact_progress >= maxf(8.0, impact_required):
        _complete("repeated_force")
    else:
        _hint("THE ROCK RINGS HOLLOW · MORE FORCE MIGHT WORK", Color("d0b6aa"))
        queue_redraw()

func _inventory_or_world() -> Node:
    if inventory != null:
        return inventory
    var game: Node = get_tree().current_scene
    if game != null:
        inventory = game.get_node_or_null("Inventory")
    return inventory

func _complete(method: String) -> bool:
    if opened:
        return false
    var saved: Node = _inventory_or_world()
    if saved == null:
        _hint("THE STONE MOVES, BUT THE DISCOVERY CANNOT BE RECORDED", Color("ebbdba"))
        return false
    var flags: Dictionary = saved.get("collected_pickups") as Dictionary
    if flags.is_empty() and saved.get("collected_pickups") == null:
        return false
    # Commit discovery and its solution together, before dropping collision.
    var method_flag: String = discovery_id + "_" + method
    flags[discovery_id] = true
    flags[method_flag] = true
    if not bool(saved.call("save_game")):
        flags.erase(discovery_id)
        flags.erase(method_flag)
        _hint("THE DISCOVERY COULD NOT BE SAVED · TRY AGAIN", Color("ebbdba"))
        return false
    opened = true
    solution = method
    dissolve = 1.0
    _refresh_state()
    if is_inside_tree():
        IMPACT.burst(get_parent(), global_position, "stone", 1.15, Vector2.UP, discovery_id.hash())
        IMPACT.rumble(global_position, 5.8)
    _hint("THE MOONLIT CAVE OPENS · A HIDDEN PATH AND CACHE AWAIT", Color("dbc7eb"))
    return true

func _hint(message: String, color: Color) -> void:
    if not is_inside_tree():
        return
    var world: Node = get_tree().current_scene
    if world != null and world.has_node("HUD"):
        world.get_node("HUD").call("show_pickup", message, color)

func _process(delta: float) -> void:
    age += delta
    if ice_left > 0.0 and not opened:
        ice_left = maxf(0.0, ice_left - delta)
    if dissolve > 0.0:
        dissolve = maxf(0.0, dissolve - delta * 1.2)
    queue_redraw()

func _draw() -> void:
    # Original, quiet dark-fairytale cave-entrance line art. It belongs to
    # this editor-editable scene node; no existing backgrounds are recycled.
    var portal_dark: Color = Color("100f18")
    draw_circle(Vector2(0, 38), 118.0, Color(0.02, 0.02, 0.04, 0.24))
    draw_colored_polygon(PackedVector2Array([
        Vector2(-113, 33), Vector2(-109, -33), Vector2(-84, -101),
        Vector2(-49, -143), Vector2(0, -155), Vector2(55, -136),
        Vector2(90, -91), Vector2(108, -32), Vector2(113, 34)]), Color("393340"))
    draw_colored_polygon(PackedVector2Array([
        Vector2(-79, 26), Vector2(-77, -36), Vector2(-55, -89),
        Vector2(-20, -113), Vector2(23, -114), Vector2(58, -85),
        Vector2(78, -35), Vector2(82, 30)]), portal_dark)
    for step in range(3):
        var w: float = 96.0 + float(step) * 11.0
        draw_arc(Vector2(0, -34), w, PI * 1.10, PI * 1.90, 38, Color(0.59, 0.51, 0.64, 0.20 - step * 0.04), 2.5, true)
    draw_line(Vector2(-111, 34), Vector2(-84, -83), Color("746777"), 4.0, true)
    draw_line(Vector2(109, 34), Vector2(83, -85), Color("8b7587"), 3.1, true)
    draw_line(Vector2(-35, 31), Vector2(36, 31), Color("9c8394"), 2.0, true)
    if opened:
        draw_arc(Vector2(0, -42), 38.0, -PI * 0.85, PI * 0.85, 36, Color(0.75, 0.67, 0.88, 0.12 + 0.05 * sin(age * 1.7)), 1.6, true)
        for i in range(7):
            var point: Vector2 = Vector2(-73 + float(i) * 22.0, 38.0 + float(i % 2) * 4.0)
            draw_line(point, point + Vector2(8, 4), Color("867483"), 2.3, true)
        return
    # Readable physical stone blocks the opening until a genuine solution.
    var rock: Color = Color("6c6572") if ice_left <= 0.0 else Color("8ca2b3")
    var vertices: PackedVector2Array = PackedVector2Array([
        Vector2(-85, 27), Vector2(-76, -24), Vector2(-52, -58),
        Vector2(12, -71), Vector2(71, -42), Vector2(89, 6),
        Vector2(75, 51), Vector2(30, 63), Vector2(-47, 57)])
    draw_colored_polygon(vertices, rock)
    draw_polyline(PackedVector2Array([vertices[0], vertices[1], vertices[2], vertices[3], vertices[4], vertices[5], vertices[6], vertices[7]]), Color("baaabb"), 3.5, true)
    draw_line(Vector2(-45, -17), Vector2(-8, -29), Color("b4a7b9"), 3.0, true)
    draw_line(Vector2(-8, -29), Vector2(34, -18), Color("aba0b3"), 2.0, true)
    draw_line(Vector2(-12, -29), Vector2(-19, 3), Color("40343f"), 3.0, true)
    draw_line(Vector2(-19, 3), Vector2(12, 32), Color("40343f"), 2.8, true)
    draw_line(Vector2(12, 32), Vector2(42, 17), Color("40343f"), 2.3, true)
    if ice_left > 0.0:
        for i in range(7):
            var p: Vector2 = Vector2(-59.0 + float(i) * 19.0, -32.0 + float(i % 3) * 17.0)
            draw_line(p, p + Vector2(5, -8), Color(0.75, 0.91, 1.0, 0.52), 1.7, true)
    elif hook_pulls > 0 or impact_progress > 0.0:
        draw_line(Vector2(-19, 3), Vector2(-42, 28), Color("c9b3ba"), 2.4, true)
