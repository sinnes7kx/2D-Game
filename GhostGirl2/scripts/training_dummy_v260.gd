extends StaticBody2D
## A non-hostile repeatable target. No death, loot, XP or persistent state.
var last_damage: float = 0.0
var total_damage: float = 0.0
var hits: int = 0
var flash: float = 0.0
var reset_left: float = 0.0
var frost_left: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("training_dummies")
	set_meta("arrow_impact_material","wood")
	collision_layer = 16
	collision_mask = 0
	var shape: CollisionShape2D = CollisionShape2D.new()
	var capsule: CapsuleShape2D = CapsuleShape2D.new()
	capsule.radius = 23.0
	capsule.height = 65.0
	shape.shape = capsule
	shape.position = Vector2(0,-29)
	add_child(shape)
	set_process(false)

func hit(damage: float, _poise: float = 1.0) -> void:
	last_damage = maxf(0.0,damage)
	total_damage += last_damage
	hits += 1
	flash = 0.24
	reset_left = 4.0
	set_process(true)
	queue_redraw()

func apply_frost_slow(seconds: float, _factor: float) -> void:
	frost_left = maxf(frost_left,seconds)
	set_process(true)
	queue_redraw()

func spell_aim_point() -> Vector2:
	return global_position + Vector2(0,-31)

func _process(delta: float) -> void:
	flash = maxf(0.0,flash-delta)
	frost_left = maxf(0.0,frost_left-delta)
	reset_left = maxf(0.0,reset_left-delta)
	if reset_left <= 0.0:
		hits = 0
		total_damage = 0.0
		last_damage = 0.0
		if frost_left <= 0.0:
			set_process(false)
	queue_redraw()

func _draw() -> void:
	draw_set_transform(Vector2.ZERO,0.0,Vector2(1.0,0.45))
	draw_circle(Vector2.ZERO,31.0,Color(0.05,0.04,0.07,0.4))
	draw_set_transform(Vector2.ZERO)
	draw_line(Vector2(-25,0),Vector2(25,0),Color("443239"),7.0,true)
	draw_line(Vector2(0,0),Vector2(0,-69),Color("493831"),9.0,true)
	draw_line(Vector2(-2,0),Vector2(-2,-69),Color("9b7960"),2.0,true)
	draw_line(Vector2(-35,-44),Vector2(35,-44),Color("71513d"),9.0,true)
	draw_colored_polygon(PackedVector2Array([Vector2(-22,-55),Vector2(22,-55),Vector2(25,-26),Vector2(0,-14),Vector2(-25,-26)]),Color("5d4b52").lerp(Color("b99c85"),flash*2.7))
	draw_polyline(PackedVector2Array([Vector2(-22,-55),Vector2(22,-55),Vector2(25,-26),Vector2(0,-14),Vector2(-25,-26),Vector2(-22,-55)]),Color("aa8c68"),1.8,true)
	draw_circle(Vector2(0,-39),12.0,Color("3c3039"))
	draw_arc(Vector2(0,-39),10.0,0.0,TAU,32,Color("ae8970"),1.4,true)
	draw_circle(Vector2(0,-39),4.0,Color("a15e63"))
	draw_circle(Vector2(0,-71),12.0,Color("927b69"))
	for y in range(-77,-62,4):
		draw_line(Vector2(-8,y),Vector2(8,y+2),Color("58483f"),1.0,true)
	if frost_left > 0.0:
		draw_arc(Vector2(0,-35),29.0,0.0,TAU,28,Color(0.6,0.84,1.0,0.65),1.2,true)
	var font: Font = ThemeDB.fallback_font
	var title: String = "PRACTICE"
	draw_string(font,Vector2(-font.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x*0.5,-94),title,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("cbbca8"))
	if hits > 0:
		var readout: String = "%.1f · %d hits · %.1f total" % [last_damage,hits,total_damage]
		draw_string(font,Vector2(-font.get_string_size(readout,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x*0.5,-112),readout,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("e5cda0"))
