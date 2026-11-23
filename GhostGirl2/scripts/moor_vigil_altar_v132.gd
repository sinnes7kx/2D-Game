@tool
extends Node2D
## The Moor Vigil encounter is optional, editor-placeable, and persistent.
## Four memories awaken the altar; the boss itself is reset on room re-entry
## until defeated, while its reward gate stays permanently open afterwards.
const MEMORY_IDS: Array[String] = ["v132_vigil_willow", "v132_vigil_graves", "v132_vigil_fen", "v132_vigil_ruins"]
const DEFEAT_ID: String = "v132_moor_warden_defeated"
@export var boss_path: NodePath
@export var reward_gate_path: NodePath
@export var bonus_gate_path: NodePath
@export var second_reward_gate_path: NodePath
var inventory: Node = null
var completed: bool = false
var activated_this_visit: bool = false
var elapsed: float = 0.0

func _ready() -> void:
    if not Engine.is_editor_hint():
        add_to_group("interactable")
        add_to_group("moor_vigil_altar")

func restore_from_inventory(save_data: Node) -> void:
    inventory = save_data
    completed = inventory != null and inventory.has_collected(DEFEAT_ID)
    activated_this_visit = false
    var boss: Node = get_node_or_null(boss_path)
    if boss != null and boss.has_method("restore_warden"):
        boss.call("restore_warden", completed)
    _apply_gate()
    queue_redraw()

func progress() -> int:
    if inventory == null:
        return 0
    var count: int = 0
    for id in MEMORY_IDS:
        if inventory.has_collected(id):
            count += 1
    return count

func try_awaken() -> String:
    if completed:
        return "THE WARDEN RESTS. THE RELIQUARY IS YOURS."
    if inventory == null:
        return "THE ALTAR DOES NOT ANSWER."
    var count: int = progress()
    if count < MEMORY_IDS.size():
        return "MOOR VIGIL: %d / 4 LAMENTS · SEEK THE FOUR MEMORIALS" % count
    if activated_this_visit:
        return "THE WARDEN WAITS BEYOND THE ALTAR"
    var boss: Node = get_node_or_null(boss_path)
    if boss == null or not boss.has_method("begin_encounter"):
        return "THE WARDEN CANNOT BE SUMMONED"
    activated_this_visit = true
    boss.call("begin_encounter")
    queue_redraw()
    return "THE MOOR WARDEN AWAKENS · BREAK HIS CHARGE"

func refresh_progress() -> void:
    _apply_gate()
    queue_redraw()

func mark_completed() -> void:
    completed = true
    activated_this_visit = false
    _apply_gate()
    queue_redraw()

func _apply_gate() -> void:
    var gate: Node = get_node_or_null(reward_gate_path)
    if gate != null and gate.has_method("set_open"):
        gate.call("set_open", completed)
    var second: Node = get_node_or_null(second_reward_gate_path)
    if second != null and second.has_method("set_open"):
        second.call("set_open", completed)
    var bonus: Node = get_node_or_null(bonus_gate_path)
    if bonus != null and bonus.has_method("set_open"):
        bonus.call("set_open", progress() >= 2)

func _process(delta: float) -> void:
    elapsed += delta
    queue_redraw()

func _draw() -> void:
    var count: int = progress() if not Engine.is_editor_hint() else 2
    var r: float = 60.0
    var ink: Color = Color("f0d9aa") if count >= 4 else Color("b8a1c4")
    draw_circle(Vector2.ZERO, 71.0, Color(0.10, 0.05, 0.12, 0.23))
    draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, Color(ink.r, ink.g, ink.b, 0.32), 3.0, true)
    draw_arc(Vector2.ZERO, 42.0, elapsed * 0.16, elapsed * 0.16 + PI * 1.7, 54, Color(ink.r, ink.g, ink.b, 0.37), 1.5, true)
    for i in range(4):
        var theta: float = TAU * float(i) / 4.0 - PI * 0.5
        var p: Vector2 = Vector2.from_angle(theta) * r
        var c: Color = Color("dfc89b") if completed else (Color("b7d3fa") if i < count else Color("494050"))
        draw_circle(p, 9.0, Color(c.r, c.g, c.b, 0.35 if i >= count and not completed else 0.92))
        draw_arc(p, 11.0, 0.0, TAU, 24, Color(ink.r, ink.g, ink.b, 0.5), 1.2, true)
    var pulse: float = 0.5 + 0.5 * sin(elapsed * 2.3)
    draw_circle(Vector2.ZERO, 14.0 + 2.0 * pulse, Color(ink.r, ink.g, ink.b, (0.09 + pulse * 0.10) if count >= 4 else 0.07))
    draw_colored_polygon(PackedVector2Array([Vector2(0, -23), Vector2(9, 0), Vector2(0, 23), Vector2(-9, 0)]), Color(ink.r, ink.g, ink.b, 0.85 if count >= 4 else 0.31))
