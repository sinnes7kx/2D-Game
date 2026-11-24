@tool
extends Node2D
## Optional three-part exploration mechanism: F hook -> T Grasping Roses
## -> Z Moonfall. Each stage is saved independently; treasure is still
## awarded by the existing chest's one-time pickup system.
@export var discovery_id: String = "v130_triune"
@export var gate_path: NodePath
@export_range(30.0, 130.0, 1.0) var hover_radius: float = 30.0
@export_range(30.0, 160.0, 1.0) var bloom_radius: float = 65.0
var activated: bool = false
var stage: int = 0
var elapsed: float = 0.0
var emphasis: float = 0.0
var inventory: Node

func _ready() -> void:
    if not Engine.is_editor_hint():
        add_to_group("hook_switch")
        add_to_group("rose_bloom_relay")
        add_to_group("v130_triune_relay")

func restore_secret(save_data: Node) -> void:
    inventory = save_data
    stage = 0
    if inventory != null:
        for suffix in ["hook", "rose", "frost"]:
            if inventory.call("has_collected", discovery_id + "_" + suffix):
                stage += 1
            else:
                break
    activated = stage >= 3
    _apply_gate()

func _apply_gate() -> void:
    var gate: Node = get_node_or_null(gate_path)
    if gate != null and gate.has_method("set_open"):
        gate.call("set_open", activated)
    queue_redraw()

func hook_prompt() -> String:
    match stage:
        0: return "F  DRAW OUT THE SLEEPING ROSE"
        1: return "T  AWAKEN THE ROSE WITH MAGIC"
        2: return "Z  FREEZE THE OPEN BLOOM"
        _: return ""

func on_hook_latched() -> void:
    if not Engine.is_editor_hint() and stage == 0:
        _advance("hook", "THE ROOTS STIR  ·  GRASPING ROSES NEXT", Color("e3b1da"))

func on_grasping_roses() -> bool:
    if Engine.is_editor_hint() or stage != 1:
        return false
    _advance("rose", "THE ROSE BLOOMS  ·  MOONFALL NEXT", Color("eab2cf"))
    return true

func on_moonfall() -> bool:
    if Engine.is_editor_hint() or stage != 2:
        return false
    _advance("frost", "TRIUNE SEAL RELEASED  ·  TREASURE AWAKENS", Color("cce7ff"))
    return true

func _advance(suffix: String, message: String, color: Color) -> void:
    if inventory == null:
        var game: Node = get_tree().current_scene
        if game != null:
            inventory = game.get_node_or_null("Inventory")
    if inventory == null:
        return
    stage = mini(3, stage + 1)
    var records: Dictionary = inventory.get("collected_pickups") as Dictionary
    records[discovery_id + "_" + suffix] = true
    inventory.call("save_game")
    activated = stage >= 3
    emphasis = 0.75
    _apply_gate()
    var root: Node = get_tree().current_scene
    if root != null and root.has_node("HUD"):
        root.get_node("HUD").call("show_pickup", message, color)

func _process(delta: float) -> void:
    elapsed += delta
    emphasis = maxf(0.0, emphasis - delta)
    queue_redraw()

func _draw() -> void:
    var shades: Array[Color] = [Color("c59baf"), Color("eab6d4"), Color("b6badf"), Color("bfe9ef")]
    var ink: Color = shades[clampi(stage, 0, 3)]
    var pulse: float = 0.5 + 0.5 * sin(elapsed * 2.1)
    draw_circle(Vector2.ZERO, hover_radius * 1.25, Color(ink.r, ink.g, ink.b, 0.08 + emphasis * 0.12))
    draw_arc(Vector2.ZERO, hover_radius, elapsed * 0.24, elapsed * 0.24 + PI * 1.75, 48, Color(ink.r, ink.g, ink.b, 0.39 + pulse * 0.25), 2.6, true)
    for n in range(3):
        var a: float = TAU * float(n) / 3.0 - PI * 0.5
        var point: Vector2 = Vector2.from_angle(a) * hover_radius * 0.58
        var active_color: Color = shades[n + 1] if stage > n else Color("463945")
        draw_circle(point, 6.5, Color(active_color.r, active_color.g, active_color.b, 0.77 if stage > n else 0.37))
        draw_arc(point, 7.5, 0.0, TAU, 18, Color(ink.r, ink.g, ink.b, 0.48), 1.1, true)
    if stage == 3:
        for k in range(5):
            var angle: float = elapsed * 0.6 + TAU * float(k) / 5.0
            draw_circle(Vector2.from_angle(angle) * hover_radius * 0.91, 2.4, Color("e4eef8"))
