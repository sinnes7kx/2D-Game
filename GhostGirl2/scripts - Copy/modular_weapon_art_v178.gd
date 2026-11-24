extends RefCounted
## v1.78: reusable opaque modular weapon art. The same profile can later
## be rendered by the inspection screen without a player or combat scene.
const SURFACE = preload("res://scripts/living_metal_v187.gd")
const LOOK = preload("res://scripts/collector_appearance_v177.gd")

static func profile(look: Dictionary, hand: int = 0) -> Dictionary:
	if look.is_empty():
		return {}
	var pattern: int = int(look.get("pattern", 0))
	var finish: int = int(look.get("finish", 0))
	var ornament: int = int(look.get("ornament", 0))
	var tier: int = int(look.get("material", 0))
	var metals: Array = look.get("metal_colors", [])
	var accents: Array = look.get("accent_colors", [])
	var handles: Array = look.get("handle_colors", [])
	if metals.size() < 3 or accents.size() < 3 or handles.size() < 3:
		return {}
	var tint: Color = GhostCosmeticRNGV152.sample_palette(metals, 0.23 + float(hand) * 0.54)
	var accent: Color = GhostCosmeticRNGV152.sample_palette(accents, 0.41 + float(hand) * 0.46)
	var grip: Color = GhostCosmeticRNGV152.sample_palette(handles, 0.72 - float(hand) * 0.44)
	var steel: Color = Color("b5b9ca").lerp(tint, 0.25 + float(tier) * 0.095)
	if finish == 1:
		steel = steel.darkened(0.42)
	elif finish == 2:
		steel = steel.lightened(0.28)
	elif finish == 3:
		steel = steel.lerp(Color("695468"), 0.35)
	return {
		"shape": pattern % 5, "width_scale": float(look.get("forge_width", 1.0)),
		"shoulder": float(look.get("forge_shoulder", 1.0)), "taper": float(look.get("forge_taper", 1.0)),
		"guard_style": int(look.get("forge_guard", 0)), "guard_span": float(look.get("forge_guard_span", 1.0)),
		"grip_style": int(look.get("forge_grip", 0)), "grip_width": float(look.get("forge_grip_width", 1.0)),
		"wrap_count": int(look.get("forge_wrap_count", 5)), "inset_style": int(look.get("forge_inset", 0)),
		"inset_scale": float(look.get("forge_inset_scale", 1.0)), "etch_style": int(look.get("forge_etch", 0)),
		"etch_count": int(look.get("forge_etch_count", 3)),
		"ornament_ink": GhostCosmeticRNGV152.sample_palette(look.get("forge_ornament_colors", accents), 0.35 + float(hand) * 0.30),
		"material": tier, "finish": finish, "ornament": ornament,
		"surface_mode": int(look.get("surface_mode", 0)),
		"surface_phase": float(look.get("surface_phase", 0.0)),
		"surface_speed": float(look.get("surface_speed", 0.5)),
		"surface_colors": look.get("surface_colors", metals),
		"metal": steel, "shade": steel.darkened(0.44), "edge": steel.lightened(0.63),
		"accent": accent, "grip": grip.darkened(0.58)
	}

# Cached on each rendering node. A reroll or saved-look restore invalidates
# the cache immediately without hashing every render frame.
static func equipped_profile(owner: Node, body: AnimatedSprite2D, hand: int = 0) -> Dictionary:
	if body == null:
		return {}
	var player: Node = body.get_parent()
	var world: Node = player.get("world") as Node if player != null else null
	var inventory: Node = world.get("inventory") as Node if world != null else null
	if inventory == null:
		return {}
	var item: GhostItemInstance = inventory.get_equipped("sword")
	if item == null:
		return {}
<<<<<<< Updated upstream
	var key: String = "%s:%s:%s:%s:%s:%s:%s:%s:%s:%s" % [item.get_instance_id(), item.cosmetic_uid, item.visual_seed(), hand, item.debug_collector_tier, item.debug_surface_mode, item.origin_room, item.regional_rank, item.debug_forge_guard, item.debug_forge_grip]
=======
	var key: String = "%s:%s:%s:%s:%s" % [item.get_instance_id(), item.cosmetic_uid, item.visual_seed(), hand, item.debug_collector_tier]
