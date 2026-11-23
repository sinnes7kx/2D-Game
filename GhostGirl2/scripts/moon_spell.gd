extends Node2D
## V1.13 spectral wand forms: one hit event regardless of visual projectile count.
## The beam performs one swept, wall-clipped collision query and then fades.
## Multi-wisp/triple-star styles are synchronized cosmetic formations, not extra shots.
var direction: Vector2 = Vector2.RIGHT
var speed: float = 740.0
var damage: float = 15.0
var charged: bool = false
var distance_left: float = 850.0
var owner_rid: RID
var caster: Node2D
var age: float = 0.0
var effect_motif: int = 0
var effect_color: Color = Color("bca9f5")
var accent_color: Color = Color("efbde0")
var gradient_c: Color = Color("f0dce9")
var rare_signature: int = 0
var mythic_layer_variant: int = 0  # purely visual, saved-look-derived
var trail_style: int = 0
var effect_tier: int = 0
var spell_form: int = 0
var effect_seed: int = 0
var trail: Array[Vector2] = []
var beam_resolved: bool = false
var beam_end: Vector2 = Vector2.ZERO
const BEAM_FADE: float = 0.36
const LANCE_FADE: float = 0.52  # A bright, sustained-looking one-hit flash
const IMPACT_SCRIPT: Script = preload("res://scripts/weapon_spectacle.gd")
const IMPACT_PRESTIGE: Script = preload("res://scripts/impact_prestige_v116.gd")
var impact_style: int = 0

func _physics_process(delta: float) -> void:
	if spell_form >= 5:
		if not beam_resolved:
			_resolve_beam()
		elif age >= (LANCE_FADE if spell_form == 7 else BEAM_FADE):
			queue_free()
		return
	var distance: float = minf(speed * delta, distance_left)
	if distance <= 0.0:
		queue_free()
		return
	var start: Vector2 = global_position
	var finish: Vector2 = start + direction.normalized() * distance
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	# Crates and world stone intercept physical and magical projectiles.
	var wall_ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(start, finish)
	wall_ray.collision_mask = 6  # World (2), destructible crates (4)
	wall_ray.exclude = [owner_rid]
	var wall: Dictionary = space.intersect_ray(wall_ray)
	var safe_finish: Vector2 = wall.get("position", finish) if not wall.is_empty() else finish
	var victim: Node2D = _find_contact(space, start, safe_finish)
	if victim != null:
		_hit_enemy(victim)
		queue_free()
		return
	if not wall.is_empty():
		_hit_cover(wall)
		queue_free()
		return
	global_position = finish
	distance_left -= distance
	trail.append(global_position)
	if trail.size() > 10:
		trail.pop_front()
	if distance_left <= 0.0:
		queue_free()

func _resolve_beam() -> void:
	beam_resolved = true
	age = 0.0
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var start: Vector2 = global_position
	var finish: Vector2 = start + direction.normalized() * distance_left
	var wall_ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(start, finish)
	wall_ray.collision_mask = 6
	wall_ray.exclude = [owner_rid]
	var wall: Dictionary = space.intersect_ray(wall_ray)
	var safe_finish: Vector2 = wall.get("position", finish) if not wall.is_empty() else finish
	var victim: Node2D = _find_contact(space, start, safe_finish)
	beam_end = safe_finish
	if victim != null:
		beam_end = victim.global_position + Vector2(0, -28)
		_hit_enemy(victim)
	elif not wall.is_empty():
		_hit_cover(wall)

func _hit_cover(hit: Dictionary) -> void:
	var cover: Object = hit.get("collider")
	if cover != null and cover.has_method("receive_damage"):
		cover.call("receive_damage", damage, global_position)
	_spawn_contact_effect(hit.get("position", global_position))

func _hit_enemy(victim: Node2D) -> void:
	# The visible extra wisps never multiply the hitbox or this damage event.
	victim.call("hit", damage, 1.0 if not charged else 1.25)
	_spawn_contact_effect(victim.global_position + Vector2(0.0, -25.0))
	if is_instance_valid(caster) and caster.has_method("on_wand_projectile_hit"):
		caster.call("on_wand_projectile_hit", charged)

