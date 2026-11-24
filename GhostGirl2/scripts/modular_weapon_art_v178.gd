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
	var tint: Color = metals[posmod(hand, 3)]
	var accent: Color = accents[posmod(hand + 1, 3)]
	var grip: Color = handles[posmod(hand + 2, 3)]
	var steel: Color = Color("b5b9ca").lerp(tint, 0.25 + float(tier) * 0.095)
	if finish == 1:
		steel = steel.darkened(0.42)
	elif finish == 2:
		steel = steel.lightened(0.28)
	elif finish == 3:
		steel = steel.lerp(Color("695468"), 0.35)
	return {
		"shape": pattern % 5, "width_scale": 0.78 + float(pattern % 4) * 0.16,
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
	var key: String = "%s:%s:%s:%s:%s:%s:%s:%s" % [item.get_instance_id(), item.cosmetic_uid, item.visual_seed(), hand, item.debug_collector_tier, item.debug_surface_mode, item.origin_room, item.regional_rank]
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
	return PackedVector2Array([root + normal * w * factors[0] * side, root.lerp(tip, 0.30) + normal * w * factors[1] * side, root.lerp(tip, 0.76) + normal * w * factors[2] * side, tip])

static func draw_grip(canvas: Node2D, start: Vector2, end: Vector2, width: float, p: Dictionary) -> void:
	var axis: Vector2 = (end - start).normalized()
	var normal: Vector2 = Vector2(-axis.y, axis.x)
	var tint: Color = p["grip"]
	canvas.draw_line(start, end, Color("211b29"), width + 2.0, true)
	canvas.draw_line(start, end, tint, width, true)
	var finish: int = int(p["finish"])
	for i in range(4 + finish % 4):
		var at: Vector2 = start.lerp(end, float(i + 1) / float(5 + finish % 4))
		canvas.draw_line(at - normal * width * 0.40, at + normal * width * 0.40 + axis * float(finish % 2), tint.lightened(0.32), 0.8, true)

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