>>>>>>> Stashed changes
	if str(owner.get_meta("v178_profile_key", "")) != key:
		owner.set_meta("v178_profile_key", key)
		owner.set_meta("v178_profile", weapon_profile(item.collector_appearance(), str(item.definition.item_id), hand))
	return owner.get_meta("v178_profile", {}) as Dictionary

# Both edges terminate at the exact authored point. All profiles stay
# slender and pointed, never recreate the old club-shaped twinblade heads.
static func edge_points(root: Vector2, tip: Vector2, base_width: float, p: Dictionary, side: float) -> PackedVector2Array:
	var axis: Vector2 = (tip - root).normalized()
	var normal: Vector2 = Vector2(-axis.y, axis.x)
	var w: float = base_width * float(p.get("width_scale", 1.0))
	var factors: Array[float] = [1.0, 0.95, 0.72]
	match int(p.get("shape", 0)):
		1: factors = [0.7, 1.0, 0.48] # leaf
		2: factors = [1.0, 0.68, 0.42] # needle
		3: factors = [0.8, 0.82, 0.90] # long sabre edge
		4: factors = [1.0, 0.55, 0.88] # sculpted waist
	factors[1] *= float(p.get("shoulder", 1.0))
	factors[2] *= float(p.get("taper", 1.0))
	return PackedVector2Array([root + normal * w * factors[0] * side, root.lerp(tip, 0.30) + normal * w * factors[1] * side, root.lerp(tip, 0.76) + normal * w * factors[2] * side, tip])

static func draw_grip(canvas: Node2D, start: Vector2, end: Vector2, width: float, p: Dictionary) -> void:
	var axis: Vector2 = (end - start).normalized()
	var normal: Vector2 = Vector2(-axis.y, axis.x)
	var tint: Color = p["grip"]
	var trim: Color = p.get("ornament_ink", p["accent"])
	var w: float = width * float(p.get("grip_width", 1.0))
	var style: int = int(p.get("grip_style", 0))
	var count: int = int(p.get("wrap_count", 5))
	canvas.draw_line(start, end, Color("211b29"), w + 1.6, true)
	canvas.draw_line(start, end, tint, w, true)
	for i in range(count):
		var at: Vector2 = start.lerp(end, float(i + 1) / float(count + 1))
		var n: Vector2 = normal * w * 0.43
		match style:
			0: # angled leather wrap
				canvas.draw_line(at - n, at + n + axis * 1.1, tint.lightened(0.32), 0.75, true)
			1: # alternating metal collars
				canvas.draw_line(at - n, at + n, trim.darkened(0.12), 1.1 if i % 2 == 0 else 0.55, true)
			2: # crossed silk lacing
				canvas.draw_line(at - n - axis, at + n + axis, trim, 0.6, true)
				canvas.draw_line(at + n - axis, at - n + axis, trim.darkened(0.25), 0.6, true)
			3: # narrow central inlay
				canvas.draw_line(at - axis, at + axis, trim, 0.9, true)
			4: # riveted dark leather
				canvas.draw_circle(at + n * (0.55 if i % 2 == 0 else -0.55), 0.65, trim)
			5: # carved segmented grip
				canvas.draw_line(at - n, at + n, tint.darkened(0.4), 0.8, true)
				canvas.draw_line(at - n + axis, at + n + axis, tint.lightened(0.28), 0.5, true)
	# Tiny collars stay inside the handle endpoints; no protruding club heads.
	for at in [start.lerp(end, 0.07), start.lerp(end, 0.93)]:
		canvas.draw_line(at - normal * w * 0.55, at + normal * w * 0.55, trim, 1.0, true)

