extends Node2D
const RelicPaletteV139 = preload("res://scripts/procedural_relic_palette_v139.gd")
const ARROW_AUDIO = preload("res://scripts/arrow_impact_audio_v233.gd")
const ARCHERY_ENV = preload("res://scripts/archery_environment_v272.gd")
const EMBED = preload("res://scripts/embedded_arrow_v272.gd")
var physical_archery: bool = true
var ignited_v272: bool = false
## One physical arrow. Rare decorations add visual wisps but never extra hits.
## Charged arrows may pierce TWO distinct enemies, once each; world/cover stops them.
var direction: Vector2 = Vector2.RIGHT
var speed: float = 980.0
var damage: float = 15.0
var range_left: float = 830.0
var charged: bool = false
var is_crossbow_bolt: bool = false
var launched_in_air: bool = false
var caster: Node2D = null
var caster_rid: RID
var bow_style: String = "thornrose"
var ink: Color = Color("d8afca")
var accent: Color = Color("b7d8f3")
var fx_tier: int = 0
var motif: int = 0
var trail_style: int = 0
var visual_variant: int = -1
# v1.38 independent saved bow visual/puzzle rolls.
var element_index: int = 0
var formation_index: int = 0
var bow_glow_index: int = 0
var bow_trail_index: int = 0
var bow_detail_index: int = 0
# Presentation-only seed signature: never influences damage or raycasts.
var projectile_style: int = 0
var visual_glow_scale: float = 1.0
var procedural_look: Dictionary = {}
var distance_travelled: float = 0.0
var hit_ids: Dictionary = {}
var can_return: bool = false
var returning: bool = false
var secondary_projectile: bool = false
var trail_points: Array[Vector2] = []
const BOW_IMPACT_V129: Script = preload("res://scripts/bow_impact_v129.gd")
const ARROW_GLOW_V154: Script = preload("res://scripts/arrow_glow_v154.gd")
var full_palette: Array[Color] = []
var glow_a: Color = Color("efb3d7")
var glow_b: Color = Color("c09df2")
var glow_c: Color = Color("a6dbfa")

func _ready() -> void:
	z_index = 30
	direction = direction.normalized() if direction.length_squared() > 0.0 else Vector2.RIGHT
	# Bolts own a short seeded trail and do not allocate the long arrow lantern.
	if is_crossbow_bolt:
		queue_redraw()
		return
	# A separate additive layer preserves the readable painted arrow shaft.
	var lantern: Node2D = Node2D.new()
	lantern.name = "ArrowLanternGlowV154"
	lantern.set_script(ARROW_GLOW_V154)
	add_child(lantern)
	queue_redraw()

func contact_stagger_v276() -> float:
	return 1.3 if charged else 0.85

func confirmed_contact_v276(_target: Node, _point: Vector2) -> void:
	pass