func _spawn_contact_effect(where: Vector2) -> void:
	# Only one burst per resolved collision. Cosmetic wisps share one hit event.
	var root: Node = get_tree().current_scene
	if root == null:
		return
	var burst: Node2D = Node2D.new()
	burst.set_script(IMPACT_SCRIPT)
	# Use explicit state rather than calling the version-sensitive overload.
	burst.set("effect_kind", "spell")
	burst.set("ink", effect_color)
	burst.set("motif", effect_motif)
	burst.set("rarity", maxi(0, effect_tier))
	burst.set("facing", direction.normalized() if direction.length_squared() > 0.01 else Vector2.RIGHT)
	burst.set("accent", accent_color)
	burst.set("trail_style", trail_style)
	burst.set("lifetime", 0.32)
	burst.set("life", 0.32)
	root.add_child(burst)
	burst.global_position = where
	var starburst: Node2D = Node2D.new()
	starburst.set_script(IMPACT_PRESTIGE)
	root.add_child(starburst)
	starburst.global_position = where
	starburst.call("configure", "wand", effect_color, accent_color, impact_style, effect_tier, direction, effect_seed)

func _find_contact(space: PhysicsDirectSpaceState2D, start: Vector2, finish: Vector2) -> Node2D:
	# Swept sphere checks guarantee a single first target, including beams.
	var radius: float = 17.0 if charged else 11.0
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = radius
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	query.shape = circle
	query.collision_mask = 16 | 32
	query.collide_with_areas = true
	query.exclude = [owner_rid]
	var segment: Vector2 = finish - start
	var count: int = maxi(1, ceili(segment.length() / (radius * 1.1)))
	for n in range(count + 1):
		query.transform = Transform2D(0.0, start.lerp(finish, float(n) / float(count)))
		for contact in space.intersect_shape(query, 16):
			var collider: Object = contact.get("collider")
			var target: Node = collider as Node
			if target is Area2D:
				target = target.get_parent()
			if target is Node2D and target.is_in_group("enemies") and target.has_method("hit"):
				return target as Node2D
	return null

func _process(delta: float) -> void:
	age += delta
	queue_redraw()