static func draw_blade(canvas: Node2D, root: Vector2, tip: Vector2, width: float, p: Dictionary, phase: float = -1.0) -> void:
	if root.distance_squared_to(tip) < 16.0 or p.is_empty():
		return
	var left: PackedVector2Array = edge_points(root, tip, width, p, -1.0)
	var right: PackedVector2Array = edge_points(root, tip, width, p, 1.0)
	var outline: PackedVector2Array = PackedVector2Array([left[0], left[1], left[2], tip, right[2], right[1], right[0]])
	var steel: Color = p["metal"]
	var shade: Color = p["shade"]
	var edge: Color = p["edge"]
	var accent: Color = p["accent"]
	canvas.draw_colored_polygon(outline, steel)
	canvas.draw_colored_polygon(PackedVector2Array([root, tip, right[2], right[1], right[0]]), shade)
	var time: float = float(Time.get_ticks_msec() % 3600000) / 1000.0 if phase < 0.0 else phase
	SURFACE.draw_surface(canvas, left, right, p, time)
	canvas.draw_polyline(left, edge, 0.85, true)
	canvas.draw_polyline(right, edge.darkened(0.18), 0.7, true)
	canvas.draw_line(root, tip, edge, 0.55, true)
	var axis: Vector2 = (tip - root).normalized()
	var normal: Vector2 = Vector2(-axis.y, axis.x)
<<<<<<< Updated upstream
	# Every etching is sampled from the real cross section, so narrow blades
	# cannot have floating markings. Separate from surface and glow rolls.
	var ink: Color = p.get("ornament_ink", accent)
	var count: int = int(p.get("etch_count", 3))
	var etch: int = int(p.get("etch_style", 0))
	for i in range(count):
		var u: float = 0.19 + float(i) * 0.57 / float(count)
		var l: Vector2 = SURFACE.at_edge(left, u)
		var r: Vector2 = SURFACE.at_edge(right, u)
		var at: Vector2 = l.lerp(r, 0.5)
		var extent: float = l.distance_to(r) * 0.22
		var mark: Color = ink.lerp(steel, 0.35)
		match etch:
			0: canvas.draw_line(at - normal * extent, at + normal * extent, mark, 0.6, true)
			1: canvas.draw_polyline(PackedVector2Array([at - normal * extent - axis, at + axis, at + normal * extent - axis]), mark, 0.7, true)
			2: canvas.draw_circle(at, minf(0.85, extent), mark)
			3: canvas.draw_line(at - axis * 1.3, at + axis * 1.3, mark, 0.65, true)
			4: canvas.draw_polyline(PackedVector2Array([at - normal * extent, at + axis, at + normal * extent, at - axis, at - normal * extent]), mark, 0.55, true)
	_draw_guard(canvas, root, axis, normal, width, p)

static func _draw_guard(canvas: Node2D, root: Vector2, axis: Vector2, normal: Vector2, width: float, p: Dictionary) -> void:
	var edge: Color = p["edge"]
	var trim: Color = p.get("ornament_ink", p["accent"])
	var span: float = width * float(p.get("guard_span", 1.0)) * 1.45
	var style: int = int(p.get("guard_style", 0))
	var inset: int = int(p.get("inset_style", 0))
	var size: float = minf(2.2, width * 0.42) * float(p.get("inset_scale", 1.0))
	canvas.draw_line(root - normal * span, root + normal * span, edge.darkened(0.25), 1.6, true)
	for side in [-1.0, 1.0]:
		var tip: Vector2 = root + normal * span * side
		var inner: Vector2 = root + normal * span * side * 0.42
		match style:
			0: canvas.draw_line(inner, tip, trim, 0.85, true)
			1: canvas.draw_polyline(PackedVector2Array([inner, tip - axis * 1.7, tip - axis * 3.0 + normal * side]), trim, 1.1, true)
			2: canvas.draw_polyline(PackedVector2Array([inner, tip + axis * 2.2, tip + axis * 4.0 - normal * side]), trim, 1.05, true)
			3: canvas.draw_colored_polygon(PackedVector2Array([inner, tip, tip - axis * 2.8, root - axis]), trim.darkened(0.15))
			4: canvas.draw_arc(inner, minf(span * 0.38, 2.8), axis.angle(), axis.angle() + PI * 1.65, 12, trim, 0.85, true)
			5: canvas.draw_polyline(PackedVector2Array([root, inner + axis * 2.0, tip, inner - axis * 2.0, root]), trim, 0.8, true)
			6: canvas.draw_polyline(PackedVector2Array([inner, tip - axis, tip + axis * 2.2]), trim, 1.0, true)
			7: canvas.draw_circle(tip, minf(1.35, width * 0.30), trim)
	if inset == 0:
		return
	var center: Vector2 = root - axis * 1.8
	match inset:
		1: canvas.draw_circle(center, size, trim)
		2: canvas.draw_colored_polygon(PackedVector2Array([center - axis * size, center + normal * size, center + axis * size, center - normal * size]), trim)
		3: canvas.draw_arc(center, size, 0.0, TAU, 16, trim, 0.8, true)
		4:
			canvas.draw_circle(center - normal * size * 0.6, size * 0.54, trim)
			canvas.draw_circle(center + normal * size * 0.6, size * 0.54, trim)
		5: canvas.draw_colored_polygon(PackedVector2Array([center + axis * size, center - axis * size + normal * size, center - axis * size - normal * size]), trim)
		6:
			canvas.draw_circle(center, size, trim.darkened(0.30))
			canvas.draw_circle(center - axis * size * 0.3, size * 0.42, trim.lightened(0.55))
