@tool
extends Node2D
## v1.31 optional two-stage discovery:
## 1) physically strike the moon disc with a charged bow shot while jumping;
## 2) cast Grasping Roses beside it. Both steps persist via existing save keys.
## This consumes one normal arrow event; no bonus hits or damage.
@export var discovery_id: String = "v131_moonshot_bloom"
@export var gate_path: NodePath
@export_range(16.0, 52.0, 1.0) var trigger_radius: float = 38.0
@export_range(30.0, 150.0, 1.0) var bloom_radius: float = 73.0
var activated: bool = false
var stage: int = 0
var elapsed: float = 0.0
var flash: float = 0.0
var inventory: Node = null

func _ready() -> void:
    if not Engine.is_editor_hint():
        add_to_group("moon_archery_targets")
        add_to_group("rose_bloom_relay")

func restore_secret(save_data: Node) -> void:
    inventory = save_data
    stage = 0
    if inventory != null and inventory.call("has_collected", discovery_id + "_arrow"):
        stage = 1
        if inventory.call("has_collected", discovery_id + "_rose"):
            stage = 2
    activated = stage >= 2
    _apply_gate()

func _apply_gate() -> void:
    var gate: Node = get_node_or_null(gate_path)
    if gate != null and gate.has_method("set_open"):
        gate.call("set_open", activated)
    queue_redraw()

func _save_step(suffix: String) -> bool:
    if inventory == null:
        var root: Node = get_tree().current_scene
        if root != null:
            inventory = root.get_node_or_null("Inventory")
    if inventory == null:
        return false
    var records: Dictionary = inventory.get("collected_pickups") as Dictionary
    records[discovery_id + "_" + suffix] = true
    inventory.call("save_game")
    return true

func on_bow_hit(charged: bool, airborne: bool) -> bool:
    if Engine.is_editor_hint() or stage != 0 or not (charged and airborne):
        return false
    if not _save_step("arrow"):
        return false
    stage = 1
    flash = 0.8
    _notify("MOONSHOT AWAKENED  ·  GRASPING ROSES NEXT", Color("c5d3ff"))
    queue_redraw()
    return true

func on_grasping_roses() -> bool:
    if Engine.is_editor_hint() or stage != 1:
        return false
    if not _save_step("rose"):
        return false
    stage = 2
    activated = true
    flash = 1.0
    _apply_gate()
    _notify("MOONBLOOM RELEASED  ·  A RELIC AWAITS", Color("efb9dc"))
    return true

func _notify(message: String, color: Color) -> void:
    var root: Node = get_tree().current_scene
    if root != null and root.has_node("HUD"):
        root.get_node("HUD").call("show_pickup", message, color)

func _process(delta: float) -> void:
    elapsed += delta
    flash = maxf(0.0, flash - delta)
    queue_redraw()

func _draw() -> void:
    var alpha: float = 0.5 + 0.5 * sin(elapsed * 2.0)
    var ink: Color = Color("afbce9") if stage == 0 else (Color("e5b3d6") if stage == 1 else Color("9fb6ad"))
    var glow: float = 0.18 + alpha * 0.16 + flash * 0.20
    draw_circle(Vector2.ZERO, trigger_radius + 13.0, Color(ink.r, ink.g, ink.b, glow * 0.35))
    draw_arc(Vector2.ZERO, trigger_radius, elapsed * 0.33, elapsed * 0.33 + TAU * 0.91, 46, Color(ink.r, ink.g, ink.b, glow + 0.33), 2.7, true)
    draw_arc(Vector2.ZERO, trigger_radius * 0.56, -elapsed * 0.64, -elapsed * 0.64 + PI * 1.5, 28, Color(ink.r, ink.g, ink.b, glow + 0.10), 1.3, true)
    for k in range(5):
        var a: float = elapsed * 0.45 + TAU * float(k) / 5.0
        var p: Vector2 = Vector2.from_angle(a) * trigger_radius * 0.76
        draw_circle(p, 2.4, Color("f3e7f8") if k < stage * 2 else ink)
    if stage == 0:
        draw_line(Vector2(-14, 0), Vector2(12, 0), Color("e5e0f4"), 2.0, true)
        draw_line(Vector2(12, 0), Vector2(4, -7), Color("e5e0f4"), 2.0, true)
    elif stage == 1:
        draw_circle(Vector2(0, -4), 9.0, Color(0.93, 0.52, 0.69, glow))
        draw_arc(Vector2(0, -4), 13.0, -PI * 0.6, PI * 0.6, 20, Color("f0c3dc"), 1.5, true)
    else:
        draw_circle(Vector2(0, -3), 7.5, Color("dff5ea"))
