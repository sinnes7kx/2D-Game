@tool
extends Node2D
## A dim hidden sigil only made fully visible by luminous arrows.
## The revealed chest is a normal persistent treasure cache.
@export var flag_id: String = "v139_light_secret"
@export var trigger_radius: float = 46.0
@export var reward_chest_path: NodePath
var inventory: Node = null
var revealed: bool = false
var age: float = 0.0

func _ready() -> void:
    if not Engine.is_editor_hint():
        add_to_group("v139_elemental_world")
        add_to_group("v140_light_reveal")

func restore_from_inventory(saved_inventory: Node) -> void:
    inventory = saved_inventory
    revealed = inventory != null and inventory.has_collected(flag_id)
    _update_chest()

func reveal_from_light(world_point: Vector2) -> bool:
    if global_position.distance_squared_to(world_point) > 140.0 * 140.0:
        return false
    return on_elemental_arrow_hit(3, 0, false, false)

func on_elemental_arrow_hit(element: int, _formation: int, _charged: bool, _airborne: bool) -> bool:
    if element != 3 or revealed:
        return false
    revealed = true
    if inventory == null:
        var root: Node = get_tree().current_scene
        if root != null:
            inventory = root.get_node_or_null("Inventory")
    if inventory != null:
        var flags: Dictionary = inventory.get("collected_pickups") as Dictionary
        flags[flag_id] = true
        inventory.call("save_game")
    _update_chest()
    queue_redraw()
    return true

func _update_chest() -> void:
    if reward_chest_path.is_empty():
        return
    var chest: Node2D = get_node_or_null(reward_chest_path) as Node2D
    if chest != null:
        chest.visible = revealed
        if revealed and not bool(chest.get("opened")):
            chest.add_to_group("interactable")
        else:
            chest.remove_from_group("interactable")

func _process(delta: float) -> void:
    age += delta
    queue_redraw()

func _draw() -> void:
    var a: float = 0.20 if not revealed else 0.80
    var c: Color = Color("faefbe")
    draw_arc(Vector2.ZERO, trigger_radius, age*.18, age*.18+TAU*.9, 35, Color(c.r,c.g,c.b,a),2.3,true)
    for i in range(7):
        var p: Vector2 = Vector2.from_angle(float(i)*TAU/7+age*.25)*trigger_radius*.65
        draw_circle(p,2.0,Color(c.r,c.g,c.b,a*.8))
    if revealed:
        draw_circle(Vector2.ZERO,7.0,Color(1.0,0.93,0.72,0.66))