=======
	var tier: int = int(p["material"])
	var finish: int = int(p["finish"])
	# Etching / facets are opaque surface marks, not glow.
	for i in range(2 + tier):
		var at: Vector2 = root.lerp(tip, 0.18 + float(i) * 0.58 / float(2 + tier))
		var extent: float = width * (0.18 + float(finish % 3) * 0.07)
		canvas.draw_line(at - normal * extent, at + normal * extent + axis * 1.1, accent.lerp(steel, 0.38), 0.7, true)
	# Nine ornament rolls independently alter guard profile and inset.
	var ornament: int = int(p["ornament"])
	var guard: float = width * (1.25 + float(ornament % 3) * 0.25)
	canvas.draw_line(root - normal * guard, root + normal * guard, edge.darkened(0.12), 1.6, true)
	if ornament >= 3:
		var sweep: float = -2.0 if ornament < 6 else 2.0
		for side in [-1.0, 1.0]:
			var at: Vector2 = root + normal * guard * side
			canvas.draw_line(at, at + axis * sweep - normal * side, edge, 1.0, true)
	if ornament % 3 != 0:
		canvas.draw_circle(root - axis * 1.5, 1.4 + float(ornament % 3) * 0.35, accent)
>>>>>>> Stashed changes

# Distinct base silhouette families: Eclipse is a narrow needle, Rosemirror
# is a slender leaf with an ornate swept guard. Rolls still change widths/colors.
static func weapon_profile(look: Dictionary, item_id: String, hand: int = 0) -> Dictionary:
	var p: Dictionary = profile(look, hand)
	if p.is_empty():
		return p
	if item_id == "eclipse_twinblade_v170":
		p["shape"] = 2
		p["width_scale"] = float(p["width_scale"]) * 0.94
	elif item_id == "rosemirror_twinblade_v170":
		p["shape"] = 1
		p["width_scale"] = float(p["width_scale"]) * 1.02
		p["ornament"] = 6 + int(p["ornament"]) % 3
	return p

# Single source for the target double-ended sword silhouette. Both equipped
# and display models use these exact endpoints, with no old crystal-head art.
static func twinblade_width(rose: bool) -> float:
	return 5.8 if rose else 4.6

static func twinblade_spans(grip: Vector2, tip: Vector2) -> Array[PackedVector2Array]:
	var rear: Vector2 = grip - (tip - grip) * 0.90
	return [PackedVector2Array([grip.lerp(tip, 0.16), tip]), PackedVector2Array([grip.lerp(rear, 0.18), rear])]
<<<<<<< Updated upstream

# Apply only to a weapon-specific CanvasItem, not the parent body.
static func apply_equipped_opacity(canvas: Node2D, body: AnimatedSprite2D) -> void:
	var player: Node = body.get_parent() if body != null else null
	var world: Node = player.get("world") as Node if player != null else null
	var inventory: Node = world.get("inventory") as Node if world != null else null
	var item: GhostItemInstance = inventory.get_equipped("sword") if inventory != null else null
	canvas.self_modulate.a = item.weapon_opacity() if item != null else 1.0

# Only request animated surface redraws for the actual equipped weapon layer.
# Cached profiles are reused; no new rolls or per-frame hashing.
static func surface_is_animated(owner: Node, body: AnimatedSprite2D, hand: int = 0) -> bool:
	var p: Dictionary = equipped_profile(owner, body, hand)
	return not p.is_empty() and SURFACE.animated(int(p.get("surface_mode", 0)))
=======
>>>>>>> Stashed changes
