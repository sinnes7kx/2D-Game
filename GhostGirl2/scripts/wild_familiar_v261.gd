extends "res://scripts/collectible_item.gd"
## One-time, approachable catch, using the existing seeded companion slot.
func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		add_to_group("wild_familiar_v261")

func _draw() -> void:
	var y: float = -42.0 + sin(pulse*1.45)*5.0
	var center: Vector2 = Vector2(0,y)
	var hue: Color = Color.from_hsv(fposmod(float(item_seed)*0.137,1.0),0.32,0.93)
	draw_circle(center,22.0,Color(hue.r,hue.g,hue.b,0.045))
	draw_circle(center,12.0,Color(hue.r,hue.g,hue.b,0.13))
	var wing: float = 0.65+0.35*sin(pulse*3.0)
	for side in [-1.0,1.0]:
		var points: PackedVector2Array = PackedVector2Array([center,center+Vector2(side*17.0*wing,-8),center+Vector2(side*12.0*wing,6),center+Vector2(side*3.0,8)])
		draw_colored_polygon(points,Color(hue.r,hue.g,hue.b,0.62))
		draw_polyline(points,hue.lightened(0.25),0.7,true)
	draw_circle(center,4.0,hue.lightened(0.35))
	draw_circle(center,1.7,Color("eee3cf"))
	draw_arc(Vector2.ZERO,15.0,0.0,TAU,24,Color(hue.r,hue.g,hue.b,0.26),0.7,true)