func _draw() -> void:
	var pulse: float = 1.0 + sin(age * 21.0 + float(effect_seed % 13)) * 0.10
	var scale_factor: float = 1.75 if charged else 1.0
	var light: Color = effect_color.lerp(Color.WHITE, 0.62)
	var accent_light: Color = accent_color.lerp(Color.WHITE, 0.45)
	var glow: Color = Color(effect_color.r, effect_color.g, effect_color.b, 0.16)
	if spell_form == 7:
		_draw_luminous_lance()
		_draw_lance_cosmetics()
		if rare_signature == 4:
			_draw_mythic_spell_beam(to_local(beam_end), clampf(1.0 - age / LANCE_FADE, 0.0, 1.0))
		return
	if spell_form >= 5:
		var line_end: Vector2 = to_local(beam_end)
		var fade: float = clampf(1.0 - age / BEAM_FADE, 0.0, 1.0)
		var beam_width: float = (11.0 if charged else 6.5) * (0.65 + fade * 0.35)
		draw_line(Vector2.ZERO, line_end, Color(effect_color.r, effect_color.g, effect_color.b, 0.15 * fade), beam_width * 3.6, true)
		draw_line(Vector2.ZERO, line_end, Color(effect_color.r, effect_color.g, effect_color.b, 0.66 * fade), beam_width * 1.6, true)
		draw_line(Vector2.ZERO, line_end, Color(light.r, light.g, light.b, fade), beam_width * 0.36, true)
		# Secondary filaments have their own independent color and motion.
		var cross: Vector2 = Vector2(-direction.y, direction.x)
		var strand_count: int = 2 if trail_style in [3, 4, 5] else 1
		for strand in range(strand_count):
			var points: PackedVector2Array = PackedVector2Array()
			for step in range(13):
				var f: float = float(step) / 12.0
				var twist: float = sin(f * TAU * (1.0 + float(trail_style % 3)) + age * 10.0 + float(strand) * PI)
				var width: float = 3.0 + float(trail_style) * 1.25
				points.append(line_end * f + cross * twist * width * sin(f * PI))
			draw_polyline(points, Color(accent_light.r, accent_light.g, accent_light.b, fade * 0.60), 1.9, true)
		draw_circle(line_end, 10.0 * fade + 3.0, Color(light.r, light.g, light.b, fade * 0.70))
		var span: float = line_end.length()
		var normal: Vector2 = Vector2(-direction.y, direction.x)
		for i in range(10 if spell_form == 6 else 5):
			var fraction: float = float(i + 1) / float(11 if spell_form == 6 else 6)
			var p: Vector2 = direction.normalized() * span * fraction
			if spell_form == 6:
				var off: float = sin(fraction * 20.0 + age * 8.0) * (10.0 + 8.0 * fade)
				draw_circle(p + normal * off, 2.4 + fade * 2.0, Color(effect_color.r, effect_color.g, effect_color.b, 0.86 * fade))
				draw_circle(p - normal * off, 2.0 + fade * 1.6, Color(accent_light.r, accent_light.g, accent_light.b, 0.75 * fade))
			else:
				draw_circle(p, 2.0 + fade * 1.8, Color(light.r, light.g, light.b, 0.6 * fade))
		_draw_beam_cosmetics(line_end, fade)
		if rare_signature == 4:
			_draw_mythic_spell_beam(line_end, fade)
		return

	for j in range(trail.size()):
		var t: float = float(j + 1) / float(trail.size())
		var trail_point: Vector2 = to_local(trail[j])
		var trace: Color = effect_color if j % 2 == 0 else accent_color
		draw_circle(trail_point, (2.0 + t * 3.0) * scale_factor, Color(trace.r, trace.g, trace.b, 0.10 + t * 0.29))
		if trail_style >= 2:
			var normal: Vector2 = Vector2(-direction.y, direction.x)
			var phase: float = (float(j) * 0.55 + age * (3.0 + float(trail_style)))
			var side: float = sin(phase) * (3.0 + float(trail_style) * 1.7)
			draw_circle(trail_point + normal * side, (1.4 + t * 2.0) * scale_factor, Color(accent_color.r, accent_color.g, accent_color.b, (0.14 + t * 0.31)))
	draw_circle(Vector2.ZERO, 18.0 * pulse * scale_factor, glow)
	draw_circle(Vector2.ZERO, 9.0 * pulse * scale_factor, Color(effect_color.r, effect_color.g, effect_color.b, 0.53))
	draw_circle(Vector2.ZERO, 5.5 * scale_factor, Color(light.r, light.g, light.b, 0.96))
	if spell_form == 1:  # comet trail
		draw_line(-direction * 34.0 * scale_factor, Vector2.ZERO, Color(effect_color.r, effect_color.g, effect_color.b, 0.49), 5.0 * scale_factor, true)
	elif spell_form == 2:  # paired ghost wisps, single damage probe
		var normal: Vector2 = Vector2(-direction.y, direction.x)
		for side in [-1.0, 1.0]:
			var p: Vector2 = normal * (12.0 + sin(age * 26.0) * 4.0) * side
			draw_circle(p, 5.0 * scale_factor, Color(effect_color.r, effect_color.g, effect_color.b, 0.55))
			draw_circle(p, 2.0 * scale_factor, accent_light)
	elif spell_form == 3:  # orbiting glyph
		draw_arc(Vector2.ZERO, 20.0 * scale_factor, age * 5.0, age * 5.0 + TAU * 0.88, 30, Color(light.r, light.g, light.b, 0.7), 2.0, true)
		for i in range(4):
			var p: Vector2 = Vector2.from_angle(age * 5.0 + float(i) * TAU / 4.0) * 20.0 * scale_factor
			draw_circle(p, 2.7, accent_color)
	elif spell_form == 4:  # three linked stars, single swept collision
		var normal: Vector2 = Vector2(-direction.y, direction.x)
		for i in range(3):
			var off: float = float(i - 1) * 16.0 + sin(age * 18.0 + float(i)) * 2.0
			var p: Vector2 = normal * off - direction * 3.0
			var star_color: Color = effect_color if i % 2 == 0 else accent_color
			draw_circle(p, 6.0 * scale_factor, Color(star_color.r, star_color.g, star_color.b, 0.71))
			draw_line(p + Vector2(-6, 0), p + Vector2(6, 0), light, 1.6, true)
			draw_line(p + Vector2(0, -6), p + Vector2(0, 6), light, 1.6, true)
	_draw_projectile_cosmetics(scale_factor)
	if rare_signature == 4:
		_draw_mythic_spell_bolt(scale_factor)
	# Each affix motif changes the edge details independently of projectile form.
	for i in range(3 + effect_tier):
		var a: float = float(i) * TAU / float(3 + effect_tier) + age * (2.0 + float(effect_motif % 4))
		var p: Vector2 = Vector2.from_angle(a) * (15.0 + float(effect_motif % 4) * 2.0)
		var ornament_color: Color = light if i % 2 == 0 else accent_light
		if effect_motif % 2 == 0:
			draw_circle(p, 2.4, Color(ornament_color.r, ornament_color.g, ornament_color.b, 0.8))
		else:
			draw_line(p - Vector2(3, 0), p + Vector2(3, 0), Color(ornament_color.r, ornament_color.g, ornament_color.b, 0.8), 1.2, true)


