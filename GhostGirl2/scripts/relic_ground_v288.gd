extends Node2D
## Ground eruptions and physical ring impacts: no projectile instances.
const AUDIO = preload("res://scripts/combat_juice_v194.gd")
const IMPACT = preload("res://scripts/impact_spawner_v149.gd")
var caster: CharacterBody2D
var kind: String = "impale"
var axis: Vector2 = Vector2.RIGHT
var power: float = 20.0
var ink: Color = Color("e9cfb8")
var age: float = 0.0
var spots: PackedVector2Array = PackedVector2Array()
var emitted: int = 0
var hit_ids: Dictionary = {}
var ring_radius: float = 0.0
const STEP: float = 0.14
const FIRST: float = 0.27
const BELL_FIRST: float = 0.55
const BELL_STEP: float = 0.42
const RING_SPEED: float = 420.0
const RING_MAX: float = 235.0

static func clear_path(actor: CharacterBody2D,from: Vector2,to: Vector2) -> bool:
	if from.distance_squared_to(to)<1.0:
		return true
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from,to,6,[actor.get_rid()])
	return actor.get_world_2d().direct_space_state.intersect_ray(query).is_empty()

# A physical double-ended blade contacts only where its two edges have
# swept during this physics step. The cyclone uses the full disk instead.
static func blade_sweep_contact(offset: Vector2,angle: float,travel: float,radius: float,width: float) -> bool:
	var distance: float = offset.length()
	if distance>radius:
		return false
	if distance<=width:
		return true
	var margin: float = asin(clampf(width/distance,0.0,1.0))
	var relative: float = fposmod(offset.angle()-angle,PI)
	return relative<=maxf(0.0,travel)+margin or relative>=PI-margin

static func hit_spin(actor: CharacterBody2D,angle: float,travel: float,radius: float,damage: float,age: float,ledger: Dictionary,interval: float) -> int:
	var hits: int = 0
	for other in actor.get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(other) or other.is_queued_for_deletion() or not other is Node2D or not other.has_method("hit"):
			continue
		var point: Vector2 = (other as Node2D).global_position
		var key: int = other.get_instance_id()
		if age<float(ledger.get(key,0.0)) or not blade_sweep_contact(point-actor.global_position,angle,travel,radius,18.0):
			continue
		if not clear_path(actor,actor.global_position,point):
			continue
		ledger[key]=age+interval
		other.call("hit",damage,0.45)
		hits+=1
	return hits

static func hit_disk(actor: CharacterBody2D,center: Vector2,radius: float,damage: float,poise: float,ledger: Dictionary,slow: bool=false,inner: float=0.0) -> int:
	if not is_instance_valid(actor) or not actor.is_inside_tree():
		return 0
	var count: int = 0
	for other in actor.get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(other) or other.is_queued_for_deletion() or not other is Node2D or not other.has_method("hit"):
			continue
		var point: Vector2 = (other as Node2D).global_position
		var d: float = point.distance_squared_to(center)
		if d>radius*radius or d<inner*inner or ledger.has(other.get_instance_id()):
			continue
		if not clear_path(actor,center,point) or not clear_path(actor,actor.global_position,point):
			continue
		ledger[other.get_instance_id()]=true
		other.call("hit",damage,poise)
		if slow and is_instance_valid(other) and not other.is_queued_for_deletion() and other.has_method("apply_frost_slow"):
			other.call("apply_frost_slow",1.3,0.70)
		count+=1
	return count

func configure(actor: CharacterBody2D,mode: String,direction: Vector2,damage: float,color: Color) -> void:
	caster=actor
	kind=mode
	axis=direction.normalized() if not direction.is_zero_approx() else Vector2.DOWN
	power=damage
	ink=color

func _ready() -> void:
	z_index=12
	if kind=="bells":
		for offset in [Vector2(130,0),Vector2(222,-83),Vector2(222,83)]:
			var at: Vector2 = global_position+offset.rotated(axis.angle())
			if clear_path(caster,global_position,at):
				spots.append(to_local(at))
	elif kind=="impale" or kind=="fissure":
		var gap: float = 61.0 if kind=="impale" else 83.0
		for i in range(6 if kind=="impale" else 4):
			var at: Vector2 = global_position+axis*(55.0+gap*float(i))
			if not clear_path(caster,global_position,at):
				break
			spots.append(to_local(at))
	else:
		spots.append(Vector2.ZERO)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(caster) or not caster.is_inside_tree():
		queue_free()
		return
	if caster.get("world").ui.is_menu_open():
		return
	age+=delta
	if kind=="ring":
		var prev: float = ring_radius
		ring_radius=clampf((age-FIRST)*RING_SPEED,0.0,RING_MAX)
		if age>=FIRST and ring_radius>prev:
			var hits: int = hit_disk(caster,global_position,ring_radius+18.0,power,2.4,hit_ids,false,maxf(0.0,prev-18.0))
			if hits>0:
				caster.set("camera_kick",maxf(float(caster.get("camera_kick")),4.2))
		if age>=FIRST+RING_MAX/RING_SPEED+0.25:
			queue_free()
	elif kind=="bells":
		while emitted<spots.size() and age>=BELL_FIRST+BELL_STEP*float(emitted):
			var point: Vector2 = to_global(spots[emitted])
			var hits: int = hit_disk(caster,point,70.0,power*0.72,2.1,{})
			AUDIO.play(get_parent(),point,"ground_slam",-14.0)
			IMPACT.burst(get_parent(),point,"slam",1.25,axis,emitted+289)
			if hits>0:
				caster.set("camera_kick",maxf(float(caster.get("camera_kick")),5.0))
			emitted+=1
		if age>BELL_FIRST+BELL_STEP*float(spots.size())+0.5:
			queue_free()
	else:
		while emitted<spots.size() and age>=FIRST+STEP*float(emitted):
			var point: Vector2 = to_global(spots[emitted])
			var hits: int = hit_disk(caster,point,47.0 if kind=="impale" else 68.0,power,1.55 if kind=="impale" else 2.8,hit_ids)
			AUDIO.play(get_parent(),point,"arrow_metal" if kind=="impale" else "ground_slam",-19.0)
			IMPACT.burst(get_parent(),point,"stone" if kind=="impale" else "slam",0.7,axis,emitted+288)
			if hits>0:
				caster.set("camera_kick",maxf(float(caster.get("camera_kick")),3.7))
			emitted+=1
		if age>FIRST+STEP*float(spots.size())+0.65:
			queue_free()
	queue_redraw()

