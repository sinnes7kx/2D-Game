@tool
extends StaticBody2D
## Layer 6 (bit 32): the only obstacle category Ghost Girl can jump over.
## Normal walls, crates, enemies and other collisions remain unchanged.
@export var barrier_size: Vector2 = Vector2(32, 165)
var age: float = 0.0

func _ready() -> void:
    collision_layer = 32
    collision_mask = 0
    if not has_node("CollisionShape2D"):
        var child: CollisionShape2D = CollisionShape2D.new()
        child.name = "CollisionShape2D"
        var shape: RectangleShape2D = RectangleShape2D.new()
        shape.size = barrier_size
        child.shape = shape
        add_child(child)

func _process(delta: float) -> void:
    age += delta
    queue_redraw()

func _draw() -> void:
    var half: float = barrier_size.y * 0.5
    var c: Color = Color(0.62, 0.47, 0.72, 0.92)
    draw_rect(Rect2(-barrier_size.x * 0.5, -half, barrier_size.x, barrier_size.y), Color(0.14, 0.08, 0.20, 0.40), true)
    for i in range(13):
        var y: float = -half + float(i) * (barrier_size.y / 12.0)
        var wave: float = sin(age * 1.5 + float(i) * 0.8) * 3.0
        draw_line(Vector2(-18 + wave, y), Vector2(18 - wave, y - 6), c, 2.3, true)
        draw_line(Vector2(-15 + wave, y), Vector2(-24 + wave, y - 7), Color("d5a9db"), 1.4, true)
    draw_arc(Vector2(0, 0), 30, -PI * 0.5, PI * 0.5, 18, Color("ddbadf"), 2.2, true)