func _physics_process(delta: float) -> void:
	if returning:
		if not is_instance_valid(caster) or not caster.is_inside_tree():
			queue_free()
			return
		var toward: Vector2 = caster.global_position + Vector2(0, -39) - global_position
		if toward.length() <= maxf(12.0, speed * delta):
			queue_free()
			return
		direction = toward.normalized()
	var travel: float = minf(speed * delta, range_left)
	if travel <= 0.0:
		queue_free()
		return
	var start: Vector2 = global_position
	var destination: Vector2 = start + direction * travel
	var state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var wall_query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(start, destination)
	wall_query.collision_mask = 6 # Solid world and pullable cover only.
	if caster_rid.is_valid():
		wall_query.exclude = [caster_rid]
	var wall: Dictionary = state.intersect_ray(wall_query)
	var end: Vector2 = wall.get("position", destination) if not wall.is_empty() else destination
	# Track potential ignition at the end of the clipped segment without
	# prematurely giving a nearer enemy the fire damage bonus.
	var end_ignited: bool = _fire_at_v272(start,end)
	# v1.39: environmental objects share this same swept segment, so visual
	# echo arrows never create multiple activations or hitboxes.
	# Light reveals nearby world secrets as its one physical arrow passes,
	# even when it strikes a wall or creature. This does not add damage.
	if not is_crossbow_bolt and not returning and not secondary_projectile and element_index == 3:
		_reveal_hidden_near_sweep(start, end)
	if not is_crossbow_bolt and not returning and not secondary_projectile and _check_world_elements(start, end):
		return
	# Charged jump shots can strike painted moon targets. This is checked
	# against the SAME swept segment as walls/enemies, without extra arrows.
	if not is_crossbow_bolt and not returning and not secondary_projectile and _check_elemental_targets(start, end):
		return
	if not is_crossbow_bolt and not returning and not secondary_projectile and _check_moon_targets(start, end):
		return
	if not is_crossbow_bolt and not returning and not secondary_projectile and ARCHERY_ENV.effective_element(element_index,end_ignited) == 2 and _freeze_water_on_sweep(start, end):
		_impact(end, "water")
		queue_free()
		return
	var length: float = start.distance_to(end)
	var steps: int = maxi(1, ceili(length / 12.0))
	var shot_shape: CircleShape2D = CircleShape2D.new()
	shot_shape.radius = 11.0 if charged else 8.0
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = shot_shape
	query.collision_mask = 16 | 32
	query.collide_with_areas = true
	if caster_rid.is_valid():
		query.exclude = [caster_rid]
	for i in range(steps + 1):
		var point: Vector2 = start.lerp(end, float(i) / float(steps))
		query.transform = Transform2D(0.0, point)
		for record in state.intersect_shape(query, 12):
			var target: Node = record.get("collider") as Node
			if target is Area2D:
				target = target.get_parent()
			if target == null or not (target is Node2D) or not target.is_in_group("enemies") or not target.has_method("hit"):
				continue
			var target_id: int = target.get_instance_id()
			if hit_ids.has(target_id):
				continue
			hit_ids[target_id] = true
			ignited_v272=_fire_at_v272(start,point)
			var material: String = ARROW_AUDIO.material_for(target, "flesh")
			target.call("hit", ARCHERY_ENV.impact_power(damage,ignited_v272), contact_stagger_v276())
			confirmed_contact_v276(target,point)
			if ARCHERY_ENV.effective_element(element_index,ignited_v272) == 2 and target.has_method("apply_frost_slow") and is_instance_valid(target) and not target.is_queued_for_deletion():
				target.call("apply_frost_slow", 1.35, 0.78)
			_impact(point, material)
			if not returning and (not charged or hit_ids.size() >= 2):
				if can_return:
					global_position = point
					_begin_return()
				else:
					queue_free()
				return
			if returning:
				queue_free()
				return
	ignited_v272=end_ignited
	if not wall.is_empty():
		var cover: Object = wall.get("collider")
		var material: String = ARROW_AUDIO.material_for(cover, "stone")
		if is_instance_valid(cover) and ARCHERY_ENV.effective_element(element_index,ignited_v272) == 1 and cover.has_method("ignite_from_environment"):
			cover.call("ignite_from_environment")
		if is_instance_valid(cover) and cover.has_method("receive_damage"):
			cover.call("receive_damage", ARCHERY_ENV.impact_power(damage,ignited_v272), end)
		_impact(end, material)
		if physical_archery and is_instance_valid(cover):
			_embed_surface_v272(cover,end)
		queue_free()
		return
	global_position = destination
	range_left -= travel
	distance_travelled += travel
	trail_points.push_front(global_position)
	if trail_points.size() > 12:
		trail_points.pop_back()
	queue_redraw()
	if range_left <= 0.0:
		if can_return and not returning:
			_begin_return()
		else:
			queue_free()

func _begin_return() -> void:
	returning = true
	range_left = 950.0
	damage *= 0.60
	charged = false
	trail_points.clear()

func _reveal_hidden_near_sweep(start: Vector2, end: Vector2) -> void:
	var line: Vector2 = end - start
	if line.length_squared() < 0.001:
		return
	for node in get_tree().get_nodes_in_group("v140_light_reveal"):
		if not is_instance_valid(node) or not (node is Node2D) or not node.has_method("reveal_from_light"):
			continue
		var t: float = clampf((node.global_position - start).dot(line) / line.length_squared(), 0.0, 1.0)
		var closest: Vector2 = start + line * t
		node.call("reveal_from_light", closest)

func _freeze_water_on_sweep(start: Vector2, end: Vector2) -> bool:
	for water in get_tree().get_nodes_in_group("water_body"):
		if is_instance_valid(water) and water.has_method("freeze_arrow_segment"):
			if bool(water.call("freeze_arrow_segment", start, end, 10.0)):
				return true
	return false

