@tool
extends Node2D
## Persistent creativity reward: four bells for the first gate; at least
## three distinct tools/skills across any bells for the optional second gate.
@export var bell_ids: PackedStringArray = PackedStringArray()
@export var method_threshold: int = 0
@export var gate_path: NodePath
@export var title: String = "The Bellroot Chorus"
var inventory: Node = null
var progress: int = 0
var method_count: int = 0
var unlocked: bool = false
var clock: float = 0.0
const METHODS: Array[String] = ["hook", "roses", "frost", "bow", "debris"]

func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group("v137_chorus_vault")

func restore_from_inventory(saved_inventory: Node) -> void:
	inventory = saved_inventory
	refresh()

func refresh() -> void:
	if inventory == null:
		return
	progress = 0
	var discovered: Dictionary = {}
	for bell_id in bell_ids:
		if inventory.call("has_collected", bell_id):
			progress += 1
		for style in METHODS:
			if inventory.call("has_collected", bell_id + "_method_" + style):
				discovered[style] = true
	method_count = discovered.size()
	unlocked = bell_ids.size() > 0 and progress == bell_ids.size() and method_count >= method_threshold
	var gate: Node = get_node_or_null(gate_path)
	if gate != null and gate.has_method("set_open"):
		gate.call("set_open", unlocked)
	queue_redraw()

func _process(delta: float) -> void:
	clock += delta
	queue_redraw()

func _draw() -> void:
	var glow: Color = Color("bfe9dd") if unlocked else Color("efbeda")
	var breathe: float = 0.5 + 0.5 * sin(clock * 1.35)
	draw_circle(Vector2.ZERO, 45.0, Color(glow.r, glow.g, glow.b, 0.08 + 0.04 * breathe))
	draw_arc(Vector2.ZERO, 35.0, clock * 0.1, clock * 0.1 + TAU * 0.97, 58, Color(glow.r,glow.g,glow.b,0.61), 2.4, true)
	var amount: int = maxi(1, bell_ids.size())
	for i in range(amount):
		var p: Vector2 = Vector2.from_angle(float(i) * TAU / float(amount) - PI * 0.5) * 23.0
		draw_circle(p, 5.0, Color("d3ffe5") if i < progress else Color("594b64"))
	if method_threshold > 0:
		draw_arc(Vector2.ZERO, 44.0, -PI*0.5, -PI*0.5 + TAU * float(mini(method_count, method_threshold)) / float(method_threshold), 40, Color("efd49d"), 3.0, true)
	if unlocked:
		draw_circle(Vector2.ZERO, 6.0, Color("ffffff"))
