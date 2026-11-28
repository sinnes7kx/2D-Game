extends Node2D
const RENDER = preload("res://scripts/animation/weapon_render_contract.gd")
var render_phase: float = 0.0
const GENTLE = preload("res://scripts/gentle_weapon_motion_v191.gd")
const MODULAR = preload("res://scripts/modular_weapon_art_v178.gd")
## v1.73 per-hand drawing over Ghost Girl's approved unchanged 2D body.
## This is art-only: never creates a collider, damage trigger or projectile.
@export_range(0, 1, 1) var blade_index: int = 0
var rig: Node2D = null
var body: AnimatedSprite2D = null
var last_animation: String = ""
var last_frame: int = -1
var last_active: bool = false

func _ready() -> void:
	rig = get_parent() as Node2D
	body = rig.get_parent() as AnimatedSprite2D if rig != null else null
	set_process(true)

func _process(_delta: float) -> void:
	render_phase+=_delta
	if rig == null or body == null:
		return
	MODULAR.apply_equipped_opacity(self, body)
	var animation_name: String = str(body.animation)
	var active: bool = bool(rig.call("is_active", animation_name))
	if active and (RENDER.effect_scale(RENDER.equipped(body))>0.0 or animation_name.begins_with("attack_") or GENTLE.modular_idle(animation_name) or MODULAR.surface_is_animated(self, body, blade_index)):
		queue_redraw()
	if animation_name != last_animation or body.frame != last_frame or active != last_active:
		last_animation = animation_name
		last_frame = body.frame
		last_active = active
		z_index=RENDER.paired_layer(animation_name,blade_index)

		queue_redraw()

func _draw() -> void:
	if rig == null or body == null:
		return
	var blades: Array = rig.call("get_blade_spans", str(body.animation), body.frame)
	if blades.size() != 2:
		return
	var span: PackedVector2Array = blades[blade_index]
	if span.size() != 2:
		return
	var grip: Vector2 = span[0]
	var point: Vector2 = span[1]
	var axis: Vector2 = point - grip
	if axis.length_squared() < 64.0:
		return
	var tangent: Vector2 = axis.normalized()
	var normal: Vector2 = Vector2(-tangent.y, tangent.x)
	var guard: Vector2 = grip + tangent * 9.0
	var steel: Vector2 = grip + tangent * 12.0
	var look: Dictionary = MODULAR.equipped_profile(self, body, blade_index)
	if not look.is_empty():
		var geometry: Dictionary=RENDER.straight_geometry("dual_dagger",span,blade_index)
		RENDER.draw_straight(self,geometry,look,render_phase)
		RENDER.draw_owned_light(self,body,geometry,look,render_phase)
		return
	var steel_tone: Color = Color("3c384d") if blade_index == 0 else Color("403047")
	var edge: Color = Color("c7c3de") if blade_index == 0 else Color("e5aec5")
	var glass: Color = Color("8c6fba") if blade_index == 0 else Color("b17895")
	# Distinct ornate wrapped hilts with a bright thorn-shaped hand guard.
	draw_line(grip - tangent * 9.0, guard, Color("211b2d"), 6.0, true)
	draw_line(grip - tangent * 7.0, guard - tangent * 3.0, Color("6d5c76"), 3.5, true)
	for wrap_i in range(3):
		var at: Vector2 = grip - tangent * (4.5 - float(wrap_i) * 3.1)
		draw_line(at - normal * 2.2, at + normal * 2.2, Color("c2a3b8"), 0.9, true)
	draw_line(guard - normal * 8.2 - tangent * 2.0, guard + normal * 8.2 - tangent * 2.0, Color("bca4ba"), 2.8, true)
	draw_circle(guard - tangent * 2.0, 2.8, glass)
	# Physically tapered cutting edge, transparent away from blade contour.
	draw_colored_polygon(PackedVector2Array([
		steel - normal * 3.5,
		steel.lerp(point, 0.24) - normal * 4.2,
		point,
		steel.lerp(point, 0.26) + normal * 2.2,
		steel + normal * 1.4
	]), steel_tone)
	draw_line(steel - normal * 2.0, point, edge, 1.55, true)
	draw_line(steel + normal * 1.1, point - tangent * 2.0, glass.lightened(0.25), 0.85, true)
	draw_circle(grip - tangent * 7.0, 3.4, Color("d0becd"))
