@tool
extends Node2D
## Reusable dry roots / timber. Fire propagates through nearby tagged objects,
## including existing v1.39 burnables and destructible wooden cover.
## Every node burns once, so chains always terminate; each has a saved state.
@export var flag_id: String = "v140_kindling"
@export var display_name: String = "Dry moonroot"
@export_range(15.0, 75.0, 1.0) var trigger_radius: float = 37.0
@export_range(80.0, 420.0, 1.0) var spread_radius: float = 235.0
@export_range(0.15, 2.0, 0.05) var ignition_delay: float = 0.70
@export var persistent: bool = true
var inventory: Node = null
var burning: bool = false
var burned: bool = false
var fire_age: float = 0.0
var spread_sent: bool = false
var age: float = 0.0
@export var fire_avoid_radius: float = 145.0

func _ready() -> void:
    if Engine.is_editor_hint():
        return
    add_to_group("v139_elemental_world")
    add_to_group("v140_flammable")

func restore_from_inventory(saved_inventory: Node) -> void:
    inventory = saved_inventory
    burned = persistent and inventory != null and inventory.has_collected(flag_id)
    burning = false
    spread_sent = burned
    remove_from_group("v146_live_fire")
    queue_redraw()

func on_elemental_arrow_hit(element: int, _formation: int, _charged: bool, _airborne: bool) -> bool:
    if element != 1 or burning or burned:
        return false
    ignite_from_environment()
    return true

func ignite_from_environment() -> void:
    if burning or burned or Engine.is_editor_hint():
        return
    burning = true
    fire_age = 0.0
    spread_sent = false
    add_to_group("v146_live_fire")
    get_tree().call_group("v145_world_response", "report_fire_ignition", global_position, fire_avoid_radius * 1.6)
    queue_redraw()

func _propagate() -> void:
    if spread_sent:
        return
    spread_sent = true
    var max_distance_squared: float = spread_radius * spread_radius
    for group_name in ["v140_flammable", "v139_flammable", "breakable_cover"]:
        for neighbor in get_tree().get_nodes_in_group(group_name):
            if neighbor == self or not is_instance_valid(neighbor) or not (neighbor is Node2D):
                continue
            if global_position.distance_squared_to(neighbor.global_position) > max_distance_squared:
                continue
            if neighbor.has_method("ignite_from_environment"):
                neighbor.call("ignite_from_environment")

func _persist_burn() -> void:
    if not persistent or inventory == null or flag_id.is_empty():
        return
    var flags: Dictionary = inventory.get("collected_pickups") as Dictionary
    flags[flag_id] = true
    inventory.call("save_game")

func _process(delta: float) -> void:
    age += delta
    if burning and not Engine.is_editor_hint():
        fire_age += delta
        if fire_age >= ignition_delay and not spread_sent:
            _propagate()
        if fire_age >= ignition_delay + 1.3:
            burning = false
            burned = true
            remove_from_group("v146_live_fire")
            _persist_burn()
    if Engine.is_editor_hint() or burning:
        queue_redraw()

func _draw() -> void:
    var color: Color = Color("56434d") if burned else Color("73616a")
    draw_line(Vector2(-20, 10), Vector2(8, -26), color, 7.0, true)
    draw_line(Vector2(2, 8), Vector2(27, -18), color, 5.0, true)
    draw_line(Vector2(-17, -2), Vector2(-26, -17), color, 3.0, true)
    if burning:
        for i in range(7):
            var phase: float = age * 5.5 + float(i) * 1.9
            var p: Vector2 = Vector2(sin(phase) * 19.0, -12.0 - float(i) * 8.0)
            var tint: Color = Color("ee9473") if i % 3 == 0 else Color("f6c0a1")
            draw_circle(p, 2.5 + float(i % 3), Color(tint.r, tint.g, tint.b, 0.45))
    elif Engine.is_editor_hint() and not burned:
        draw_arc(Vector2.ZERO, trigger_radius, 0, TAU, 28, Color("e6a07b"), 1.4, true)
