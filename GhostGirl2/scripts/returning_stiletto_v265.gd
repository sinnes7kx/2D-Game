extends Node2D
## A narrow spectral dagger. Independent hit ledgers per flight leg.
## No arrow puzzles, no damage from visual trails, no changes to other returns.
const AUDIO = preload("res://scripts/arrow_impact_audio_v233.gd")
const COMBAT_AUDIO = preload("res://scripts/combat_juice_v194.gd")
const FX = preload("res://scripts/fx_intensity_v1924.gd")
const IMPACT = preload("res://scripts/stiletto_fx_v267.gd")
const TRAIL_LIMIT: int = 18
const TRAIL_STEP: float = 9.0
const OUT_SPEED: float = 860.0
const RETURN_SPEED: float = 1040.0
const OUT_RANGE: float = 390.0
const RETURN_RANGE: float = 980.0
const OUT_POWER: float = 0.72
const RETURN_POWER: float = 0.65
const MAX_TARGETS_PER_LEG: int = 4
var ember_v272: bool = false
var special_id_v276: String = ""
var throw_charge_v276: float = 0.0
var healed_v276: bool = false
var caster: CharacterBody2D
var direction: Vector2 = Vector2.RIGHT
var power: float = 20.0
var palette: Array[Color] = []
var glow: float = 1.0
var returning: bool = false
var remaining: float = OUT_RANGE
var outbound_hits: Dictionary = {}
var return_hits: Dictionary = {}
var traveled: float = 0.0
var trail: Array[Vector2] = []
var trail_carry: float = 0.0
var _shape: CircleShape2D = CircleShape2D.new()

func _ready() -> void:
	z_index = 30
	direction = direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT
	_shape.radius = 6.0
	remaining=OUT_RANGE*lerpf(0.85,1.15,throw_charge_v276)

func register_contact(id: int) -> bool:
	var ledger: Dictionary = return_hits if returning else outbound_hits
	if ledger.has(id) or ledger.size() >= MAX_TARGETS_PER_LEG:
		return false
	ledger[id] = true
	return true

func begin_return() -> void:
	if returning:
		return
	returning = true
	remaining = RETURN_RANGE
	trail.clear()
	trail_carry = 0.0
	if is_inside_tree():
		trail.append(global_position)
		_emit_fx("turn",global_position,-direction)
		COMBAT_AUDIO.play(get_tree().current_scene,global_position,"dagger_swing",-23.0)

func damage_now() -> float:
	return power * (RETURN_POWER if returning else OUT_POWER) * (1.10 if ember_v272 else 1.0)

