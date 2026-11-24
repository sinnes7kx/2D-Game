@tool
extends Node2D
## Editor-placed post-boss seal. The linked rose_gate controls the single
## unique chest; this node never duplicates item generation or loot rolling.
const ECHO_IDS: Array[String] = ["v133_bellglass_hook", "v133_bellglass_frost", "v133_bellglass_bow"]
const WARDEN_FLAG: String = "v132_moor_warden_defeated"
@export var gate_path: NodePath
var gathered: int = 0
var released: bool = false
var elapsed: float = 0.0

func restore_from_inventory(inventory: Node) -> void:
    refresh_from_inventory(inventory)

func refresh_from_inventory(inventory: Node) -> void:
    gathered = 0
    if inventory != null:
        for echo_id in ECHO_IDS:
            if inventory.has_collected(echo_id):
                gathered += 1
    released = inventory != null and inventory.has_collected(WARDEN_FLAG) and gathered == ECHO_IDS.size()
    var gate: Node = get_node_or_null(gate_path)
    if gate != null and gate.has_method("set_open"):
        gate.call("set_open", released)
    queue_redraw()

func _process(delta: float) -> void:
    elapsed += delta
    if Engine.is_editor_hint() or not released:
        queue_redraw()

func _draw() -> void:
    var pulse: float = 0.5 + 0.5 * sin(elapsed * 1.7)
    var ring: Color = Color("d8c1e9") if released else Color("b2a2c9")
    draw_circle(Vector2.ZERO, 60.0, Color(0.06, 0.035, 0.075, 0.36))
    draw_arc(Vector2.ZERO, 54.0, 0.0, TAU, 60, Color(ring.r, ring.g, ring.b, 0.25 + 0.16 * pulse), 2.0, true)
    for i in range(3):
        var angle: float = float(i) * TAU / 3.0 - PI * 0.5
        var p: Vector2 = Vector2.from_angle(angle) * 38.0
        var ink: Color = Color("a9e2cc") if i < gathered else Color("5c506c")
        draw_circle(p, 7.0, ink)
        draw_arc(p, 11.0, 0.0, TAU, 20, Color(ring.r, ring.g, ring.b, 0.45), 1.4, true)
    if released:
        draw_arc(Vector2.ZERO, 66.0, elapsed * 0.4, elapsed * 0.4 + PI * 1.2, 46, Color(0.86, 0.81, 1.0, 0.5), 1.5, true)
