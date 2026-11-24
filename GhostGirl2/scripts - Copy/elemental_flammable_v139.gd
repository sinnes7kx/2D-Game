@tool
extends Node2D
## Fire spreads between authored objects (and nearby breakable cover) one
## ignition at a time. One damage application per object/enemy, no per-frame DPS.
@export var flag_id: String = "v139_burnable"
@export var display_name: String = "Dry thornwood"
@export var trigger_radius: float = 40.0
@export var spread_radius: float = 290.0
@export var spread_delay: float = 0.85
@export var reveal_chest_path: NodePath
var inventory: Node = null
var burning: bool = false
var burned: bool = false
var age: float = 0.0
var spread_done: bool = false
@export var fire_avoid_radius: float = 155.0

func _ready() -> void:
    if not Engine.is_editor_hint():
        add_to_group("v139_elemental_world")
        add_to_group("v139_flammable")

func restore_from_inventory(saved_inventory: Node) -> void:
    inventory = saved_inventory
    burned = inventory != null and inventory.has_collected(flag_id)
    burning = false
    spread_done = burned
    remove_from_group("v146_live_fire")
    _update_chest()
    queue_redraw()

func on_elemental_arrow_hit(element: int, _formation: int, _charged: bool, _airborne: bool) -> bool:
    if element != 1 or burned or burning:
        return false
    ignite_from_environment()
    return true

func ignite_from_environment() -> void:
    if burned or burning:
        return
    burning = true
    age = 0.0
    spread_done = false
    add_to_group("v146_live_fire")
    get_tree().call_group("v145_world_response", "report_fire_ignition", global_position, fire_avoid_radius * 1.6)
    queue_redraw()

func _mark_saved() -> void:
    if inventory == null:
        var root: Node = get_tree().current_scene
        if root != null:
            inventory = root.get_node_or_null("Inventory")
    if inventory != null:
        var flags: Dictionary = inventory.get("collected_pickups") as Dictionary
        flags[flag_id] = true
        inventory.call("save_game")

func _update_chest() -> void:
    if reveal_chest_path.is_empty():
        return
    var chest: Node2D = get_node_or_null(reveal_chest_path) as Node2D
    if chest == null:
        return
    chest.visible = burned
    if burned and not bool(chest.get("opened")):
        chest.add_to_group("interactable")
    else:
        chest.remove_from_group("interactable")

func _propagate() -> void:
    if spread_done:
        return
    spread_done = true
    # New v1.40 kindling and old v1.39 props share one reusable spread path.
    for group_name in ["v139_flammable", "v140_flammable", "breakable_cover"]:
        for neighbor in get_tree().get_nodes_in_group(group_name):
            if neighbor == self or not is_instance_valid(neighbor) or not (neighbor is Node2D):
                continue
            if global_position.distance_squared_to(neighbor.global_position) > spread_radius * spread_radius:
                continue
            if neighbor.has_method("ignite_from_environment"):
                neighbor.call("ignite_from_environment")
    for enemy in get_tree().get_nodes_in_group("enemies"):
        if is_instance_valid(enemy) and enemy is Node2D and global_position.distance_squared_to(enemy.global_position) <= 70.0 * 70.0 and enemy.has_method("hit"):
            enemy.call("hit", 7.0, 0.5)

func _process(delta: float) -> void:
    if Engine.is_editor_hint():
        return
    if burning:
        age += delta
        if age >= spread_delay and not spread_done:
            _propagate()
        if age >= spread_delay + 1.3:
            burning = false
            burned = true
            remove_from_group("v146_live_fire")
            _mark_saved()
            _update_chest()
    queue_redraw()

func _draw() -> void:
    var tone: Color = Color("594b58") if burned else Color("8a6266")
    for i in range(5):
        var dx: float = float(i-2) * 14.0
        draw_line(Vector2(dx-20,11), Vector2(dx+12,-10.0-float(i%2)*9.0), tone, 6.0, true)
    if burning:
        var t: float = age * 7.0
        for i in range(9):
            var off: Vector2 = Vector2(sin(t+float(i)*2.0)*21.0, -18.0-float(i)*6.0)
            draw_circle(off, 4.0 + float(i%3), Color(1.0,0.35+float(i%3)*0.12,0.13,0.52))
    elif not burned:
        draw_arc(Vector2.ZERO, trigger_radius, 0, TAU, 28, Color(0.92,0.54,0.42,0.28), 1.6, true)
