extends Node2D
const SKILL = preload("res://scripts/seraph_descent_v292.gd")
const FX = preload("res://scripts/fx_intensity_v1924.gd")
var actor: CharacterBody2D

func _ready() -> void:
	z_index=12

func _process(_delta: float) -> void:
	if not is_instance_valid(actor) or actor.get("seraph_item_v292")==null:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(actor):
		return
	var age: float = float(actor.get("seraph_age_v292"))
	var axis: Vector2 = actor.get("seraph_axis_v292")
	var height: float = SKILL.height_at(age)
	var item: GhostItemInstance = actor.get("seraph_item_v292")
	if item==null:
		return
	var colors: Array[Color] = item.glow_gradient_colors()
	if colors.is_empty():
		return
	var strength: float = preload("res://scripts/visual_choices_v216.gd").effect_scale(item)*FX.intensity
	if strength<=0.0:
		return
	var ink: Color = colors[0]
	var center: Vector2 = Vector2(0,-39-height)
	for strike in [SKILL.RISE_HIT,SKILL.FALL_HIT]:
		var elapsed: float = age-float(strike)
		if elapsed>=0.0 and elapsed<0.18:
			var fade: float = 1.0-elapsed/0.18
			var radius: float = 84.0 if strike==SKILL.RISE_HIT else 116.0
			var arc_center: Vector2 = center+axis*16.0
			draw_arc(arc_center,radius,axis.angle()-1.15,axis.angle()+1.15,42,Color(ink.r,ink.g,ink.b,fade*0.23*strength),13.0,true)
			draw_arc(arc_center,radius,axis.angle()-1.15,axis.angle()+1.15,42,Color(ink.r,ink.g,ink.b,fade*0.90*strength),2.6,true)
