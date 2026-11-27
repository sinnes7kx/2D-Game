extends "res://scripts/bow_arrow_v126.gd"
## Reuses swept collision and return-hit deduplication; no archery puzzles.
var special_id: String = ""
var throw_charge_v276: float = 0.0
const FX_V273 = preload("res://scripts/fx_intensity_v1924.gd")

func _ready() -> void:
	physical_archery=false
	super._ready()

func contact_stagger_v276() -> float:
	if special_id=="bellthorn_judgment":
		return lerpf(1.45,2.4,throw_charge_v276)
	return lerpf(0.85,1.25,throw_charge_v276)

func confirmed_contact_v276(target: Node, point: Vector2) -> void:
	if special_id=="reliquary_fan" and is_instance_valid(target) and not target.is_queued_for_deletion() and target.has_method("apply_frost_slow"):
		target.call("apply_frost_slow",1.5,0.72)
	if special_id not in ["last_toll","reverie_wave"] and is_instance_valid(caster) and caster.has_method("thrown_impact_v276"):
		caster.call("thrown_impact_v276",point,direction,throw_charge_v276)

func _draw_trail_v273() -> void:
	var alpha: float = clampf(visual_glow_scale,0.0,1.0)*clampf(FX_V273.intensity*0.85,0.0,1.0)
	if alpha<=0.0:
		return
	var points: PackedVector2Array = PackedVector2Array([Vector2.ZERO])
	for point in trail_points:
		points.append(to_local(point))
	for i in range(points.size()-1):
		var u: float = float(i)/float(maxi(1,points.size()-1))
		var fade: float = pow(1.0-u,1.6)*alpha
		var tint: Color = GhostCosmeticRNGV152.sample_palette(full_palette,distance_travelled*0.003-u*0.42,true) if not full_palette.is_empty() else Color("c5c6e7")
		var bright: Color = tint.lerp(Color.WHITE,0.48)
		var width: float = lerpf(1.0,11.0 if returning else 8.0,1.0-u)*(1.0+throw_charge_v276*0.45)
		draw_line(points[i],points[i+1],Color(tint.r,tint.g,tint.b,fade*0.15),width*2.0,true)
		draw_line(points[i],points[i+1],Color(tint.r,tint.g,tint.b,fade*0.62),width*0.7,true)
		draw_line(points[i],points[i+1],Color(bright.r,bright.g,bright.b,fade*0.88),maxf(0.7,width*0.23),true)

func _draw() -> void:
	_draw_trail_v273()
	var axis: Vector2 = direction.normalized()
	var n: Vector2 = axis.orthogonal()
	var tint: Color = full_palette[0] if not full_palette.is_empty() else Color("c5c6e7")
	if special_id in ["roseglass_fan","reliquary_fan"]:
		draw_line(-axis*12.0,axis*16.0,Color("d4b8cb"),2.6,true)
		draw_colored_polygon(PackedVector2Array([-axis*2.0-n*3.0,axis*20.0,-axis*2.0+n*3.0]),Color("f1e2ee"))
		if visual_glow_scale>0.0:
			draw_line(-axis*28.0,axis*12.0,Color(tint.r,tint.g,tint.b,decoration_alpha(0.48)),1.5,true)
		return
	if special_id=="reverie_wave":
		draw_arc(-axis*9.0,29.0,axis.angle()-1.15,axis.angle()+1.15,28,Color("d0c4dd"),2.1,true)
		if visual_glow_scale>0.0:
			draw_arc(-axis*9.0,29.0,axis.angle()-1.1,axis.angle()+1.1,28,Color(tint.r,tint.g,tint.b,decoration_alpha(0.36)),6.0,true)
		return
	if special_id == "last_toll":
		draw_arc(Vector2.ZERO,24.0,axis.angle()-1.15,axis.angle()+1.15,20,Color("c4b29a"),2.0,true)
		if visual_glow_scale > 0.0:
			draw_arc(Vector2.ZERO,28.0,axis.angle()-1.15,axis.angle()+1.15,20,Color(tint.r,tint.g,tint.b,decoration_alpha(0.28)),6.0,true)
		return
	draw_line(-axis*48.0,axis*15.0,Color("362c2c"),4.0,true)
	draw_line(-axis*48.0-n*0.7,axis*15.0-n*0.7,Color("a58b73"),0.9,true)
	var root: Vector2 = axis*10.0
	var tip: Vector2 = axis*30.0
	draw_colored_polygon(PackedVector2Array([root-n*4.5,tip,root+n*4.5,root-axis*5.0]),Color("777b88"))
	draw_colored_polygon(PackedVector2Array([root,tip,root-n*4.5]),Color("d4d7df"))
	if visual_glow_scale > 0.0:
		draw_line(root,tip,Color(tint.r,tint.g,tint.b,decoration_alpha(0.72)),1.6,true)
		draw_line(-axis*54.0,-axis*24.0,Color(tint.r,tint.g,tint.b,decoration_alpha(0.20)),3.0,true)
