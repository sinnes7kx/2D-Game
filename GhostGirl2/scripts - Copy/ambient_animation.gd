@tool
extends Node2D
## Small, reusable atmospheric object; place instances anywhere in the room.
@export_range(0.0, 1.0, 0.01) var flicker_strength: float = 0.12
@export var phase_offset: float = 0.0
@onready var light_node: PointLight2D = get_node_or_null("PointLight2D") as PointLight2D
var clock: float = 0.0
func _process(delta: float) -> void:
	clock += delta
	if light_node != null:
		light_node.energy = 0.78 + flicker_strength * sin(clock * 3.7 + phase_offset)
