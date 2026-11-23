@tool
extends Node2D
## A temporary ice crossing. Unfrozen water/withered bridge is blocked by
## an editable narrow collision shape; frost opens firm footing for seconds.
@export var trigger_radius: float = 63.0
@export var bridge_length: float = 190.0
@export var bridge_width: float = 65.0
@export var freeze_seconds: float = 8.0
var frozen_left: float = 0.0
var age: float = 0.0
var blocker: StaticBody2D = null
var shape_node: CollisionShape2D = null

func _ready() -> void:
    if not Engine.is_editor_hint():
        add_to_group("v139_elemental_world")
        add_to_group("v135_frost_targets")
    _ensure_collision()
    _update_collision()

func _ensure_collision() -> void:
    blocker = get_node_or_null("UnfrozenBarrier") as StaticBody2D
    if blocker == null:
        blocker = StaticBody2D.new()
        blocker.name = "UnfrozenBarrier"
        add_child(blocker)
    blocker.collision_layer = 2
    blocker.collision_mask = 0
    shape_node = blocker.get_node_or_null("CollisionShape2D") as CollisionShape2D
    if shape_node == null:
        shape_node = CollisionShape2D.new()
        shape_node.name = "CollisionShape2D"
        blocker.add_child(shape_node)
    if shape_node.shape == null or not (shape_node.shape is RectangleShape2D):
        shape_node.shape = RectangleShape2D.new()
    (shape_node.shape as RectangleShape2D).size = Vector2(bridge_length, bridge_width)

func _update_collision() -> void:
    if shape_node != null:
        shape_node.set_deferred("disabled", frozen_left > 0.0)

func on_elemental_arrow_hit(element: int, _formation: int, _charged: bool, _airborne: bool) -> bool:
    if element != 2:
        return false
    _freeze()
    return true

func on_moonfall() -> bool:
    _freeze()
    return true

func _freeze() -> void:
    frozen_left = freeze_seconds
    _update_collision()
    queue_redraw()

func _process(delta: float) -> void:
    age += delta
    if frozen_left > 0.0:
        frozen_left = maxf(0.0, frozen_left-delta)
        if frozen_left <= 0.0:
            # Don't suddenly close the bridge on top of Ghost Girl.
            var ghost: Node2D = get_tree().get_first_node_in_group("ghost_girl_player") as Node2D
            if ghost != null and global_position.distance_squared_to(ghost.global_position) < pow(bridge_length * 0.60, 2.0):
                frozen_left = 1.0
            _update_collision()
    queue_redraw()

func _draw() -> void:
    var rect: Rect2 = Rect2(-bridge_length*.5,-bridge_width*.5,bridge_length,bridge_width)
    if frozen_left > 0.0:
        var fade: float = minf(1.0,frozen_left)
        draw_rect(rect,Color(0.62,0.82,0.93,0.19*fade),true)
        for i in range(8):
            var x: float = -bridge_length*.45+float(i)*bridge_length*.13
            draw_line(Vector2(x,-bridge_width*.45),Vector2(x+10,bridge_width*.45),Color(0.91,0.97,1.0,0.43*fade),1.7,true)
        draw_arc(Vector2.ZERO,trigger_radius*.82,age,age+PI*1.4,30,Color(0.75,0.93,1.0,0.65*fade),2.0,true)
    else:
        draw_rect(rect,Color(0.07,0.1,0.15,0.14),true)
        draw_rect(rect,Color(0.46,0.65,0.74,0.44),false,1.5)
        draw_arc(Vector2.ZERO,trigger_radius,age*.2,age*.2+PI*1.3,32,Color(0.58,0.83,1.0,0.40),1.3,true)
