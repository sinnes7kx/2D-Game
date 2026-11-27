extends RefCounted
## Shared geometry for the Lunar Vigil Halberd and both warmauls.
## The shaft stays anchored to the existing weapon-free body pose.
const ART = preload("res://scripts/modular_weapon_art_v178.gd")
const SCYTHE = preload("res://scripts/scythe_art_v190.gd")
const SURFACE = preload("res://scripts/living_metal_v187.gd")
const FX = preload("res://scripts/anomalous_steel_fx_v180.gd")
const HAND = preload("res://scripts/dagger_thrust_v186.gd")
const GENTLE = preload("res://scripts/gentle_weapon_motion_v191.gd")
const BLUNT_V203 = preload("res://scripts/blunt_weapon_family_v203.gd")
const FORGED = preload("res://scripts/forged_polearm_v255.gd")
const FX_LEVEL = preload("res://scripts/fx_intensity_v1924.gd")

static func matches(name: String) -> bool:
	return name.begins_with("halberd_") or name.begins_with("attack_halberd_") or name.begins_with("maul_") or name.begins_with("attack_maul_") or name.begins_with("ashglass_maul_") or name.begins_with("attack_ashglass_maul_")

static func source_frame(name: String, frame: int) -> int:
	return 0 if name.contains("_idle_") else SCYTHE.source_frame(name, frame)

static func install(sprite: AnimatedSprite2D) -> void:
	var frames: SpriteFrames = sprite.sprite_frames
	if frames == null:
		return
	for value in frames.get_animation_names():
		var name: String = str(value)
		if not matches(name):
			continue
		var face: String = name.get_slice("_", name.get_slice_count("_") - 1)
		var source: String = "attack_unarmed_light_" + face
		if not frames.has_animation(source) or frames.get_frame_count(source) < 8:
			continue
		for i in range(frames.get_frame_count(name)):
			frames.set_frame(name, i, frames.get_frame_texture(source, source_frame(name,i)), frames.get_frame_duration(name,i))

static func span(name: String, frame: int, guides: Dictionary) -> PackedVector2Array:
	if not matches(name):
		return PackedVector2Array()
	var diagonal: PackedVector2Array = preload("res://scripts/ghost_diagonal_art_v247.gd").carried_span(name,frame,82.0 if name.contains("halberd") else 70.0,true)
	if diagonal.size() == 2:
		return diagonal
	var face: String = name.get_slice("_",name.get_slice_count("_")-1)
	var anchor: Vector2 = HAND.hand_anchor(face,source_frame(name,frame),0 if face == "left" else 1)
	if anchor == Vector2.INF:
		if face != "back":
			return PackedVector2Array()
		anchor = Vector2(34,27)
	var direction: Vector2 = Vector2(-0.62 if face == "left" else 0.62,-0.78)
	var guide_key: String = name.replace("_air_", "_") if name.contains("_air_") else name
	var rows: Array = guides.get(guide_key,[])
	if not rows.is_empty():
		var line: Array = rows[clampi(frame,0,rows.size()-1)]
		if line.size() == 4:
			var heading: Vector2 = Vector2(float(line[2])-float(line[0]),float(line[3])-float(line[1]))
			if heading.length_squared() > 16.0:
				direction = heading.normalized()
	return PackedVector2Array([anchor, anchor + direction.normalized() * (82.0 if name.contains("halberd") else 70.0)])

static func halberd_outline(head: Vector2, axis: Vector2, p: Dictionary, side: float = 1.0) -> PackedVector2Array:
	var n: Vector2 = Vector2(-axis.y,axis.x)*side
	var width: float = 21.0 * float(p.get("heavy_head_span",1.0))
	var flare: float = float(p.get("heavy_head_flare",1.0))
	return PackedVector2Array([head-axis*13.0,head-axis*19.0+n*width*0.90,head-axis*6.0+n*width*flare,head+axis*8.0+n*width,head+axis*13.0+n*width*0.45,head+axis*7.0])

static func maul_outline(head: Vector2, axis: Vector2, p: Dictionary, ashglass: bool) -> PackedVector2Array:
	var n: Vector2 = Vector2(-axis.y,axis.x)
	var half_width: float = (14.0 if ashglass else 12.0)*float(p.get("heavy_head_span",1.0))
	var depth: float = (10.0 if ashglass else 12.0)*float(p.get("heavy_head_flare",1.0))
	var bevel: float = 3.5 if ashglass else 2.2
	return PackedVector2Array([head-axis*depth-n*(half_width-bevel),head-axis*(depth-bevel)-n*half_width,head+axis*(depth-bevel)-n*half_width,head+axis*depth-n*(half_width-bevel),head+axis*depth+n*(half_width-bevel),head+axis*(depth-bevel)+n*half_width,head-axis*(depth-bevel)+n*half_width,head-axis*depth+n*(half_width-bevel)])

