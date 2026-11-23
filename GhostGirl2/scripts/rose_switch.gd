@tool
extends Node2D
## Aim F at the rose to release its distant spectral gate.
## In each room, place inside Gameplay/HookAnchors so it is saved/restored.
@export var gate_path: NodePath
@export var discovery_id: String = ""
@export var hover_radius: float = 26.0
var activated: bool = false
var elapsed: float = 0.0
var save_inventory: Node

func _ready() -> void:
    if not Engine.is_editor_hint():
        add_to_group("hook_switch")

func restore_secret(inventory: Node) -> void:
    save_inventory = inventory
    if inventory != null and not discovery_id.is_empty():
        activated = bool(inventory.call("has_collected", discovery_id))
    _apply_gate()

func _apply_gate() -> void:
    var gate: Node = get_node_or_null(gate_path)
    if gate != null and gate.has_method("set_open"):
        gate.call("set_open", activated)

func on_hook_latched() -> void:
    if activated or Engine.is_editor_hint():
        return
    activated = true
    _apply_gate()
    if save_inventory != null and not discovery_id.is_empty():
        var records: Dictionary = save_inventory.get("collected_pickups") as Dictionary
        records[discovery_id] = true
        save_inventory.call("save_game")
    var current: Node = get_tree().current_scene
    if current != null and current.has_node("HUD"):
        current.get_node("HUD").call("show_pickup", "A ROSE SEAL RELEASES")

func _process(delta: float) -> void:
    elapsed += delta
    queue_redraw()

func _draw() -> void:
    var shade: Color = Color(0.68, 0.51, 0.65, 0.50) if activated else Color(0.92, 0.68, 0.82, 0.68 + 0.12 * sin(elapsed * 3.0))
    draw_arc(Vector2.ZERO, hover_radius, 0.0, TAU, 36, shade, 2.0, true)
    for i in range(6):
        var a: float = float(i) * TAU / 6.0 + elapsed * 0.22
        draw_circle(Vector2.from_angle(a) * 10.0, 5.0, shade)
    draw_circle(Vector2.ZERO, 5.0, Color(0.96, 0.90, 1.0, shade.a))
