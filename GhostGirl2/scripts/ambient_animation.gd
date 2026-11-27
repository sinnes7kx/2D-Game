@tool
extends Node2D
const ATMOSPHERE = preload("res://scripts/atmosphere_settings_v278.gd")
const PERF_V230 = preload("res://scripts/performance_profiles_v230.gd")
var redraw_clock: float = 0.0
var last_profile_revision: int = -1
## Small, reusable atmospheric object; place instances anywhere in the room.
@export_range(0.0, 1.0, 0.01) var flicker_strength: float = 0.12
@export var phase_offset: float = 0.0
@onready var light_node: PointLight2D = get_node_or_null("PointLight2D") as PointLight2D
var clock: float = 0.0
var original_scale: float = 1.0
var original_color: Color = Color.WHITE
var atmosphere_revision: int = -1

func _ready() -> void:
	if light_node!=null:
		original_scale=light_node.texture_scale
		original_color=light_node.color

func _process(delta: float) -> void:
	clock += delta
	if light_node == null:
		return
	redraw_clock += delta
	var hz: float = 0.0 if Engine.is_editor_hint() else PERF_V230.ambient_hz()
	if atmosphere_revision!=ATMOSPHERE.revision and not Engine.is_editor_hint():
		atmosphere_revision=ATMOSPHERE.revision
		var strength: float = ATMOSPHERE.strength()
		light_node.texture_scale=original_scale*(1.0+0.25*strength)
		light_node.color=original_color.lerp(Color("ffce99"),0.22*strength)
	if last_profile_revision != PERF_V230.revision or PERF_V230.due(redraw_clock, hz):
		last_profile_revision = PERF_V230.revision
		redraw_clock = PERF_V230.remainder(redraw_clock, hz)
		light_node.energy = 0.78 + flicker_strength * sin(clock * 3.7 + phase_offset)
