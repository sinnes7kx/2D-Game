extends Node2D
## Short-lived, purely cosmetic dagger accents.
const FX = preload("res://scripts/fx_intensity_v1924.gd")
const DURATION: Dictionary = {"hit":0.29,"return_hit":0.35,"wall":0.25,"turn":0.27,"catch":0.31}
var event_kind: String = "hit"
var heading: Vector2 = Vector2.RIGHT
var ink: Color = Color("b7a3d8")
var accent: Color = Color("e1d8ed")
var strength: float = 1.0
var elapsed: float = 0.0

static func opacity(scale_value: float, intensity: float, progress: float) -> float:
	return clampf(scale_value,0.0,1.0)*clampf(intensity*0.70,0.0,1.0)*pow(1.0-clampf(progress,0.0,1.0),2.0)

static func duration_for(kind: String) -> float:
	return float(DURATION.get(kind,0.29))

func _ready() -> void:
	z_index = 31
	heading = Vector2.RIGHT if heading.is_zero_approx() else heading.normalized()
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= duration_for(event_kind):
		queue_free()
	else:
		queue_redraw()

func _colored(color: Color, amount: float) -> Color:
	return Color(color.r,color.g,color.b,clampf(amount,0.0,1.0))

func _draw() -> void:
	var t: float = clampf(elapsed/duration_for(event_kind),0.0,1.0)
	var a: float = opacity(strength,FX.intensity,t)
	if a <= 0.0:
		return
	var eased: float = 1.0-pow(1.0-t,3.0)
	var n: Vector2 = heading.orthogonal()
	var bright: Color = ink.lerp(accent,0.45).lerp(Color.WHITE,0.30)
	var r: float = lerpf(5.0,16.0,eased)
	if event_kind == "hit" or event_kind == "return_hit":
		var recall: bool = event_kind == "return_hit"
		var size: float = 1.22 if recall else 1.0
		draw_circle(Vector2.ZERO,r*size,_colored(ink,a*0.085))
		draw_circle(Vector2.ZERO,r*0.56*size,_colored(ink,a*0.15))
		var slash: PackedVector2Array = PackedVector2Array()
		for i in range(13):
			var u: float = float(i)/12.0
			slash.append(n*(u-0.5)*36.0*size*eased+heading*(sin(u*PI)*7.0-3.0)*size)
		draw_polyline(slash,_colored(ink,a*0.20),5.0,true)
		draw_polyline(slash,_colored(bright,a*0.84),1.25,true)
		for j in range(3 if recall else 2):
			var side: float = -1.0 if j%2==0 else 1.0
			var at: Vector2 = n*side*(5.0+eased*(10.0+float(j)*3.0))+heading*(float(j)-1.0)*7.0*eased
			draw_line(at-heading*3.0,at+heading*2.0,_colored(bright,a*0.68),0.9,true)
	elif event_kind == "wall":
		var stone: Color = Color("c9b9a2").lerp(ink,0.30)
		for i in range(4):
			var v: Vector2 = heading.rotated((float(i)-1.5)*0.46)
			var p: Vector2 = v*(3.0+eased*(10.0+float(i%2)*6.0))
			draw_line(p-v*4.0,p,_colored(stone,a*0.78),1.1,true)
		draw_circle(Vector2.ZERO,r*0.65,_colored(stone,a*0.14))
	else:
		var radius: float = lerpf(4.0,20.0 if event_kind=="turn" else 13.0,eased)
		var angle: float = heading.angle()+eased*0.7
		draw_circle(Vector2.ZERO,radius,_colored(ink,a*0.07))
		draw_arc(Vector2.ZERO,radius,angle-1.6,angle+1.6,24,_colored(ink,a*0.20),4.0,true)
		draw_arc(Vector2.ZERO,radius,angle-1.4,angle+1.4,24,_colored(bright,a*0.72),1.1,true)
		draw_circle(Vector2.ZERO,2.1*(1.0-t),_colored(bright,a*0.8))