func _draw() -> void:
	if kind=="bells":
		for i in range(spots.size()):
			var p: Vector2 = spots[i]
			var t: float = age-BELL_FIRST-BELL_STEP*float(i)
			if t < -0.5 or t>0.42:
				continue
			var fade: float = 1.0-clampf(t/0.42,0.0,1.0)
			var fall: float = clampf((t+0.5)/0.5,0.0,1.0)
			var center: Vector2 = p+Vector2(0,-190.0*(1.0-fall*fall)-23.0)
			draw_arc(p,70.0,0.0,TAU,48,Color(ink.r,ink.g,ink.b,0.4*fade),2.0,true)
			var contour: PackedVector2Array = PackedVector2Array([center+Vector2(-31,19),center+Vector2(-23,5),center+Vector2(-18,-29),center+Vector2(-10,-39),center+Vector2(10,-39),center+Vector2(18,-29),center+Vector2(23,5),center+Vector2(31,19)])
			draw_colored_polygon(contour,Color(0.35,0.26,0.22,0.88*fade))
			draw_polyline(contour,Color(ink.r,ink.g,ink.b,fade),2.1,true)
			draw_line(center+Vector2(-31,19),center+Vector2(31,19),Color(ink.r,ink.g,ink.b,fade),5.0,true)
			draw_line(center+Vector2(0,-44),center+Vector2(0,-53),Color(ink.r,ink.g,ink.b,fade),4.0,true)
			draw_circle(center+Vector2(0,24),5.0,Color(ink.r,ink.g,ink.b,fade))
			if t>=0.0:
				draw_arc(p,70.0*clampf(t/0.32,0.0,1.0),0.0,TAU,48,Color(ink.r,ink.g,ink.b,fade),4.0,true)
		return
	if kind=="ring":
		var radius: float = ring_radius if age>=FIRST else RING_MAX
		var alpha: float = 0.65 if age>=FIRST else 0.20
		draw_arc(Vector2.ZERO,radius,0.0,TAU,96,Color(ink.r,ink.g,ink.b,alpha*0.25),25.0,true)
		draw_arc(Vector2.ZERO,radius,0.0,TAU,96,Color(ink.r,ink.g,ink.b,alpha),3.0,true)
		if age>=FIRST:
			for i in range(24):
				var angle: float = TAU*float(i)/24.0
				var n: Vector2 = Vector2.from_angle(angle)
				draw_line(n*(radius-12.0),n*(radius+10.0),Color(ink.r,ink.g,ink.b,alpha),1.6,true)
		return
	for i in range(spots.size()):
		var p: Vector2 = spots[i]
		var t: float = age-FIRST-STEP*float(i)
		if t<0.0:
			draw_arc(p,38.0 if kind=="impale" else 57.0,0.0,TAU,36,Color(ink.r,ink.g,ink.b,0.25),1.3,true)
			continue
		if t>0.58:
			continue
		var fade: float = 1.0-clampf((t-0.18)/0.40,0.0,1.0)
		var rise: float = clampf(t/0.075,0.02,1.0)
		if kind=="impale":
			var tip: Vector2 = p+Vector2(axis.x*18.0,-96.0)*rise
			var direction: Vector2 = (tip-p).normalized()
			var normal: Vector2 = direction.orthogonal()
			var head: Vector2 = p.lerp(tip,0.69)
			draw_line(p,head,Color(0.28,0.19,0.26,fade),5.0,true)
			draw_line(p,head,Color(ink.r,ink.g,ink.b,fade),2.0,true)
			draw_colored_polygon(PackedVector2Array([head-normal*7.0,tip,head+normal*7.0]),Color(ink.r,ink.g,ink.b,fade))
			draw_line(head,tip,Color(1.0,0.96,0.88,fade),1.6,true)
			draw_line(p-Vector2(12,9),p+Vector2(12,9),Color(ink.r,ink.g,ink.b,fade*0.8),3.0,true)
			draw_arc(p,35.0*rise,0.0,TAU,32,Color(ink.r,ink.g,ink.b,fade*0.55),2.0,true)
		else:
			var n: Vector2 = axis.orthogonal()
			draw_polyline(PackedVector2Array([p-axis*35.0,p-axis*12.0+n*12.0,p+axis*7.0-n*9.0,p+axis*35.0]),Color(ink.r,ink.g,ink.b,fade),4.0,true)
			for j in range(6):
				var dir: Vector2 = Vector2.from_angle(float(j)*TAU/6.0+float(i))
				var at: Vector2 = p+dir*45.0*rise
				draw_line(at,at+Vector2(0,-18.0*fade),Color(ink.r,ink.g,ink.b,fade),2.0,true)