func _catch_point() -> Vector2:
	var body: AnimatedSprite2D = caster.get_node_or_null("Ghost") as AnimatedSprite2D
	if body != null:
		var rig: Node = body.get_node_or_null("WeaponPoseV172")
		if rig != null and rig.has_method("get_weapon_span"):
			var span: PackedVector2Array = rig.call("get_weapon_span",str(body.animation),body.frame)
			if span.size()==2:
				return body.to_global(span[0])
	return caster.global_position+Vector2(0,-39)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(caster) or not caster.is_inside_tree() or caster.is_queued_for_deletion():
		queue_free()
		return
	var speed: float = (RETURN_SPEED if returning else OUT_SPEED*lerpf(0.88,1.18,throw_charge_v276))*0.88
	var travel: float = minf(remaining,speed*delta)
	var caught: bool = false
	if returning:
		var toward: Vector2 = _catch_point()-global_position
		var distance: float = toward.length()
		if distance <= 6.0:
			_emit_fx("catch",_catch_point(),direction)
			queue_free()
			return
		direction = toward/distance
		caught = distance<=travel
		travel = minf(travel,distance)
	if travel <= 0.0:
		queue_free()
		return
	var start: Vector2 = global_position
	var destination: Vector2 = start+direction*travel
	var state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var wall_query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(start,destination)
	wall_query.collision_mask = 6
	wall_query.exclude = [caster.get_rid()]
	var wall: Dictionary = state.intersect_ray(wall_query)
	# Keep the dagger center on the free side of the impact plane. A return
	# never tunnels through cover, even when the owner moves behind a wall.
	var end: Vector2 = destination
	if not wall.is_empty():
		var contact: Vector2 = wall["position"]
		end = start+direction*maxf(0.0,start.distance_to(contact)-7.0)
	var steps: int = maxi(1,ceili(start.distance_to(end)/5.0))
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = _shape
	query.collision_mask = 16|32
	query.collide_with_areas = true
	query.exclude = [caster.get_rid()]
	for i in range(steps+1):
		var point: Vector2 = start.lerp(end,float(i)/float(steps))
		query.transform = Transform2D(0.0,point)
		for record in state.intersect_shape(query,12):
			var target: Node = record.get("collider") as Node
			if target is Area2D:
				target = target.get_parent()
			if not is_instance_valid(target) or not target is Node2D or target.is_queued_for_deletion() or not target.is_in_group("enemies") or not target.has_method("hit"):
				continue
			# A target overlapping a wall must not take a hit through it.
			var line: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(point,(target as Node2D).global_position+Vector2(0,-28))
			line.collision_mask = 6
			line.exclude = [caster.get_rid()]
			if not state.intersect_ray(line).is_empty():
				continue
			if not register_contact(target.get_instance_id()):
				continue
			var material: String = AUDIO.material_for(target,"flesh")
			target.call("hit",damage_now(),lerpf(0.55,0.95,throw_charge_v276))
			if special_id_v276=="winter_return" and is_instance_valid(target) and not target.is_queued_for_deletion() and target.has_method("apply_frost_slow"):
				target.call("apply_frost_slow",1.8,0.65)
			if special_id_v276=="ivory_return" and not healed_v276:
				healed_v276=true
				caster.set("health",minf(float(caster.call("maximum_health")),float(caster.get("health"))+3.0))
				var world: Node = caster.get("world")
				if world!=null and world.get("ui")!=null:
					world.get("ui").call("set_health",caster.get("health"),caster.call("maximum_health"))
			if caster.has_method("thrown_impact_v276"):
				caster.call("thrown_impact_v276",point,direction,throw_charge_v276)
			AUDIO.play(get_tree().current_scene,point,material,false)
			_emit_fx("return_hit" if returning else "hit",point,direction)
	global_position = end
	remaining -= travel
	traveled += start.distance_to(end)
	_record_trail(start,end)
	queue_redraw()
	if not wall.is_empty():
		var surface: Object = wall.get("collider")
		if ember_v272 and is_instance_valid(surface) and surface.has_method("ignite_from_environment"):
			surface.call("ignite_from_environment")
		AUDIO.play(get_tree().current_scene,end,AUDIO.material_for(surface,"stone"),false)
		_emit_fx("wall",end,wall.get("normal",-direction))
		if returning:
			queue_free()
		else:
			begin_return()
	elif returning and caught:
		_emit_fx("catch",end,direction)
		queue_free()
	elif remaining<=0.0:
		if returning:
			queue_free()
		else:
			begin_return()

# Distance-sampled history, bounded independently of frame rate.
func _record_trail(start: Vector2,end: Vector2) -> void:
	if trail.is_empty():
		trail.push_front(start)
	var distance: float = start.distance_to(end)
	if distance <= 0.001:
		return
	var at: float = TRAIL_STEP-trail_carry
	while at <= distance:
		trail.push_front(start.lerp(end,at/distance))
		if trail.size()>TRAIL_LIMIT:
			trail.pop_back()
		at += TRAIL_STEP
	trail_carry = fposmod(trail_carry+distance,TRAIL_STEP)

func _palette_at(u: float) -> Color:
	var color: Color = GhostCosmeticRNGV152.sample_palette(palette,u,true) if not palette.is_empty() else Color("b7a3d8")
	if special_id_v276=="winter_return":
		return color.lerp(Color("9be9f5"),0.48)
	if special_id_v276=="ivory_return":
		return color.lerp(Color("f5e1b5"),0.48)
	return color.lerp(Color("ee8a49"),0.66) if ember_v272 else color

