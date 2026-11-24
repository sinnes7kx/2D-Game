@tool
extends Node2D
## Three sequential rose bells reveal a permanent optional Crypt Gallery cache.
@export var relay_id: String = "v147_gallery_rose_relay"
@export var chest_path: NodePath = NodePath("../TreasureChests/ThreeRoseCache")
var inventory: Node
var progress: int = 0
var completed: bool = false

func restore_from_inventory(saved_inventory: Node) -> void:
    inventory = saved_inventory
    completed = inventory != null and inventory.call("has_collected", relay_id)
    if completed:
        _reveal(true)
    queue_redraw()

func ring(step: int) -> void:
    if completed or Engine.is_editor_hint():
        return
    if step == progress + 1:
        progress += 1
        _say("MEMORIAL CHIME  %d / 3" % progress, Color("dcc4ec"))
        if progress >= 3:
            completed = true
            if inventory != null:
                var flags: Dictionary = inventory.get("collected_pickups") as Dictionary
                flags[relay_id] = true
                inventory.call("save_game")
            _reveal(false)
            _say("THREE ROSES ANSWER · THE HIDDEN RELIQUARY OPENS", Color("ead4a5"))
    else:
        progress = 0
        _say("THE ROSES FALL SILENT · BEGIN AT THE FIRST", Color("cfa9c8"))
    queue_redraw()

func _reveal(restoring: bool) -> void:
    var chest: Node = get_node_or_null(chest_path)
    if chest != null and chest.has_method("reveal_from_collapse"):
        chest.call("reveal_from_collapse", restoring)

func _say(message: String, tint: Color) -> void:
    var game: Node = get_tree().current_scene
    if game != null and game.has_node("HUD"):
        game.get_node("HUD").call("show_pickup", message, tint)
