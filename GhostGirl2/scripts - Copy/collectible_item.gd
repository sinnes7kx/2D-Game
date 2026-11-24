@tool
extends Node2D
## World pickup placed as editable scene instance in each room.
@export var item_data: GhostItemData
@export var interaction_name: String = "Collect treasure"
@export var pickup_id: String = ""
@export var item_seed: int = 1
@export_range(0.1, 4.0) var aura_scale: float = 1.0
var pulse: float = 0.0

func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group("interactable")
		add_to_group("collectible")

func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()
	if has_node("KeyArt"):
		$KeyArt.position.y = sin(pulse * 2.2) * 3.0

func _draw() -> void:
	var strength: float = 0.22 + 0.10 * sin(pulse * 2.0)
	draw_circle(Vector2.ZERO, 32.0 * aura_scale, Color(0.91, 0.71, 0.99, strength * 0.35))
	draw_arc(Vector2.ZERO, 25.0 * aura_scale, 0, TAU, 32, Color(0.96, 0.81, 0.98, strength), 1.6, true)
