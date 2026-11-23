@tool
extends Node2D
## Four readable, persistent moor memorials. Each can be awakened by E;
## no combat, rare wand, or undiscovered spell is required to finish the hunt.
@export var memory_id: String = "v132_vigil_west"
@export var memory_title: String = "THE WILLOW LAMENT"
@export var hint_text: String = "A faded bell remembers the lost moor."
@export var glow_color: Color = Color("d6b8df")
var awakened: bool = false
var elapsed: float = 0.0

func _ready() -> void:
    if not Engine.is_editor_hint():
        add_to_group("moor_vigil_memory")
        add_to_group("interactable")

func restore_from_inventory(inventory: Node) -> void:
    awakened = inventory != null and inventory.has_collected(memory_id)
    if awakened:
        remove_from_group("interactable")
    else:
        add_to_group("interactable")
    queue_redraw()

func awaken(inventory: Node) -> bool:
    if awakened or inventory == null:
        return false
    var records: Dictionary = inventory.get("collected_pickups") as Dictionary
    records[memory_id] = true
    inventory.call("save_game")
    awakened = true
    remove_from_group("interactable")
    queue_redraw()
    return true

func _process(delta: float) -> void:
    elapsed += delta
    if Engine.is_editor_hint() or not awakened:
        queue_redraw()

func _draw() -> void:
    var glow: float = 0.5 + 0.5 * sin(elapsed * 1.8)
    draw_circle(Vector2(0, 3), 26, Color(0.02, 0.01, 0.04, 0.3))
    var stone: Color = Color("3c3448")
    draw_colored_polygon(PackedVector2Array([Vector2(-18, 10), Vector2(-20, -27), Vector2(-12, -48), Vector2(12, -48), Vector2(20, -27), Vector2(18, 10)]), stone)
    draw_line(Vector2(-19, 10), Vector2(-20, -27), Color("9c879f"), 2.0, true)
    draw_line(Vector2(-20, -27), Vector2(-12, -48), Color("a491aa"), 1.8, true)
    draw_line(Vector2(-12, -48), Vector2(12, -48), Color("b2a0b8"), 1.7, true)
    draw_line(Vector2(12, -48), Vector2(20, -27), Color("a491aa"), 1.8, true)
    draw_line(Vector2(20, -27), Vector2(18, 10), Color("9c879f"), 2.0, true)
    var ink: Color = Color("777080") if awakened else glow_color
    draw_circle(Vector2(0, -25), 8.5, Color(ink.r, ink.g, ink.b, 0.10 + (0.11 * glow if not awakened else 0.0)))
    draw_arc(Vector2(0, -25), 8.5, 0.0, TAU, 24, Color(ink.r, ink.g, ink.b, 0.60 if not awakened else 0.22), 1.9, true)
    draw_line(Vector2(0, -36), Vector2(0, -17), ink, 1.5, true)
    draw_line(Vector2(-8, -25), Vector2(8, -25), ink, 1.5, true)
    if not awakened:
        draw_arc(Vector2(0, -23), 30.0 + glow * 2.0, elapsed * 0.25, elapsed * 0.25 + PI * 1.7, 32, Color(ink.r, ink.g, ink.b, 0.20 + 0.11 * glow), 1.6, true)
        for i in range(5):
            var a: float = elapsed * 0.42 + TAU * float(i) / 5.0
            draw_circle(Vector2.from_angle(a) * 27.0 + Vector2(0, -23), 1.5, Color(ink.r, ink.g, ink.b, 0.45))