func _draw_luminous_lance() -> void:
	# Screenshot-inspired spell: a continuous-looking pearl-white lance with
	# gently tapering bloom. This is VISUAL ONLY; _resolve_beam() performs
	# exactly one wall-clipped collision query, then the light fades in place.
	var tip: Vector2 = to_local(beam_end)
	var span: float = tip.length()
	if span < 1.0:
		return
	var axis: Vector2 = tip.normalized()
	var normal: Vector2 = Vector2(-axis.y, axis.x)
	var fade: float = clampf(1.0 - age / LANCE_FADE, 0.0, 1.0)
	var onset: float = minf(1.0, age / 0.055 + 0.48)
	var energy: float = fade * onset
	var shimmer: float = 0.91 + 0.09 * sin(age * 29.0 + float(effect_seed % 31))
	var pearl: Color = Color(1.0, 0.99, 0.97, 1.0)
	var rose: Color = effect_color.lerp(pearl, 0.55)
	var secondary: Color = accent_color.lerp(pearl, 0.46)
	# Broad glow, fine pastel boundary, and a near-white core.
	# Piecewise segment widths produce the tapered blade of light.
	for section in range(16):
		var a: float = float(section) / 16.0
		var b: float = float(section + 1) / 16.0
		var mid: float = (a + b) * 0.5
		var tip_taper: float = 1.0 - smoothstep(0.74, 1.0, mid)
		var width: float = (17.0 + 7.0 * smoothstep(0.0, 0.2, mid)) * (0.65 + 0.35 * tip_taper)
		var p0: Vector2 = tip * a
		var p1: Vector2 = tip * b
		draw_line(p0, p1, Color(secondary.r, secondary.g, secondary.b, 0.09 * energy), width * 3.3, true)
		draw_line(p0, p1, Color(rose.r, rose.g, rose.b, 0.19 * energy), width * 2.25, true)
		draw_line(p0, p1, Color(1.0, 0.98, 0.99, 0.43 * energy), width * 1.3, true)
		draw_line(p0, p1, Color(1.0, 1.0, 1.0, 0.96 * energy * shimmer), width * 0.66, true)
	# Feathered termination rather than a hard cut-off rectangle.
	var tip_glow: float = 18.0 + 8.0 * fade
	draw_circle(tip, tip_glow * 1.65, Color(rose.r, rose.g, rose.b, 0.055 * energy))
	draw_circle(tip, tip_glow, Color(secondary.r, secondary.g, secondary.b, 0.12 * energy))
	draw_circle(tip, tip_glow * 0.64, Color(1.0, 1.0, 1.0, 0.30 * energy))
	# Sparse colored silver flecks. Each cosmetic item uses its own two colors.
	for spark in range(9):
		var f: float = (float(spark) + 0.6) / 10.0
		var amp: float = (7.0 + float(spark % 3) * 3.5) * energy
		var w: float = sin(f * 18.0 + age * 13.0 + float(effect_seed % 17))
		var p: Vector2 = axis * (span * f) + normal * w * amp
		var c: Color = secondary if spark % 2 == 0 else rose
		draw_circle(p, 1.6 + (1.0 - f) * 1.3, Color(c.r, c.g, c.b, 0.45 * energy))
		if spark % 3 == 0:
			draw_line(p - normal * 3.0, p + normal * 3.0, Color(1.0, 1.0, 1.0, 0.46 * energy), 1.0, true)


# v1.56 — feathered three-stop magical highlights and rare cosmetic signatures.
# Everything below is drawing-only; one projectile still performs one hit event.
func _v156_ink(t: float) -> Color:
	var u: float = clampf(t, 0.0, 1.0)
	return effect_color.lerp(accent_color, u * 2.0) if u <= 0.5 else accent_color.lerp(gradient_c, (u - 0.5) * 2.0)

