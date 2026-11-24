@tool
extends Node2D
## A modest, reusable world lamp. Hook it or strike it with a Luminous arrow
## to reveal nearby existing v1.40 moonmarks. Does not create loot or damage.
@export_range(100.0, 500.0, 10.0) var reveal_reach: float = 310.0
@export_range(15.0, 80.0, 1.0) var trigger_radius: float = 41.0
@export var lantern_label: String = "Moonthread Waylight"
var glow_left: float = 0.0
var age: float = 0.0
var newly_revealed: int = 0

func _ready() -> void:
    if Engine.is_editor_hint():
        return
    add_to_group("hook_switch")
    add_to_group("v139_elemental_world")

func on_hook_latched() -> void:
    _illuminate()

func on_elemental_arrow_hit(element: int, _formation: int, _charged: bool, _airborne: bool) -> bool:
    if element != 3:
        return false
    _illuminate()
    return true

func _illuminate() -> void:
    if Engine.is_editor_hint():
        return
    glow_left = 2.2
    newly_revealed = 0
    for node in get_tree().get_nodes_in_group("v140_light_reveal"):
        if not is_instance_valid(node) or not (node is Node2D):
            continue
        if not node.has_method("reveal_from_light"):
            continue
        if global_position.distance_squared_to(node.global_position) > reveal_reach * reveal_reach:
            continue
        if bool(node.call("reveal_from_light", node.global_position)):
            newly_revealed += 1
    var root: Node = get_tree().current_scene
    if root != null and root.has_node("HUD"):
        var message: String = "MOONTHREAD REVEALS A SECRET" if newly_revealed > 0 else "MOONTHREAD GLOWS SOFTLY"
        root.get_node("HUD").call("show_pickup", message, Color("ddc8e5"))
    queue_redraw()

func _process(delta: float) -> void:
    age += delta
    if glow_left > 0.0:
        glow_left = maxf(0.0, glow_left - delta)
        queue_redraw()
    elif Engine.is_editor_hint():
        queue_redraw()

func _draw() -> void:
    # A slender metallic hanging lantern rather than a large spell circle.
    var ink: Color = Color("806b85")
    var light: Color = Color("dfc6e9")
    draw_line(Vector2(0, -45), Vector2(0, -28), ink, 2.0, true)
    draw_line(Vector2(-11, -26), Vector2(11, -26), ink, 2.0, true)
    draw_line(Vector2(-13, -26), Vector2(-9, 7), ink, 2.0, true)
    draw_line(Vector2(13, -26), Vector2(9, 7), ink, 2.0, true)
    draw_line(Vector2(-9, 7), Vector2(9, 7), ink, 2.0, true)
    var alpha: float = 0.17 + 0.06 * (0.5 + 0.5 * sin(age * 1.5))
    if glow_left > 0.0:
        alpha += 0.23 * minf(1.0, glow_left)
    draw_line(Vector2(0, -21), Vector2(0, 0), Color(light.r, light.g, light.b, alpha), 6.0, true)
    draw_line(Vector2(0, -21), Vector2(0, 0), Color(1.0, 0.94, 0.98, alpha * 0.70), 2.0, true)
    if Engine.is_editor_hint():
        draw_rect(Rect2(Vector2(-17, -49), Vector2(34, 61)), Color("bca4c4"), false, 1.0)
