@tool
extends Node2D
## A physically blocking side-passage shutter. The paired signal is the
## authority for saving and unlocking; there is no independent gate loot roll.
@export var width: float = 138.0
@export var depth: float = 38.0
@export var label: String = "Ashglass shutter"
var opened: bool = false
var blocker: StaticBody2D = null
var collider: CollisionShape2D = null

func _ready() -> void:
    _ensure_blocker()
    _sync_collision()

func _ensure_blocker() -> void:
    blocker = get_node_or_null("Barrier") as StaticBody2D
    if blocker == null:
        blocker = StaticBody2D.new()
        blocker.name = "Barrier"
        add_child(blocker)
    blocker.collision_layer = 2
    blocker.collision_mask = 0
    collider = blocker.get_node_or_null("CollisionShape2D") as CollisionShape2D
    if collider == null:
        collider = CollisionShape2D.new()
        collider.name = "CollisionShape2D"
        blocker.add_child(collider)
    # Never mutate a Shape2D shared with another gate.
    var rectangle: RectangleShape2D = RectangleShape2D.new()
    rectangle.size = Vector2(width, depth)
    collider.shape = rectangle

func set_open(value: bool) -> void:
    opened = value
    _sync_collision()
    queue_redraw()

func _sync_collision() -> void:
    if blocker == null or collider == null:
        return
    if not Engine.is_editor_hint():
        blocker.set_deferred("collision_layer", 0 if opened else 2)
        collider.set_deferred("disabled", opened)

func _draw() -> void:
    if opened:
        for index in range(5):
            var x: float = -width * 0.45 + float(index) * width * 0.21
            draw_line(Vector2(x, depth * 0.32), Vector2(x + 15, depth * 0.54), Color("59474e"), 2.5, true)
        return
    var dark: Color = Color("493941")
    var iron: Color = Color("968291")
    for i in range(4):
        var x: float = -width * 0.43 + float(i) * width * 0.28
        draw_line(Vector2(x, -depth * 0.65), Vector2(x + 8.0, depth * 0.65), dark, 8.0, true)
        draw_line(Vector2(x + 3.0, -depth * 0.62), Vector2(x + 12.0, depth * 0.61), iron, 1.7, true)
    draw_line(Vector2(-width * 0.49, -depth * 0.26), Vector2(width * 0.49, -depth * 0.26), iron, 3.0, true)
    draw_line(Vector2(-width * 0.49, depth * 0.31), Vector2(width * 0.49, depth * 0.31), iron, 3.0, true)
