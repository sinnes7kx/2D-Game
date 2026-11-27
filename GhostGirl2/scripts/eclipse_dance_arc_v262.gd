extends Node2D
## Short curved blade wake. Cosmetic only; no secondary hit area.
var ink: Color = Color("b76c84")
var heading: float = 0.0
var strength: float = 1.0
var reverse: bool = false
var elapsed: float = 0.0
func _ready() -> void:
	z_index = 25
func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= 0.34:
		queue_free()
	else:
		queue_redraw()
func _draw() -> void:
	var t: float = clampf(elapsed/0.34,0.0,1.0)
	var radius: float = lerpf(48.0,77.0,t)
	var a: float = heading+t*0.88*(-1.0 if reverse else 1.0)
	var alpha: float = (1.0-t)*(1.0-t)*clampf(strength,0.0,1.0)
	draw_set_transform(Vector2.ZERO,0.0,Vector2(1.0,0.74))
	# Both ends of the twinblade leave paired narrow curved wakes.
	for side in range(2):
		var angle: float = a+float(side)*PI
		var r: float = radius*(1.0 if side==0 else 0.82)
		draw_arc(Vector2.ZERO,r,angle-0.98,angle+0.98,28,Color(ink.r,ink.g,ink.b,alpha*0.08),8.0,true)
		draw_arc(Vector2.ZERO,r,angle-0.90,angle+0.90,28,Color(ink.r,ink.g,ink.b,alpha*0.30),3.0,true)
		var bright: Color = ink.lerp(Color.WHITE,0.38)
		bright.a = alpha*0.60
		draw_arc(Vector2.ZERO,r,angle-0.78,angle+0.78,24,bright,1.2,true)