func _check_world_elements(start: Vector2, end: Vector2) -> bool:
	var segment: Vector2 = end - start
	var length_sq: float = segment.length_squared()
	if length_sq < 0.001:
		return false
	for candidate in get_tree().get_nodes_in_group("v139_elemental_world"):
		if not is_instance_valid(candidate) or not (candidate is Node2D) or candidate.is_queued_for_deletion():
			continue
		if not candidate.has_method("on_elemental_arrow_hit"):
			continue
		var projection: float = clampf((candidate.global_position - start).dot(segment) / length_sq, 0.0, 1.0)
		var contact: Vector2 = start + segment * projection
		var radius: float = float(candidate.get("trigger_radius"))
		if contact.distance_squared_to(candidate.global_position) <= radius * radius:
			var material: String = ARROW_AUDIO.material_for(candidate, "magic")
			var contact_ignited: bool = _fire_at_v272(start,contact)
			if bool(candidate.call("on_elemental_arrow_hit", ARCHERY_ENV.effective_element(element_index,contact_ignited), formation_index, charged, launched_in_air)):
				ignited_v272=contact_ignited
				_impact(contact, material)
				queue_free()
				return true
	return false

func _check_elemental_targets(start: Vector2, end: Vector2) -> bool:
	# Use the already wall-clipped swept segment. A decorative triple-shot
	# never generates two extra physical raycasts or extra damage events.
	var segment: Vector2 = end - start
	var length_sq: float = segment.length_squared()
	if length_sq < 0.001:
		return false
	for candidate in get_tree().get_nodes_in_group("v138_arrow_targets"):
		if not is_instance_valid(candidate) or not (candidate is Node2D):
			continue
		var target: Node2D = candidate as Node2D
		if target.is_queued_for_deletion() or not target.has_method("on_elemental_arrow_hit"):
			continue
		var projection: float = clampf((target.global_position - start).dot(segment) / length_sq, 0.0, 1.0)
		var hit_point: Vector2 = start + segment * projection
		var radius: float = float(target.get("trigger_radius"))
		if hit_point.distance_squared_to(target.global_position) <= radius * radius:
			var contact_ignited: bool = _fire_at_v272(start,hit_point)
			if bool(target.call("on_elemental_arrow_hit", ARCHERY_ENV.effective_element(element_index,contact_ignited), formation_index, charged, launched_in_air)):
				ignited_v272=contact_ignited
				_impact(hit_point, "magic")
				queue_free()
				return true
	return false

func _check_moon_targets(start: Vector2, end: Vector2) -> bool:
	if not (charged and launched_in_air):
		return false
	var segment: Vector2 = end - start
	var length_sq: float = segment.length_squared()
	if length_sq < 0.001:
		return false
	for candidate in get_tree().get_nodes_in_group("moon_archery_targets"):
		if not is_instance_valid(candidate) or not (candidate is Node2D):
			continue
		var target: Node2D = candidate as Node2D
		if target.is_queued_for_deletion() or not target.has_method("on_bow_hit"):
			continue
		var projection: float = clampf((target.global_position - start).dot(segment) / length_sq, 0.0, 1.0)
		var point: Vector2 = start + segment * projection
		var range: float = float(target.get("trigger_radius"))
		if point.distance_squared_to(target.global_position) <= range * range:
			if target.call("on_bow_hit", charged, launched_in_air):
				_impact(point, "magic")
				queue_free()
				return true
	return false

func _impact(where: Vector2, surface: String = "stone") -> void:
	var root: Node = get_tree().current_scene
	if root == null:
		return
	# One positional sound per existing confirmed collision, even with glow Off.
	ARROW_AUDIO.play(root, where, surface, charged)
	if visual_glow_scale <= 0.0:
		return
	var flash: Node2D = Node2D.new()
	flash.set_script(BOW_IMPACT_V129)
	flash.call("configure", ink, accent, visual_variant, fx_tier, direction, charged, motif)
	flash.set("element_index", ARCHERY_ENV.effective_element(element_index,ignited_v272))
	flash.set("formation_index", formation_index)
	flash.self_modulate.a = decoration_alpha(1.0)
	root.add_child(flash)
	flash.global_position = where

# Scale decoration only; the physical arrow is always drawn at full opacity.
func decoration_alpha(value: float) -> float:
	return value * clampf(visual_glow_scale, 0.0, 1.0)

func decoration_color(value: Color) -> Color:
	value.a = decoration_alpha(value.a)
	return value

