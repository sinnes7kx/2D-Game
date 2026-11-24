@tool
extends StaticBody2D
## Small waist-height barricade: blocks arrows/bolts, hookable and breakable.
const PHYSICAL_FEEL: Script = preload("res://scripts/impact_spawner_v149.gd")
## It returns on revisiting the moor; the optional chain rewards remain saved.
@export var display_name: String = "Withered barricade"
@export var durability: float = 22.0
@export var announce_break: bool = true # Disable repetitive HUD prompts for ordinary early-room props.
@export var blast_radius: float = 86.0
@export var blast_damage: float = 9.0
var health: float = 22.0
var broken: bool = false
var age: float = 0.0
var broken_age: float = 0.0
var burning: bool = false
var burn_age: float = 0.0
var fire_spread_sent: bool = false
@export var fire_avoid_radius: float = 175.0

func _ready() -> void:
    health = durability
    remove_from_group("v146_live_fire")
    if Engine.is_editor_hint():
        return
    collision_layer = 2
    collision_mask = 0
    add_to_group("hook_switch")
    add_to_group("breakable_cover")
    add_to_group("v140_flammable")

func hook_prompt() -> String:
    return "F  BREAK " + display_name.to_upper() if not broken else ""

func on_hook_latched() -> void:
    receive_damage(durability + 1.0)

func receive_damage(amount: float, _source: Vector2 = Vector2.ZERO) -> void:
    if broken or amount <= 0.0:
        return
    health -= amount
    if health <= 0.0:
        _break_cover()
    queue_redraw()

func ignite_from_environment() -> void:
    if broken or burning or Engine.is_editor_hint():
        return
    burning = true
    burn_age = 0.0
    fire_spread_sent = false
    add_to_group("v146_live_fire")
    get_tree().call_group("v145_world_response", "report_fire_ignition", global_position, fire_avoid_radius * 1.5)

func _spread_fire_once() -> void:
    if fire_spread_sent:
        return
    fire_spread_sent = true
    for group_name in ["v139_flammable", "v140_flammable"]:
        for neighbor in get_tree().get_nodes_in_group(group_name):
            if neighbor != self and is_instance_valid(neighbor) and neighbor is Node2D:
                if global_position.distance_squared_to(neighbor.global_position) < 150.0 * 150.0 and neighbor.has_method("ignite_from_environment"):
                    neighbor.call("ignite_from_environment")

func _break_cover() -> void:
    broken = true
    burning = false
    PHYSICAL_FEEL.burst(get_parent(), global_position, "wood", 1.45, Vector2.UP, roundi(global_position.x * 13.0))
    PHYSICAL_FEEL.rumble(global_position, 5.5)
    remove_from_group("v146_live_fire")
    get_tree().call_group("v145_world_response", "report_world_change", global_position, "shattered cover")
    collision_layer = 0
    set_deferred("collision_layer", 0)
    remove_from_group("hook_switch")
    # One physical collapse = at most one hit per creature.
    for candidate in get_tree().get_nodes_in_group("enemies"):
        if not is_instance_valid(candidate) or not candidate is Node2D or candidate.is_queued_for_deletion():
            continue
        var enemy: Node2D = candidate as Node2D
        if enemy.global_position.distance_squared_to(global_position) <= blast_radius * blast_radius and enemy.has_method("hit"):
            enemy.call("hit", blast_damage, 0.7)
    var world: Node = get_tree().current_scene
    if announce_break and world != null and world.has_node("HUD"):
        world.get_node("HUD").call("show_pickup", "COVER SPLINTERS · USE THE OPENING", Color("e7c7d8"))

func _process(delta: float) -> void:
    age += delta
    if burning and not broken:
        burn_age += delta
        if burn_age >= 0.55 and not fire_spread_sent:
            _spread_fire_once()
        if burn_age >= 1.30:
            burning = false
            receive_damage(durability + 1.0)
    if broken:
        broken_age += delta
        if broken_age > 1.2:
            queue_free()
    queue_redraw()

func _draw() -> void:
    var timber: Color = Color("56424d")
    if burning and not broken:
        for i in range(5):
            var p: Vector2 = Vector2(float(i - 2) * 16.0, -16.0 - float(i % 3) * 12.0)
            draw_circle(p + Vector2(sin(age * 4.0 + float(i)) * 4.0, 0.0), 5.0, Color(1.0, 0.42, 0.22, 0.35))
    if broken:
        for i in range(7):
            var p: Vector2 = Vector2(-44.0 + float(i) * 14.0, 15.0 + float(i % 3) * 7.0)
            draw_line(p, p + Vector2(13, -4), Color(0.69, 0.50, 0.62, maxf(0.0, 1.0 - broken_age / 1.2)), 3.0, true)
        return
    draw_circle(Vector2(0, 18), 58, Color(0.02, 0.02, 0.04, 0.27))
    for i in range(3):
        var y: float = -18.0 + float(i) * 15.0
        draw_line(Vector2(-55, y), Vector2(55, y + 5), timber, 11.0, true)
        draw_line(Vector2(-53, y - 3), Vector2(51, y + 2), Color("a18898"), 2.0, true)
    for x in [-39.0, 39.0]:
        draw_line(Vector2(x, -34), Vector2(x, 25), Color("3f343c"), 9.0, true)
    var p: float = 0.5 + 0.5 * sin(age * 1.8)
    draw_arc(Vector2.ZERO, 47.0, 0.0, TAU, 40, Color(0.84, 0.66, 0.80, 0.10 + p * 0.11), 1.5, true)
