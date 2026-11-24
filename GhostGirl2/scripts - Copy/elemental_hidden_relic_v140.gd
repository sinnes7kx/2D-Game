@tool
extends Node2D
## A genuinely hidden world object: light from a nearby luminous arrow
## exposes an otherwise invisible object and optionally its linked chest.
## Its reveal flag is saved using the existing item-collection dictionary.
@export var discovery_id: String = "v140_hidden_relic"
@export var display_name: String = "Forgotten moonmark"
@export var reward_chest_path: NodePath
@export_range(30.0, 260.0, 1.0) var reveal_radius: float = 155.0
@export var hint_visible_in_editor: bool = true
var inventory: Node = null
var revealed: bool = false
var age: float = 0.0
var reveal_flash: float = 0.0

func _ready() -> void:
    if not Engine.is_editor_hint():
        add_to_group("v140_light_reveal")

func restore_from_inventory(saved_inventory: Node) -> void:
    inventory = saved_inventory
    revealed = inventory != null and inventory.has_collected(discovery_id)
    _refresh_chest()
    queue_redraw()

func reveal_from_light(world_point: Vector2) -> bool:
    if Engine.is_editor_hint() or revealed:
        return false
    if global_position.distance_squared_to(world_point) > reveal_radius * reveal_radius:
        return false
    revealed = true
    reveal_flash = 1.0
    if inventory == null:
        var game: Node = get_tree().current_scene
        inventory = game.get_node_or_null("Inventory") if game != null else null
    if inventory != null:
        var flags: Dictionary = inventory.get("collected_pickups") as Dictionary
        flags[discovery_id] = true
        inventory.call("save_game")
    _refresh_chest()
    var root: Node = get_tree().current_scene
    if root != null and root.has_node("HUD"):
        root.get_node("HUD").call("show_pickup", "LIGHT UNCOVERS " + display_name.to_upper(), Color("fff0c9"))
    queue_redraw()
    return true

func _refresh_chest() -> void:
    if reward_chest_path.is_empty():
        return
    var chest: Node2D = get_node_or_null(reward_chest_path) as Node2D
    if chest == null:
        return
    chest.visible = revealed
    if revealed and not bool(chest.get("opened")):
        chest.add_to_group("interactable")
    else:
        chest.remove_from_group("interactable")

func _process(delta: float) -> void:
    age += delta
    if reveal_flash > 0.0:
        reveal_flash = maxf(0.0, reveal_flash - delta * 1.45)
        queue_redraw()
    elif Engine.is_editor_hint() or revealed:
        queue_redraw()

func _draw() -> void:
    if not revealed and not (Engine.is_editor_hint() and hint_visible_in_editor):
        return
    var alpha: float = 0.70 if revealed else 0.18
    var moon: Color = Color("f9e9c0")
    draw_arc(Vector2.ZERO, 34.0, age * 0.18, age * 0.18 + PI * 1.75, 32, Color(moon.r, moon.g, moon.b, alpha), 2.2, true)
    for i in range(6):
        var a: float = float(i) * TAU / 6.0 + age * 0.25
        var p: Vector2 = Vector2.from_angle(a) * 23.0
        draw_circle(p, 2.7, Color(moon.r, moon.g, moon.b, alpha * 0.7))
    if reveal_flash > 0.0:
        draw_arc(Vector2.ZERO, 45.0 + (1.0 - reveal_flash) * 115.0, 0.0, TAU, 42, Color(1.0, 0.92, 0.72, reveal_flash * 0.5), 2.6, true)
