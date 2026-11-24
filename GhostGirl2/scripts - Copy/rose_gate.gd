@tool
extends StaticBody2D
## Editor-placed spectral seal. A linked hook switch opens it permanently.
@export var gate_width: float = 130.0
@export var gate_height: float = 54.0
@export var chest_path: NodePath
@export var open: bool = false
var pulse: float = 0.0

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	set_open(open)

func set_open(value: bool) -> void:
	open = value
	var shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape != null:
		shape.set_deferred("disabled", open)
	# The switch is a real treasure mechanism, not merely a decorative light.
	# Any linked optional chest is interactable only when the seal is released.
	var chest: Node = get_node_or_null(chest_path)
	if chest != null and not Engine.is_editor_hint():
		if open and not bool(chest.get("opened")):
			chest.add_to_group("interactable")
		else:
			chest.remove_from_group("interactable")
	queue_redraw()

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()

func _draw() -> void:
	if open:
		draw_arc(Vector2.ZERO, gate_width * 0.29, 0.0, TAU, 28, Color(0.75, 0.56, 0.80, 0.16), 1.4)
		return
	var glow: float = 0.62 + sin(pulse * 2.0) * 0.12
	var rect: Rect2 = Rect2(-gate_width * 0.5, -gate_height * 0.5, gate_width, gate_height)
	draw_rect(rect, Color(0.14, 0.10, 0.20, 0.76), true)
	draw_rect(rect, Color(0.82, 0.64, 0.78, glow), false, 3.0)
	for i in range(5):
		var x: float = -gate_width * 0.4 + float(i) * gate_width * 0.2
		draw_line(Vector2(x, -gate_height * 0.5), Vector2(x, gate_height * 0.5), Color(0.66, 0.48, 0.68, glow), 2.0)
	draw_circle(Vector2.ZERO, 9.0, Color(0.94, 0.78, 0.90, glow))
