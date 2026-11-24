@tool
extends Node2D
## Optional creativity reward: combining several different world interactions
## opens a gate without forcing the player to complete a particular route.
@export var required_sites: PackedStringArray = PackedStringArray()
@export var gate_path: NodePath
@export var title: String = "Moonrose Salvage"
var inventory: Node = null
var activated: bool = false
var completed: int = 0
var elapsed: float = 0.0

func _ready() -> void:
    if not Engine.is_editor_hint():
        add_to_group("v135_hazard_seal")

func restore_from_inventory(saved_inventory: Node) -> void:
    inventory = saved_inventory
    refresh()

func refresh() -> void:
    if inventory == null:
        return
    completed = 0
    for site in required_sites:
        if inventory.call("has_collected", site):
            completed += 1
    activated = required_sites.size() > 0 and completed >= required_sites.size()
    var gate: Node = get_node_or_null(gate_path)
    if gate != null and gate.has_method("set_open"):
        gate.call("set_open", activated)
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    queue_redraw()

func _draw() -> void:
    var color: Color = Color("b0e1d8") if activated else Color("dfacc9")
    draw_circle(Vector2.ZERO, 33.0, Color(color.r, color.g, color.b, 0.08))
    draw_arc(Vector2.ZERO, 26.0, 0.0, TAU, 44, Color(color.r, color.g, color.b, 0.48), 1.8, true)
    var total: int = maxi(1, required_sites.size())
    for i in range(total):
        var p: Vector2 = Vector2.from_angle(float(i) * TAU / float(total) - PI * 0.5) * 17.0
        draw_circle(p, 4.4, Color("d7ffed") if i < completed else Color("534252"))
    if activated:
        draw_arc(Vector2.ZERO, 36.0, elapsed, elapsed + PI, 25, Color(0.79, 0.94, 0.86, 0.37), 1.5, true)
