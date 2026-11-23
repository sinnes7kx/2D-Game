@tool
extends Node2D
## A spell-activated rose relay. One Grasping Roses cast within bloom_radius
## releases its linked treasure gate. Persisted through the existing save flags.
@export var discovery_id: String = "v128_bloom_relay"
@export var gate_path: NodePath
@export_range(35.0, 140.0, 1.0) var bloom_radius: float = 56.0
var activated: bool = false
var time_passed: float = 0.0
var inventory: Node = null

func _ready() -> void:
    if not Engine.is_editor_hint():
        add_to_group("rose_bloom_relay")

func restore_secret(save_data: Node) -> void:
    inventory = save_data
    activated = inventory != null and inventory.has_collected(discovery_id)
    _apply_gate()

func _apply_gate() -> void:
    var gate: Node = get_node_or_null(gate_path)
    if gate != null and gate.has_method("set_open"):
        gate.call("set_open", activated)
    queue_redraw()

func on_grasping_roses() -> bool:
    if activated or Engine.is_editor_hint():
        return false
    if inventory == null:
        var root: Node = get_tree().current_scene
        if root != null:
            inventory = root.get_node_or_null("Inventory")
    if inventory == null:
        return false
    activated = true
    var collected: Dictionary = inventory.get("collected_pickups") as Dictionary
    collected[discovery_id] = true
    inventory.call("save_game")
    _apply_gate()
    var game: Node = get_tree().current_scene
    if game != null and game.has_node("HUD"):
        game.get_node("HUD").call("show_pickup", "THE GRASPING ROSES AWAKEN A HIDDEN SEAL", Color("e6bed7"))
    return true

func _process(delta: float) -> void:
    time_passed += delta
    queue_redraw()

func _draw() -> void:
    var c: Color = Color("8a93a8") if activated else Color("da9ebc")
    var alpha: float = 0.15 if activated else 0.42 + 0.13 * sin(time_passed * 1.8)
    draw_circle(Vector2.ZERO, 18.0, Color(c.r, c.g, c.b, alpha * 0.15))
    draw_arc(Vector2.ZERO, bloom_radius * 0.67, 0.0, TAU, 48, Color(c.r, c.g, c.b, alpha * 0.40), 1.6, true)
    for i in range(5):
        var a: float = TAU * float(i) / 5.0 + time_passed * 0.23
        var p: Vector2 = Vector2.from_angle(a) * 15.0
        draw_circle(p, 4.0, Color(c.r, c.g, c.b, alpha))
    draw_circle(Vector2.ZERO, 5.0, Color("e2c3db") if not activated else Color("8c9ca9"))