func _draw_arrow_shaft(offset: Vector2, tint: Color, alpha: float, length_scale: float) -> void:
	var p: Vector2 = Vector2(-direction.y, direction.x)
	draw_line(-direction * (20.0 * length_scale) + offset, direction * (16.0 * length_scale) + offset, Color(tint.r, tint.g, tint.b, alpha), 2.1, true)
	draw_line(direction * (16.0 * length_scale) + offset, direction * (22.0 * length_scale) + offset, Color(tint.r, tint.g, tint.b, alpha), 2.8, true)
	for sign in [-1.0, 1.0]:
		draw_line(-direction * (17.0 * length_scale) + offset, -direction * (10.0 * length_scale) + offset + p * 5.0 * sign, Color(tint.r, tint.g, tint.b, alpha * 0.83), 1.7, true)

func _draw() -> void:
	var time_pulse: float = distance_travelled * 0.016
	var p: Vector2 = Vector2(-direction.y, direction.x)
	var element_ink: Color = GhostBowImprintsV138.color_for_element(element_index)
	var glow_ink: Color = GhostWeaponFXLibrary.color(bow_glow_index)
	if not full_palette.is_empty():
		glow_ink = GhostCosmeticRNGV152.sample_palette(full_palette, time_pulse * 0.13, true)
	elif not procedural_look.is_empty():
		glow_ink = RelicPaletteV139.color_at(procedural_look, time_pulse, 0.33)
	var mixed: Color = glow_ink.lerp(element_ink, 0.15 + 0.08 * sin(time_pulse))
	_draw_arrow_shaft(Vector2.ZERO, Color("e4dce5").lerp(element_ink, 0.43), 1.0, 0.58 if is_crossbow_bolt else 1.0)
	if ignited_v272:
		_draw_fire_v272() # Gameplay-readable flame even when cosmetic glow is off.
	if is_crossbow_bolt:
		if visual_glow_scale > 0.0:
			draw_line(-direction * 19.0, -direction * 5.0, decoration_color(Color(glow_ink.r, glow_ink.g, glow_ink.b, 0.38)), 1.5, true)
		return
	# Glow Off removes decorative light; the physical painted arrow and
	# unchanged single-hit physics are still present.
	if visual_glow_scale <= 0.0:
		return
	var pulse: float = 0.5 + 0.5 * sin(time_pulse * 3.2)
	draw_circle(direction * 18.0, 4.5 + pulse * 2.0, decoration_color(Color(mixed.r, mixed.g, mixed.b, 0.13 + 0.08 * pulse)))
	draw_circle(direction * 18.0, 2.5 + pulse, decoration_color(Color(element_ink.r, element_ink.g, element_ink.b, 0.46)))
	if not procedural_look.is_empty():
		var count: int = int(procedural_look.get("spark_count", 5))
		var motion: int = int(procedural_look.get("motion", 0))
		var size: float = float(procedural_look.get("spark_size", 1.8))
		var speed_factor: float = float(procedural_look.get("pulse_speed", 1.0))
		var geometry: int = int(procedural_look.get("geometry", 0))
		var radius: float = float(procedural_look.get("orbit_radius", 14.0))
		for i in range(count):
			var f: float = float(i) / float(maxi(1, count))
			var phase: float = f * TAU + time_pulse * speed_factor * 0.6
			var point: Vector2 = -direction * (8.0 + f * 34.0)
			var orbital: float = radius * 0.31 * sin(phase * (1.0 + float(motion % 3)))
			point += p * orbital
			var c: Color = RelicPaletteV139.color_at(procedural_look, time_pulse, f)
			c.a = decoration_alpha((0.15 + 0.22 * (1.0 - f)) * (0.4 if fx_tier < 2 else 1.0))
			if geometry % 3 == 0:
				draw_circle(point, size * (1.0 - f * 0.45), c)
			elif geometry % 3 == 1:
				draw_line(point - p * size, point + p * size, c, 1.1, true)
			else:
				draw_arc(point, size * 1.5, phase, phase + PI * 1.2, 8, c, 1.0, true)
	# A triple formation has two orbiting *painted* arrows, not two hitboxes.
	if formation_index == 1:
		for side in [-1.0, 1.0]:
			var drift: float = 10.0 + sin(time_pulse * 3.0 + side) * (1.7 + float(bow_trail_index % 3))
			var position: Vector2 = p * side * drift - direction * (5.0 + side * 2.0)
			_draw_arrow_shaft(position, mixed, decoration_alpha(0.32), 0.78)
			draw_circle(direction * 15.0 + position, 3.0, decoration_color(Color(element_ink.r, element_ink.g, element_ink.b, 0.16)))
	if element_index == 1: # Emberfire: soft cinders and a tapered flame
		for i in range(6):
			var t: float = float(i) / 6.0
			var v: Vector2 = -direction * (4.0 + 32.0 * t) + p * sin(time_pulse * 3.0 + float(i)) * (3.0 + 4.0 * t)
			draw_circle(v, 2.1 + 2.7 * (1.0 - t), decoration_color(Color(1.0, 0.28 + 0.48 * (1.0 - t), 0.20, 0.27 * (1.0 - t))))
	elif element_index == 2: # Frostglass: glinting geometric needles
		for i in range(5):
			var v: Vector2 = -direction * (2.0 + float(i) * 7.0) + p * sin(time_pulse + float(i)) * 4.0
			draw_line(v - p * 4.0, v + p * 4.0, decoration_color(Color(0.58, 0.89, 1.0, 0.28)), 1.3, true)
	elif element_index == 3: # Light: moon rings and pearl-white flashes
		draw_arc(direction * 12.0, 9.0 + pulse * 3.0, time_pulse, time_pulse + PI * 1.55, 18, decoration_color(Color(1.0, 0.96, 0.76, 0.36)), 1.6, true)
		for i in range(3):
			var v: Vector2 = -direction * float(i * 10 + 4) + p * sin(time_pulse * 2.0 + float(i)) * 5.0
			draw_circle(v, 1.6, decoration_color(Color(1.0, 0.94, 0.81, 0.30)))
	if fx_tier >= 2:
		for i in range(3 + fx_tier):
			var theta: float = float(i) * TAU / float(3 + fx_tier) + time_pulse
			var v: Vector2 = direction * (-8.0 - float(i % 3) * 4.0) + Vector2.from_angle(theta) * (4.0 + float(i % 2) * 3.0)
			draw_circle(v, 1.2, decoration_color(Color(mixed.r, mixed.g, mixed.b, 0.27)))
	var step: float = 4.0 + float(bow_trail_index % 3)
	for j in range(4):
		var n: float = float(j)
		var pos: Vector2 = -direction * (10.0 + n * step) + p * sin(time_pulse * (2.0 + float(bow_trail_index) * 0.15) + n * 0.85) * (2.0 + float(bow_detail_index % 3))
		draw_circle(pos, 1.1 + float(bow_detail_index % 2) * 0.5, decoration_color(Color(glow_ink.r, glow_ink.g, glow_ink.b, 0.30 - n * 0.045)))

