extends Node2D
const SKILL = preload("res://scripts/seraph_descent_v292.gd")
const SOFT = preload("res://scripts/atmosphere_textures_v278.gd")
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
	var opacity: float = sin(PI*clampf(age/SKILL.DURATION,0.0,1.0))
	var center: Vector2 = Vector2(0,-39-height)
	draw_texture_rect(SOFT.shadow(),Rect2(center-Vector2(95,65),Vector2(190,130)),false,Color(1.0,0.88,0.65,0.12*opacity))
	# Fan-shaped luminous feathers; no extra projectile or damage sources.
	for side in [-1.0,1.0]:
		for i in range(7):
			var t: float = float(i)/6.0
			var root: Vector2 = center+Vector2(float(side)*(8.0+t*9.0),-4.0+t*5.0)
			var tip: Vector2 = center+Vector2(float(side)*(36.0+47.0*(1.0-t))*opacity,-(60.0-48.0*t)*opacity)
			var bend: Vector2 = root.lerp(tip,0.52)+Vector2(float(side)*10.0,-11.0)*opacity
			draw_polyline(PackedVector2Array([root,bend,tip]),Color(1.0,0.89,0.72,opacity*(0.22+0.07*(1.0-t))),5.0-2.0*t,true)
			draw_polyline(PackedVector2Array([root,bend,tip]),Color(1.0,0.96,0.86,opacity*0.68),1.2,true)
	for strike in [SKILL.RISE_HIT,SKILL.FALL_HIT]:
		var elapsed: float = age-float(strike)
		if elapsed>=0.0 and elapsed<0.18:
			var fade: float = 1.0-elapsed/0.18
			var radius: float = 84.0 if strike==SKILL.RISE_HIT else 116.0
			var arc_center: Vector2 = center+axis*16.0
			draw_arc(arc_center,radius,axis.angle()-1.15,axis.angle()+1.15,42,Color(1.0,0.84,0.60,fade*0.23),13.0,true)
			draw_arc(arc_center,radius,axis.angle()-1.15,axis.angle()+1.15,42,Color(1.0,0.96,0.83,fade*0.90),2.6,true)
