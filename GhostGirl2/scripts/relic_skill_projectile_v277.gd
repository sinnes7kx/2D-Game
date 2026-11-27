extends "res://scripts/bow_arrow_v126.gd"
## One swept projectile and one existing per-target hit ledger. No puzzle
## events, new collision masks or unbounded secondary chain reactions.
const FX277 = preload("res://scripts/fx_intensity_v1924.gd")
const IMPACT277 = preload("res://scripts/impact_spawner_v149.gd")
var profile: Dictionary = {}
var rewarded: bool = false

func _ready() -> void:
	physical_archery=false
	super._ready()

func contact_stagger_v276() -> float:
	return float(profile.get("stagger",0.85))

func confirmed_contact_v276(target: Node, point: Vector2) -> void:
	var effect: String = str(profile.get("effect","none"))
	if not is_instance_valid(caster):
		return
	if effect.begins_with("frost") and is_instance_valid(target) and not target.is_queued_for_deletion() and target.has_method("apply_frost_slow"):
		target.call("apply_frost_slow",1.6,0.72)
	if not rewarded:
		rewarded=true
		var world: Node = caster.get("world")
		if effect=="heal" and caster.has_method("maximum_health"):
			caster.set("health",minf(float(caster.get("health"))+3.0,float(caster.call("maximum_health"))))
			if world!=null:
				world.ui.set_health(caster.get("health"),caster.call("maximum_health"))
		elif effect=="stamina":
			caster.set("stamina",minf(float(caster.get("stamina"))+1.5,100.0))
			if world!=null:
				world.ui.set_stamina(caster.get("stamina"),100.0)
		elif effect=="burst":
			_burst_neighbors(target,point)
	if caster.has_method("thrown_impact_v276"):
		caster.call("thrown_impact_v276",point,direction,0.55)

func _burst_neighbors(primary: Node, point: Vector2) -> void:
	var hits: int = 0
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	for other in get_tree().get_nodes_in_group("enemies"):
		if hits>=3:
			break
		if not is_instance_valid(other) or other==primary or other.is_queued_for_deletion() or not other is Node2D or not other.has_method("hit"):
			continue
		var at: Vector2 = (other as Node2D).global_position+Vector2(0,-24)
		if at.distance_squared_to(point)>75.0*75.0:
			continue
		var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(point,at,6,[caster_rid])
		if not space.intersect_ray(ray).is_empty():
			continue
		other.call("hit",damage*0.28,0.55)
		hits+=1
	IMPACT277.burst(get_tree().current_scene,point,"slam",0.95,direction,roundi(point.x+point.y))

func _draw() -> void:
	var axis: Vector2 = direction.normalized()
	var n: Vector2 = axis.orthogonal()
	var ink: Color = Color(str(profile.get("ink","c7b5e5")))
	var alpha: float = clampf(visual_glow_scale*FX277.intensity,0.0,1.0)
	var pattern: String = str(profile.get("pattern","single"))
	var wave: bool = pattern in ["radial","wave"]
	if alpha>0.0:
		for i in range(trail_points.size()-1):
			var u: float = float(i)/float(maxi(1,trail_points.size()-1))
			var a: float = (1.0-u)*alpha
			var start: Vector2 = to_local(trail_points[i])
			var end: Vector2 = to_local(trail_points[i+1])
			draw_line(start,end,Color(ink.r,ink.g,ink.b,a*0.18),9.0*(1.0-u)+1.0,true)
			draw_line(start,end,Color(ink.r,ink.g,ink.b,a*0.65),2.0,true)
	if wave:
		draw_arc(Vector2.ZERO,20.0 if pattern=="radial" else 29.0,axis.angle()-0.95,axis.angle()+0.95,20,ink,2.2,true)
		if alpha>0.0:
			draw_arc(Vector2.ZERO,26.0,axis.angle()-1.0,axis.angle()+1.0,20,Color(ink.r,ink.g,ink.b,alpha*0.35),5.0,true)
		return
	draw_line(-axis*23.0,axis*13.0,ink.darkened(0.35),2.0,true)
	draw_colored_polygon(PackedVector2Array([axis*20.0,-axis*2.0+n*4.0,axis*2.0,-axis*2.0-n*4.0]),ink.lightened(0.30))
	draw_line(-axis*15.0,axis*15.0,ink.lightened(0.48),0.9,true)