func _v156_soft_point(at: Vector2, color: Color, size: float, opacity: float) -> void:
	draw_circle(at, size * 1.8, Color(color.r, color.g, color.b, 0.016 * opacity))
	draw_circle(at, size * 1.1, Color(color.r, color.g, color.b, 0.038 * opacity))
	draw_circle(at, size * 0.55, Color(color.r, color.g, color.b, 0.13 * opacity))
	draw_circle(at, maxf(1.0, size * 0.20), Color(color.r, color.g, color.b, 0.30 * opacity))

func _draw_projectile_cosmetics(scale_factor: float) -> void:
	# A short, tapering, colour-shifting wake, not large geometric rings.
	var facing: Vector2 = direction.normalized() if direction.length_squared() > 0.01 else Vector2.RIGHT
	var side: Vector2 = Vector2(-facing.y, facing.x)
	for i in range(7):
		var u: float = float(i) / 6.0
		var c: Color = _v156_ink(u)
		var phase: float = age * 11.5 + float(i) * 1.7 + float(posmod(effect_seed, 31))
		var pos: Vector2 = -facing * (3.0 + u * 27.0) * scale_factor + side * sin(phase) * (1.5 + u * 3.0)
		_v156_soft_point(pos, c, (3.8 - 2.0 * u) * scale_factor, (0.65 - u * 0.44))
	# The tip stays light and readable, regardless of its random hue.
	_v156_soft_point(Vector2.ZERO, gradient_c.lerp(Color.WHITE, 0.42), 5.0 * scale_factor, 1.0)
	if rare_signature > 0:
		var orb_radius: float = (6.0 + float(rare_signature) * 1.4) * scale_factor
		var twist: float = age * (4.0 + float(rare_signature))
		for k in range(2 + rare_signature):
			var t: float = float(k) / float(2 + rare_signature)
			var theta: float = twist + t * TAU
			var pos: Vector2 = Vector2(cos(theta), sin(theta)) * orb_radius
			_v156_soft_point(pos, _v156_ink(t), 2.0 * scale_factor, 0.7)

func _draw_beam_cosmetics(endpoint: Vector2, fade: float) -> void:
	if fade <= 0.0:
		return
	var ortho: Vector2 = Vector2(-direction.y, direction.x).normalized()
	for i in range(16):
		var u: float = float(i) / 15.0
		var color: Color = _v156_ink(u)
		var position_on_beam: Vector2 = endpoint * u
		var spread: float = sin(u * 19.0 + age * 17.0 + float(posmod(effect_seed, 19))) * (2.0 + float(rare_signature) * 1.2) * sin(u * PI)
		_v156_soft_point(position_on_beam + ortho * spread, color, 3.0, fade * (0.3 + 0.7 * sin(u * PI)))
	_v156_soft_point(endpoint, gradient_c.lerp(Color.WHITE, 0.3), 10.0, fade)

func _draw_lance_cosmetics() -> void:
	var endpoint: Vector2 = to_local(beam_end)
	if endpoint.length_squared() < 1.0:
		return
	var fade: float = clampf(1.0 - age / LANCE_FADE, 0.0, 1.0)
	if fade <= 0.0:
		return
	var ortho: Vector2 = Vector2(-direction.y, direction.x).normalized()
	for i in range(12):
		var u: float = (float(i) + 0.5) / 12.0
		var c: Color = _v156_ink(u)
		var off: float = sin(u * 22.0 + age * 13.0) * (4.0 + float(rare_signature) * 1.6) * sin(u * PI)
		_v156_soft_point(endpoint * u + ortho * off, c, 3.1, fade * 0.75)
	_v156_soft_point(endpoint, gradient_c.lerp(Color.WHITE, 0.56), 9.0, fade)


# v1.68: Mythic wand spell skin, with four reproducible effects from the
# wand's cosmetic UID. The gameplay bolt/beam is still ONE damage query.
func _mythic_spell_ink(t: float) -> Color:
	var u: float = clampf(t, 0.0, 1.0)
	return effect_color.lerp(accent_color, u * 2.0) if u <= 0.5 else accent_color.lerp(gradient_c, (u - 0.5) * 2.0)

