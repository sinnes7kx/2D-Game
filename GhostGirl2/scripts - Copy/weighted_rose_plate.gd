@tool
extends Node2D
## A persistent weighted rose seal, independently editable per room.
## Pull the linked real crate with Q or carry it with E and drop it with G.
## The coffer and collision gate unlock only once the crate rests on the plate.
@export var crate_path: NodePath
@export var gate_path: NodePath
@export var discovery_id: String = ""
@export_range(25.0, 90.0, 1.0) var trigger_radius: float = 48.0
var activated: bool = false
var occupied: bool = false
var glow_time: float = 0.0
var save_inventory: Node

func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group("rose_weight_plate")

func restore_secret(inventory: Node) -> void:
	save_inventory = inventory
	if inventory != null and not discovery_id.is_empty():
		activated = bool(inventory.call("has_collected", discovery_id))
	_apply_gate()

func _apply_gate() -> void:
	var gate: Node = get_node_or_null(gate_path)
	if gate != null and gate.has_method("set_open"):
		gate.call("set_open", activated)

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or activated:
		return
	var crate: RigidBody2D = get_node_or_null(crate_path) as RigidBody2D
	occupied = false
	if crate != null and not bool(crate.get("held")):
		var z_height: float = float(crate.get("z_height"))
		occupied = z_height < 13.0 and crate.global_position.distance_to(global_position) <= trigger_radius
	if occupied:
		activated = true
		_apply_gate()
		if save_inventory != null and not discovery_id.is_empty():
			var records: Dictionary = save_inventory.get("collected_pickups") as Dictionary
			records[discovery_id] = true
			save_inventory.call("save_game")
		var main: Node = get_tree().current_scene
		if main != null and main.has_node("HUD"):
			main.get_node("HUD").call("show_pickup", "THE WEIGHT AWAKENS A ROSE SEAL")
		queue_redraw()

func _process(delta: float) -> void:
	glow_time += delta
	queue_redraw()

func _draw() -> void:
	var bright: Color = Color(0.88, 0.68, 0.92, 0.95) if activated else Color(0.62, 0.46, 0.72, 0.78)
	var flicker: float = 0.12 * sin(glow_time * 2.6)
	draw_circle(Vector2.ZERO, trigger_radius + 7.0, Color(0.38, 0.19, 0.48, 0.11 + flicker * 0.3))
	draw_arc(Vector2.ZERO, trigger_radius, 0.0, TAU, 44, bright, 4.0, true)
	draw_arc(Vector2.ZERO, trigger_radius - 12.0, 0.0, TAU, 44, Color(bright.r, bright.g, bright.b, 0.55), 1.8, true)
	for i in range(8):
		var a: float = float(i) * TAU / 8.0
		draw_circle(Vector2.from_angle(a) * (trigger_radius - 5.0), 2.5, bright)
	draw_circle(Vector2.ZERO, 11.0 if activated else 7.0, bright)
	if activated:
		draw_arc(Vector2.ZERO, trigger_radius + 15.0, 0.0, TAU, 48, Color(0.86, 0.71, 0.99, 0.34), 2.0)
