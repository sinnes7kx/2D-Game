extends Node2D
var actor: CharacterBody2D
var mode: String = "spin"
var ink: Color = Color("e1bedf")
func _ready() -> void:
	z_index=16
func _process(_delta: float) -> void:
	if not is_instance_valid(actor) or str(actor.get("relic_channel_v288"))!=mode:
		queue_free()
		return
	queue_redraw()
func _draw() -> void:
	if not is_instance_valid(actor):
		return
	var angle: float = float(actor.get("relic_spin_angle_v288"))
	var age: float = float(actor.get("relic_channel_age_v288"))
	if mode=="spin":
		for i in range(2):
			var a: float = angle+PI*float(i)
			draw_arc(Vector2(0,-26),91.0,a-1.10,a,28,Color(ink.r,ink.g,ink.b,0.22),9.0,true)
			draw_arc(Vector2(0,-26),91.0,a-0.80,a,22,Color(ink.r,ink.g,ink.b,0.87),2.1,true)
		return
	var build: float = clampf(age/0.85,0.0,1.0)
	for layer in range(5):
		var h: float = float(layer)/4.0
		var radius: float = lerpf(47.0,117.0,h)*lerpf(0.65,1.0,build)
		var center: Vector2 = Vector2(0,-12.0-h*91.0)
		for strand in range(2):
			var phase: float = angle*(0.78+h*0.40)+h*2.7+PI*float(strand)
			var points: PackedVector2Array = PackedVector2Array()
			for i in range(30):
				var t: float = float(i)/29.0
				var a: float = phase-t*2.5
				points.append(center+Vector2(cos(a)*radius,sin(a)*radius*0.36+t*14.0))
			draw_polyline(points,Color(ink.r,ink.g,ink.b,0.14+build*0.12),8.0-3.0*h,true)
			draw_polyline(points,Color(ink.r,ink.g,ink.b,0.55+build*0.23),1.7,true)