func _embed_surface_v272(surface: Object,point: Vector2) -> void:
	var root: Node = get_tree().current_scene
	if root==null:
		return
	if surface is Node2D and (surface.is_queued_for_deletion() or (surface.is_in_group("breakable_cover") and bool(surface.get("broken")))):
		return
	var existing: Array[Node] = get_tree().get_nodes_in_group("embedded_arrow_v272")
	if existing.size()>=ARCHERY_ENV.EMBED_LIMIT:
		for i in range(existing.size()-ARCHERY_ENV.EMBED_LIMIT+1):
			existing[i].queue_free()
	var shaft = EMBED.new()
	shaft.bolt=is_crossbow_bolt
	shaft.burning=ARCHERY_ENV.effective_element(element_index,ignited_v272)==1
	shaft.tint=Color("e4dce5").lerp(GhostBowImprintsV138.color_for_element(ARCHERY_ENV.effective_element(element_index,ignited_v272)),0.43)
	root.add_child(shaft)
	shaft.bind_surface(surface,point,direction)
	if root.has_method("track_room_effect"):
		root.call("track_room_effect",shaft)

func _draw_fire_v272() -> void:
	var tip: Vector2 = direction*(12.0 if is_crossbow_bolt else 19.0)
	var n: Vector2 = direction.orthogonal()
	var pulse: float = 0.5+0.5*sin(distance_travelled*0.095)
	draw_circle(tip,6.0+pulse*2.0,Color(1.0,0.29,0.09,0.23))
	draw_colored_polygon(PackedVector2Array([tip+direction*3.0,tip+n*3.3,tip-direction*(23.0+4.0*pulse),tip-n*3.3]),Color(1.0,0.42,0.12,0.56))
	draw_line(tip,tip-direction*12.0,Color(1.0,0.84,0.44,0.86),1.7,true)

func _fire_at_v272(start: Vector2,end: Vector2) -> bool:
	return ignited_v272 or (physical_archery and ARCHERY_ENV.crosses_fire(self,start,end))
