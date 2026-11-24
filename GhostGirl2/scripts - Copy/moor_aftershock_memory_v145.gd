@tool
extends Node2D
## Reward an environmental solution, not a prescribed spell or weapon.
## This node listens to actual collapses nearby; reloaded progress persists.
@export var discovery_id: String = "v145_aftershock_west"
@export var display_name: String = "The Aftershock Thread"
@export var reward_chest_path: NodePath
@export var prior_completed_keys: PackedStringArray = PackedStringArray()
@export_range(80.0, 420.0, 10.0) var listen_radius: float = 290.0
var inventory: Node = null
var awakened: bool = false
var shimmer: float = 0.0
var elapsed: float = 0.0

func _ready() -> void:
    if not Engine.is_editor_hint():
        add_to_group("v145_aftershock_memory")

func restore_from_inventory(saved_inventory: Node) -> void:
    inventory = saved_inventory
    awakened = inventory != null and inventory.has_collected(discovery_id)
    # Saves that already collapsed these structures in v1.44 must not lose
    # access to the new reward after updating the game.
    if not awakened and inventory != null:
        for completed_key in prior_completed_keys:
            if inventory.has_collected(completed_key):
                awakened = true
                var flags: Dictionary = inventory.get("collected_pickups") as Dictionary
                flags[discovery_id] = true
                inventory.call("save_game")
                break
    _sync_reward()
    queue_redraw()

func on_world_change(world_point: Vector2, _source: String) -> void:
    if Engine.is_editor_hint() or awakened:
        return
    if global_position.distance_squared_to(world_point) > listen_radius * listen_radius:
        return
    awakened = true
    shimmer = 1.0
    if inventory == null:
        var root: Node = get_tree().current_scene
        inventory = root.get_node_or_null("Inventory") if root != null else null
    if inventory != null:
        var flags: Dictionary = inventory.get("collected_pickups") as Dictionary
        flags[discovery_id] = true
        inventory.call("save_game")
    _sync_reward()
    var game: Node = get_tree().current_scene
    if game != null and game.has_node("HUD"):
        game.get_node("HUD").call("show_pickup", display_name.to_upper() + " REMEMBERS THE FALL", Color("e4c6d8"))
    queue_redraw()

func _sync_reward() -> void:
    if reward_chest_path.is_empty():
        return
    var chest: Node2D = get_node_or_null(reward_chest_path) as Node2D
    if chest == null:
        push_warning("Aftershock reward chest not found: " + str(reward_chest_path))
        return
    chest.visible = awakened
    if awakened and not bool(chest.get("opened")):
        chest.add_to_group("interactable")
    else:
        chest.remove_from_group("interactable")

func _process(delta: float) -> void:
    elapsed += delta
    shimmer = maxf(0.0, shimmer - delta * 0.75)
    if awakened or Engine.is_editor_hint():
        queue_redraw()

func _draw() -> void:
    if not awakened and not Engine.is_editor_hint():
        return
    var alpha: float = 0.60 if awakened else 0.19
    var line_color: Color = Color(0.86, 0.74, 0.83, alpha)
    # A narrow fractured memorial, never a floating circular UI effect.
    draw_line(Vector2(-13, 8), Vector2(-4, -27), Color("65545f"), 5.0, true)
    draw_line(Vector2(-4, -27), Vector2(13, 8), Color("9b8796"), 4.0, true)
    draw_line(Vector2(-11, 7), Vector2(11, 7), line_color, 1.5, true)
    var highlight: float = 0.26 + 0.14 * sin(elapsed * 1.3)
    draw_line(Vector2(-2, -24), Vector2(2, -7), Color(0.92, 0.79, 0.91, alpha * highlight), 2.0, true)
    if shimmer > 0.0:
        for i in range(3):
            var shift: float = float(i - 1) * 12.0
            draw_line(Vector2(shift, -4), Vector2(shift + 4, -21 - shimmer * 15.0), Color(0.93, 0.83, 0.92, shimmer * 0.32), 1.2, true)