func _draw_mythic_spell_bolt(scale_factor: float) -> void:
	var heading: Vector2 = direction.normalized() if direction.length_squared() > 0.01 else Vector2.RIGHT
	var side: Vector2 = Vector2(-heading.y, heading.x)
	var ink: Color = _mythic_spell_ink(0.63)
	var pulse: float = 0.84 + 0.16 * sin(age * 18.0)
	# Luminous moontear core with a delicate pearl rim, unlike ordinary bolts.
	draw_circle(Vector2.ZERO, 11.0 * scale_factor, Color(ink.r, ink.g, ink.b, 0.055 * pulse))
	draw_circle(Vector2.ZERO, 5.0 * scale_factor, Color(ink.r, ink.g, ink.b, 0.21 * pulse))
	draw_circle(Vector2.ZERO, 2.5 * scale_factor, Color(1.0, 0.98, 1.0, 0.72 * pulse))
	for i in range(9):
		var u: float = float(i) / 8.0
		var fade: float = 1.0 - u
		var center: Vector2 = -heading * (5.0 + 37.0 * u) * scale_factor
		var bend: float = sin(age * 11.0 + u * TAU * 1.35 + float(mythic_layer_variant)) * (3.2 + u * 3.0) * scale_factor
		var c: Color = _mythic_spell_ink(u)
		for sign in [-1.0, 1.0]:
			var p: Vector2 = center + side * bend * sign
			draw_circle(p, (1.3 + 1.5 * fade) * scale_factor, Color(c.r, c.g, c.b, (0.08 + 0.10 * fade)))
	match mythic_layer_variant:
		0:  # Storm-spark — a fork on the moving head.
			for branch in [-1.0, 1.0]:
				var a: Vector2 = -heading * 7.0 * scale_factor + side * branch * 2.0 * scale_factor
				var b: Vector2 = a - heading * 4.0 * scale_factor + side * branch * 4.0 * scale_factor
				var c: Vector2 = b - heading * 5.0 * scale_factor - side * branch * 2.0 * scale_factor
				draw_line(a, b, Color(0.83, 0.94, 1.0, 0.46), 1.0, true)
				draw_line(b, c, Color(0.83, 0.94, 1.0, 0.28), 0.9, true)
		1:  # Ember satellite pearls.
			for i in range(3):
				var theta: float = age * 7.0 + TAU * float(i) / 3.0
				var p: Vector2 = Vector2(cos(theta), sin(theta)) * 8.5 * scale_factor
				var c: Color = _mythic_spell_ink(float(i) * 0.34)
				draw_circle(p, 1.5 * scale_factor, Color(c.r, c.g, c.b, 0.48))
		2:  # Fleeting lunar diamond.
			for i in range(4):
				var a: float = age * 2.5 + float(i) * PI * 0.5
				var p: Vector2 = Vector2.from_angle(a) * 7.2 * scale_factor
				draw_line(p, p * 1.34, Color(1.0, 0.96, 1.0, 0.22), 1.0, true)
		_:  # Flower-petal wake.
			for i in range(3):
				var u: float = float(i) / 3.0
				var p: Vector2 = -heading * (14.0 + 20.0 * u) * scale_factor + side * sin(age * 5.0 + u * TAU) * 6.5 * scale_factor
				draw_circle(p, 1.4 * scale_factor, Color(gradient_c.r, gradient_c.g, gradient_c.b, 0.30))

func _draw_mythic_spell_beam(endpoint: Vector2, opacity: float) -> void:
	if endpoint.length_squared() < 1.0 or opacity <= 0.0:
		return
	var axis: Vector2 = endpoint.normalized()
	var side: Vector2 = Vector2(-axis.y, axis.x)
	var length: float = endpoint.length()
	# Twin aurora ribbons that never spawn additional gameplay projectiles.
	for i in range(29):
		var u: float = float(i) / 28.0
		var c: Color = _mythic_spell_ink(u)
		var taper: float = sin(u * PI)
		var base: Vector2 = axis * length * u
		var wiggle: float = sin(u * TAU * 2.3 + age * 11.0 + float(mythic_layer_variant) * 0.7) * taper * 5.5
		for side_sign in [-1.0, 1.0]:
			var at: Vector2 = base + side * (side_sign * (2.1 + 2.4 * taper) + wiggle)
			draw_circle(at, 2.8, Color(c.r, c.g, c.b, 0.032 * opacity))
			draw_circle(at, 1.1, Color(c.r, c.g, c.b, 0.10 * opacity))
	var tip: Color = _mythic_spell_ink(0.85).lerp(Color.WHITE, 0.28)
	draw_circle(endpoint, 11.0 * opacity, Color(tip.r, tip.g, tip.b, 0.11 * opacity))
	draw_circle(endpoint, 3.0 * opacity, Color(1.0, 0.98, 1.0, 0.55 * opacity))
