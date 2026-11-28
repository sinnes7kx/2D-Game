extends Node2D
## Ground contact stays at feet when the character jumps. Shared radial
## texture replaces the old solid ellipse when atmosphere is enabled.
const SETTINGS = preload("res://scripts/atmosphere_settings_v278.gd")
const TEXTURES = preload("res://scripts/atmosphere_textures_v278.gd")
@export var width: float = 23.0
@export var depth: float = 8.0
var lift: float = 0.0
var previous_revision: int = -1
var actor: Node

func _ready() -> void:
	actor=get_parent() if get_parent().has_method("snap_render_after_teleport") else null
	SETTINGS.ensure_loaded()
	queue_redraw()

func _process(_delta: float) -> void:
	var next_lift: float = 0.0
	if is_instance_valid(actor) and float(actor.get("jump_time_left"))>0.0:
		var ratio: float = clampf(float(actor.get("jump_time_left"))/maxf(0.001,float(actor.get("jump_duration"))),0.0,1.0)
		next_lift=sin(ratio*PI)
	if absf(next_lift-lift)>0.008 or previous_revision!=SETTINGS.revision:
		lift=next_lift
		previous_revision=SETTINGS.revision
		queue_redraw()

func _draw() -> void:
	var strength: float = SETTINGS.strength()
	if strength<=0.0:
		var vertices := PackedVector2Array()
		for i in range(32):
			var angle := TAU*float(i)/32.0
			vertices.append(Vector2(cos(angle)*width,sin(angle)*depth))
		draw_colored_polygon(vertices,Color(0.04,0.03,0.10,0.34))
		return
	var spread: float = lerpf(1.0,1.40,lift)
	var outer: Vector2 = Vector2(width*1.52,depth*1.70)*spread
	var core: Vector2 = Vector2(width*0.95,depth*0.86)*spread
	var alpha: float = lerpf(0.51,0.16,lift)
	draw_texture_rect(TEXTURES.shadow(),Rect2(-outer,outer*2.0),false,Color(0.045,0.032,0.075,alpha*0.72))
	draw_texture_rect(TEXTURES.shadow(),Rect2(-core,core*2.0),false,Color(0.035,0.025,0.055,alpha*0.88))