func _emit_fx(kind: String,where: Vector2,axis: Vector2) -> void:
	if glow<=0.0 or FX.intensity<=0.0 or not is_inside_tree():
		return
	var root: Node = get_tree().current_scene
	if root==null:
		return
	var burst = IMPACT.new()
	burst.event_kind = kind
	burst.heading = axis
	burst.ink = _palette_at(traveled*0.003)
	burst.accent = _palette_at(traveled*0.003+0.29)
	burst.strength = glow
	root.add_child(burst)
	burst.global_position = where
	if root.has_method("track_room_effect"):
		root.call("track_room_effect",burst)

func _draw_ribbon() -> void:
	var alpha: float = clampf(glow,0.0,1.0)*clampf(FX.intensity*0.70,0.0,1.0)
	if alpha<=0.0 or trail.is_empty():
		return
	var points: PackedVector2Array = PackedVector2Array([Vector2.ZERO])
	for p in trail:
		points.append(to_local(p))
	for i in range(points.size()-1):
		var u: float = float(i)/float(points.size()-1)
		var fade: float = pow(1.0-u,1.8)*alpha
		var width: float = lerpf(1.0,11.0 if returning else 7.5,1.0-u)
		var ink: Color = _palette_at(traveled*0.003-u*0.36)
		var edge: Color = ink.lerp(Color.WHITE,0.32)
		draw_line(points[i],points[i+1],Color(ink.r,ink.g,ink.b,fade*0.11),width*1.65,true)
		draw_line(points[i],points[i+1],Color(ink.r,ink.g,ink.b,fade*(0.72 if returning else 0.56)),width*0.68,true)
		draw_line(points[i],points[i+1],Color(edge.r,edge.g,edge.b,fade*(0.92 if returning else 0.76)),maxf(0.65,width*0.20),true)
	if returning and points.size()>6:
		for j in range(2):
			var idx: int = 3+j*3
			if idx+2>=points.size():
				continue
			var p: Vector2 = points[idx]
			var axis: Vector2 = (points[idx-1]-p).normalized()
			var n: Vector2 = axis.orthogonal()*(-1.0 if j==0 else 1.0)
			var ink: Color = _palette_at(traveled*0.003+float(j)*0.21)
			var wisp: PackedVector2Array = PackedVector2Array([p,p-axis*5.0+n*2.6,points[idx+2]+n*4.0])
			draw_polyline(wisp,Color(ink.r,ink.g,ink.b,alpha*0.14),2.8,true)
			draw_polyline(wisp,Color(ink.r,ink.g,ink.b,alpha*0.32),0.85,true)

func _draw() -> void:
	var axis: Vector2 = direction
	var n: Vector2 = axis.orthogonal()
	var tint: Color = GhostCosmeticRNGV152.sample_palette(palette,traveled*0.003,true) if not palette.is_empty() else Color("b7a3d8")
	var fade: float = clampf(glow,0.0,1.0)*clampf(FX.intensity*0.70,0.0,1.0)
	_draw_ribbon()
	var grip: Vector2 = -axis*12.0
	var guard: Vector2 = -axis*3.0
	var tip: Vector2 = axis*19.0
	draw_line(grip,guard,Color("3b303f"),3.2,true)
	draw_line(grip-n*0.55,guard-n*0.55,Color("987e93"),0.7,true)
	draw_line(guard-n*5.0-axis,guard+n*5.0-axis,Color("a99bad"),1.7,true)
	draw_circle(guard,1.9,Color("746085"))
	draw_colored_polygon(PackedVector2Array([guard-n*2.7,tip,guard+n*2.7,guard-axis*1.5]),Color("515064"))
	draw_colored_polygon(PackedVector2Array([guard,tip,guard-n*2.7]),Color("c9c4d6"))
	draw_line(guard,tip,Color(tint.r,tint.g,tint.b,fade*(0.85 if returning else 0.56)),1.0,true)
