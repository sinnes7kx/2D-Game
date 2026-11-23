@tool
extends Node2D
## One saved gate for each pair of arrow puzzles. No new save schema.
@export var required_flags: PackedStringArray = PackedStringArray()
@export var gate_path: NodePath
var inventory: Node = null
var unlocked: bool = false
var elapsed: float = 0.0

func _ready() -> void:
    if not Engine.is_editor_hint():
        add_to_group("v138_bow_vaults")

func restore_from_inventory(saved_inventory: Node) -> void:
    inventory = saved_inventory
    refresh()

func refresh() -> void:
    if inventory == null:
        return
    unlocked = not required_flags.is_empty()
    for key in required_flags:
        if not inventory.has_collected(key):
            unlocked = false
    var gate: Node = get_node_or_null(gate_path)
    if gate != null and gate.has_method("set_open"):
        gate.call("set_open", unlocked)
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    queue_redraw()

func _draw() -> void:
    var tone: Color = Color("c4e9df") if unlocked else Color("e0b7d4")
    draw_circle(Vector2.ZERO, 43.0, Color(tone.r, tone.g, tone.b, 0.07))
    draw_arc(Vector2.ZERO, 36.0, elapsed * 0.3, elapsed * 0.3 + TAU * 0.9, 40, Color(tone.r, tone.g, tone.b, 0.47), 2.0, true)
    for i in range(maxi(1, required_flags.size())):
        var p: Vector2 = Vector2.from_angle(float(i) * TAU / float(maxi(1,required_flags.size())) - PI * 0.5) * 21.0
        var done: bool = inventory != null and i < required_flags.size() and inventory.has_collected(required_flags[i])
        draw_circle(p, 5.0, Color("d8f9e1") if done else Color("5c5067"))
