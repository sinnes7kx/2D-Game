extends "res://scripts/bow_arrow_v126.gd"
## Reuses swept collision and return-hit deduplication; no archery puzzles.
var special_id: String = ""

func _draw() -> void:
	var axis: Vector2 = direction.normalized()
	var n: Vector2 = axis.orthogonal()
	var tint: Color = full_palette[0] if not full_palette.is_empty() else Color("c5c6e7")
	if special_id == "last_toll":
		draw_arc(Vector2.ZERO,24.0,axis.angle()-1.15,axis.angle()+1.15,20,Color("c4b29a"),2.0,true)
		if visual_glow_scale > 0.0:
			draw_arc(Vector2.ZERO,28.0,axis.angle()-1.15,axis.angle()+1.15,20,Color(tint.r,tint.g,tint.b,0.28),6.0,true)
		return
	draw_line(-axis*48.0,axis*15.0,Color("362c2c"),4.0,true)
	draw_line(-axis*48.0-n*0.7,axis*15.0-n*0.7,Color("a58b73"),0.9,true)
	var root: Vector2 = axis*10.0
	var tip: Vector2 = axis*30.0
	draw_colored_polygon(PackedVector2Array([root-n*4.5,tip,root+n*4.5,root-axis*5.0]),Color("777b88"))
	draw_colored_polygon(PackedVector2Array([root,tip,root-n*4.5]),Color("d4d7df"))
	if visual_glow_scale > 0.0:
		draw_line(root,tip,Color(tint.r,tint.g,tint.b,0.72),1.6,true)
		draw_line(-axis*54.0,-axis*24.0,Color(tint.r,tint.g,tint.b,0.20),3.0,true)
