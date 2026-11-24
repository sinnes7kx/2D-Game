@tool
extends Node2D
## Reusable secret revealed by latching the Moonrose Hook.
## To set it up in the editor: assign relative Secret Chest NodePath and an ID.
@export var secret_chest: NodePath = NodePath("../../TreasureChests/HiddenRosary")
@export var discovery_id: String = "ashglass_hidden_rose"
@export var visible_radius: float = 19.0
var revealed: bool = false
var elapsed: float = 0.0
var save_inventory: Node = null

func _ready() -> void:
    if Engine.is_editor_hint():
        return
    add_to_group("hook_anchor")
    _show_cache(false)

func restore_secret(inventory: Node) -> void:
    save_inventory = inventory
    revealed = inventory != null and bool(inventory.call("has_collected", discovery_id))
    _show_cache(revealed)

func _show_cache(allow: bool) -> void:
    var chest: Node2D = get_node_or_null(secret_chest) as Node2D
    if chest == null:
        return
    chest.visible = allow
    if allow and not bool(chest.get("opened")):
        chest.add_to_group("interactable")
    elif not allow:
        chest.remove_from_group("interactable")

func on_hook_latched() -> void:
    if revealed or Engine.is_editor_hint():
        return
    revealed = true
    _show_cache(true)
    if save_inventory != null:
        var collected: Dictionary = save_inventory.get("collected_pickups") as Dictionary
        collected[discovery_id] = true
        save_inventory.call("save_game")
    var main: Node = get_tree().current_scene
    if main != null and main.has_node("HUD"):
        main.get_node("HUD").call("show_pickup", "A HIDDEN COFFER STIRS")

func _process(delta: float) -> void:
    elapsed += delta
    queue_redraw()

func _draw() -> void:
    var a: float = 0.3 + 0.1 * sin(elapsed * 1.2)
    var tint: Color = Color(0.80, 0.67, 0.69, a) if not revealed else Color(0.57, 0.63, 0.58, 0.36)
    draw_arc(Vector2.ZERO, visible_radius, 0.0, TAU, 28, tint, 2.0, true)
    for i in range(5):
        var theta: float = float(i) * TAU / 5.0
        draw_circle(Vector2.from_angle(theta) * 6.0, 4.5, tint)
    draw_circle(Vector2.ZERO, 3.0, Color(0.91, 0.83, 0.76, a + 0.12))
