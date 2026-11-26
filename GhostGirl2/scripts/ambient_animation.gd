@tool
extends Node2D
const PERF_V230 = preload("res://scripts/performance_profiles_v230.gd")
var redraw_clock: float = 0.0
var last_profile_revision: int = -1
## Small, reusable atmospheric object; place instances anywhere in the room.
@export_range(0.0, 1.0, 0.01) var flicker_strength: float = 0.12
@export var phase_offset: float = 0.0
@onready var light_node: PointLight2D = get_node_or_null("PointLight2D") as PointLight2D
var clock: float = 0.0
func _process(delta: float) -> void:
	clock += delta
	if light_node == null:
		return
	redraw_clock += delta
	var hz: float = 0.0 if Engine.is_editor_hint() else PERF_V230.ambient_hz()
	if last_profile_revision != PERF_V230.revision or PERF_V230.due(redraw_clock, hz):
		last_profile_revision = PERF_V230.revision
		redraw_clock = PERF_V230.remainder(redraw_clock, hz)
		light_node.energy = 0.78 + flicker_strength * sin(clock * 3.7 + phase_offset)
