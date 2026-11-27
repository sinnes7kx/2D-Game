extends Node2D
## A narrow spectral dagger. Independent hit ledgers per flight leg.
## No arrow puzzles, no damage from visual trails, no changes to other returns.
const AUDIO = preload("res://scripts/arrow_impact_audio_v233.gd")
const COMBAT_AUDIO = preload("res://scripts/combat_juice_v194.gd")
const OUT_SPEED: float = 860.0
const RETURN_SPEED: float = 1040.0
const OUT_RANGE: float = 390.0
const RETURN_RANGE: float = 980.0
const OUT_POWER: float = 0.72
const RETURN_POWER: float = 0.65
const MAX_TARGETS_PER_LEG: int = 4
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
var _shape: CircleShape2D = CircleShape2D.new()

func _ready() -> void:
	z_index = 30
	direction = direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT
	_shape.radius = 6.0

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
	if is_inside_tree():
		COMBAT_AUDIO.play(get_tree().current_scene,global_position,"dagger_swing",-23.0)

func damage_now() -> float:
	return power * (RETURN_POWER if returning else OUT_POWER)

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
	var speed: float = RETURN_SPEED if returning else OUT_SPEED
	var travel: float = minf(remaining,speed*delta)
	var caught: bool = false
	if returning:
		var toward: Vector2 = _catch_point()-global_position
		var distance: float = toward.length()
		if distance <= 6.0:
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
			target.call("hit",damage_now(),0.55)
			AUDIO.play(get_tree().current_scene,point,material,false)
	global_position = end
	remaining -= travel
	traveled += start.distance_to(end)
	trail.push_front(global_position)
	if trail.size()>9:
		trail.pop_back()
	queue_redraw()
	if not wall.is_empty():
		AUDIO.play(get_tree().current_scene,end,AUDIO.material_for(wall.get("collider"),"stone"),false)
		if returning:
			queue_free()
		else:
			begin_return()
	elif returning and caught:
		queue_free()
	elif remaining<=0.0:
		if returning:
			queue_free()
		else:
			begin_return()

func _draw() -> void:
	var axis: Vector2 = direction
	var n: Vector2 = axis.orthogonal()
	var tint: Color = GhostCosmeticRNGV152.sample_palette(palette,traveled*0.003,true) if not palette.is_empty() else Color("b7a3d8")
	var fade: float = clampf(glow,0.0,1.0)
	for i in range(1,trail.size()):
		var alpha: float = (1.0-float(i)/float(trail.size()))*fade*(0.38 if returning else 0.24)
		draw_line(to_local(trail[i-1]),to_local(trail[i]),Color(tint.r,tint.g,tint.b,alpha),2.2,true)
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
