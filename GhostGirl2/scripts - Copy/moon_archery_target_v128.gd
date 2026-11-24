@tool
extends Node2D
## Precision target for one CHARGED bow arrow loosed while jumping.
## No extra arrow physics body or damage path. Saved once per discovery ID.
@export var discovery_id: String = "v128_moon_archery"
@export var gate_path: NodePath
@export_range(14.0, 55.0, 1.0) var trigger_radius: float = 31.0
var activated: bool = false
var elapsed: float = 0.0
var inventory: Node = null

func _ready() -> void:
    if not Engine.is_editor_hint():
        add_to_group("moon_archery_targets")

func restore_secret(save_data: Node) -> void:
    inventory = save_data
    activated = inventory != null and inventory.has_collected(discovery_id)
    _apply_gate()

func _apply_gate() -> void:
    var gate: Node = get_node_or_null(gate_path)
    if gate != null and gate.has_method("set_open"):
        gate.call("set_open", activated)
    queue_redraw()

func on_bow_hit(charged: bool, airborne: bool) -> bool:
    if Engine.is_editor_hint() or activated or not (charged and airborne):
        return false
    if inventory == null:
        var game: Node = get_tree().current_scene
        if game != null:
            inventory = game.get_node_or_null("Inventory")
    if inventory == null:
        return false
    activated = true
    var saved: Dictionary = inventory.get("collected_pickups") as Dictionary
    saved[discovery_id] = true
    inventory.call("save_game")
    _apply_gate()
    var root: Node = get_tree().current_scene
    if root != null and root.has_node("HUD"):
        root.get_node("HUD").call("show_pickup", "MOONSHOT! THE AIRBORNE ARROW RELEASES A RELIC", Color("f1dbab"))
    return true

func _process(delta: float) -> void:
    elapsed += delta
    queue_redraw()

func _draw() -> void:
    var ink: Color = Color("8b98aa") if activated else Color("b8c8f3")
    var glow: float = 0.19 if activated else 0.45 + 0.16 * sin(elapsed * 2.4)
    draw_circle(Vector2.ZERO, trigger_radius + 14.0, Color(ink.r, ink.g, ink.b, glow * 0.10))
    draw_arc(Vector2.ZERO, trigger_radius, 0.0, TAU, 40, Color(ink.r, ink.g, ink.b, glow), 2.7, true)
    draw_arc(Vector2.ZERO, trigger_radius * 0.52, elapsed * 0.4, elapsed * 0.4 + TAU * 0.85, 32, Color(ink.r, ink.g, ink.b, glow * 0.80), 1.6, true)
    for n in range(4):
        var p: Vector2 = Vector2.from_angle(elapsed * 0.35 + TAU * float(n) / 4.0) * (trigger_radius * 0.78)
        draw_circle(p, 2.0, Color("ebe1ff") if not activated else ink)