static func draw_heavy(canvas: Node2D, grip: Vector2, head: Vector2, p: Dictionary, look: Dictionary, colors: Array[Color], phase: float, style: String, ashglass: bool, side: float, glow: bool, item_id: String = "") -> void:
	if p.is_empty() or grip.distance_squared_to(head)<16.0:
		return
	var blunt_kind: String = BLUNT_V203.kind_from_id(item_id)
	if style == "maul" and not blunt_kind.is_empty():
		BLUNT_V203.draw_blunt(canvas, grip, head, p, look, colors, phase, blunt_kind, glow)
		if glow:
			BLUNT_V203.draw_seeded_aura(canvas, head, colors, look, phase)
		return
	var axis: Vector2 = (head-grip).normalized()
	var n: Vector2 = Vector2(-axis.y,axis.x)
	var foot: Vector2 = grip-axis*(29.0 if style=="halberd" else 26.0)
	var trim: Color = p["ornament_ink"]
	canvas.draw_line(foot,head,Color("211b29"),5.6,true)
	canvas.draw_line(foot,head,Color(p["grip"]).lerp(Color("594239"),0.30) if style == "maul" else p["grip"],3.8,true)
	if style == "maul":
		canvas.draw_line(head-axis*17.0,head-axis*6.0,Color("3c3a40"),7.0,true)
		canvas.draw_line(head-axis*16.0+n*2.7,head-axis*7.0+n*2.7,Color("88858a"),0.8,true)
	ART.draw_grip(canvas,grip-axis*9.0,grip+axis*9.0,4.3,p)
	canvas.draw_line(foot-n*3.0,foot+n*3.0,trim,1.7,true)
	if style=="halberd":
		FORGED.draw_haft(canvas,foot,grip,head,4.0,p)
		var outline: PackedVector2Array = halberd_outline(head,axis,p,side)
		var center: Vector2 = head-axis*3.0+n*side*6.0
		for i in range(outline.size()):
			var ink: Color = SURFACE.surface_color(p,float(i)/float(outline.size()),0.25 if i%2==0 else 0.75,phase)
			canvas.draw_colored_polygon(PackedVector2Array([center,outline[i],outline[(i+1)%outline.size()]]),ink)
		var edge: PackedVector2Array = PackedVector2Array([outline[1],outline[2],outline[3],outline[4]])
		for i in range(edge.size()-1):
			var a: Vector2 = edge[i]
			var b: Vector2 = edge[i+1]
			var ink: Color = SURFACE.surface_color(p,float(i)/3.0,0.25,phase)
			canvas.draw_polygon(PackedVector2Array([a,b,b.lerp(center,0.18),a.lerp(center,0.18)]),PackedColorArray([p["edge"],p["edge"],ink,ink]))
		canvas.draw_polyline(edge,Color(p["edge"]).lerp(p["metal"],0.22),0.65,true)
		ART.draw_blade(canvas,head-axis*3.0,head+axis*22.0,3.7,p,phase)
		var hook: PackedVector2Array = PackedVector2Array([head-axis*9.0,head-axis*12.0-n*side*12.0,head+axis*5.0-n*side*5.0])
		canvas.draw_colored_polygon(hook,p["shade"])
		canvas.draw_polyline(hook,Color(p["shade"]).darkened(0.20),0.85,true)
		canvas.draw_line(hook[1],hook[2],Color(p["edge"]).lerp(p["metal"],0.40),0.7,true)
		if glow:
			FX.draw_edge(canvas,edge,colors,look,phase,0.66)
	else:
		var outline: PackedVector2Array = maul_outline(head,axis,p,ashglass)
		for i in range(outline.size()):
			var ink: Color = SURFACE.surface_color(p,float(i)/float(outline.size()),0.25 if i%2==0 else 0.75,phase)
			canvas.draw_colored_polygon(PackedVector2Array([head,outline[i],outline[(i+1)%outline.size()]]),ink)
		var closed: PackedVector2Array = outline.duplicate()
		closed.append(outline[0])
		canvas.draw_polyline(closed,p["edge"],0.9,true)
		# Recessed central socket and forged striking faces, not a jeweled block.
		var metal: Color = SURFACE.surface_color(p,0.52,0.55,phase).lerp(Color("65676c"),0.48)
		var socket: PackedVector2Array = PackedVector2Array([head-axis*5.0-n*5.0,head+axis*5.0-n*5.0,head+axis*5.0+n*5.0,head-axis*5.0+n*5.0])
		canvas.draw_colored_polygon(socket,metal.darkened(0.45))
		canvas.draw_line(socket[0],socket[1],metal.lightened(0.26),0.7,true)
		for edge_index in [1,5]:
			var a: Vector2 = outline[edge_index]
			var b: Vector2 = outline[edge_index+1]
			canvas.draw_line(a.lerp(b,0.12),a.lerp(b,0.88),metal.lightened(0.22),1.2,true)
		for sign_value in [-1.0,1.0]:
			var rivet: Vector2 = head+n*sign_value*7.0
			canvas.draw_circle(rivet,1.6,metal.darkened(0.5))
			canvas.draw_circle(rivet-axis*0.4,0.65,metal.lightened(0.25))

		if glow and FX_LEVEL.intensity > 0.0:
			# Illuminate the complete head silhouette, not only one side.
			# The shaft stays faint so the actual maul shape remains dominant.
			var halo: Color = FX.color_at(colors, look, 0.65, phase)
			var outer_halo: Color = Color(halo.r, halo.g, halo.b, FX_LEVEL.alpha(0.10))
			canvas.draw_polyline(closed, outer_halo, 9.2, true)
			canvas.draw_polyline(closed, Color(halo.r, halo.g, halo.b, FX_LEVEL.alpha(0.22)), 3.5, true)
			canvas.draw_line(foot, head, Color(halo.r, halo.g, halo.b, FX_LEVEL.alpha(0.085)), 7.0, true)
			FX.draw_edge(canvas, closed, colors, look, phase, 0.90)
			FX.draw_signature(canvas, closed, colors, look, phase)
			BLUNT_V203.draw_seeded_aura(canvas, head, colors, look, phase)
