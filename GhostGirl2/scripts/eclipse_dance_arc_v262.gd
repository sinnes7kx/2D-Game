extends Node2D
## Short curved blade wake. Cosmetic only; no secondary hit area.
var ink: Color = Color("b76c84")
var heading: float = 0.0
var strength: float = 1.0
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
	var radius: float = lerpf(56.0,94.0,t)
	var a: float = heading+t*0.88
	var alpha: float = (1.0-t)*clampf(strength,0.0,1.0)
	draw_set_transform(Vector2.ZERO,0.0,Vector2(1.0,0.66))
	draw_arc(Vector2.ZERO,radius,a-1.10,a+1.10,36,Color(ink.r,ink.g,ink.b,alpha*0.08),12.0,true)
	draw_arc(Vector2.ZERO,radius,a-1.02,a+1.02,36,Color(ink.r,ink.g,ink.b,alpha*0.34),4.0,true)
	var bright: Color = ink.lerp(Color.WHITE,0.38)
	bright.a = alpha*0.66
	draw_arc(Vector2.ZERO,radius,a-0.90,a+0.90,32,bright,1.3,true)
