extends Node2D
const MODULAR = preload("res://scripts/modular_weapon_art_v178.gd")
## v1.74: two long, sharp Gothic weapons, one in each hand.
## All drawn geometry follows v174_dual_swords.gd per-frame blade positions.
## No hitbox, collider, gameplay roll or save mutations occur in this layer.
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
	if rig == null or body == null:
		return
	MODULAR.apply_equipped_opacity(self, body)
	var animation_name: String = str(body.animation)
	var active: bool = bool(rig.call("is_active", animation_name))
	if active and MODULAR.surface_is_animated(self, body, blade_index):
		queue_redraw()
	if animation_name != last_animation or body.frame != last_frame or active != last_active:
		last_animation = animation_name
		last_frame = body.frame
		last_active = active
		var back: bool = animation_name.ends_with("back")
		var left: bool = animation_name.ends_with("left")
		var right: bool = animation_name.ends_with("right")
		# Far hand goes behind her dress when side-facing.
		z_index = -2 if back or (left and blade_index == 1) or (right and blade_index == 0) else 6
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
	if axis.length_squared() < 160.0:
		return
	var tangent: Vector2 = axis.normalized()
	var normal: Vector2 = Vector2(-tangent.y, tangent.x)
	# Longer enclosed pommel and a delicate crossed rose-shaped handguard.
	var guard: Vector2 = grip + tangent * 10.0
	var blade_root: Vector2 = guard + tangent * 5.0
	var blade_tip: Vector2 = point + tangent * 2.0
	var look: Dictionary = MODULAR.equipped_profile(self, body, blade_index)
	if not look.is_empty():
		MODULAR.draw_grip(self, grip - tangent * 9.0, blade_root, 5.1, look)
		MODULAR.draw_blade(self, blade_root, blade_tip, 5.2 if blade_index == 0 else 4.8, look)
		return
	var wrap: Color = Color("655266") if blade_index == 0 else Color("754c5e")
	var metal: Color = Color("74738c") if blade_index == 0 else Color("682e49")
	var second_metal: Color = Color("ddd5e4") if blade_index == 0 else Color("be6384")
	var edge: Color = Color("fff4f5") if blade_index == 0 else Color("f5c3d4")
	var jewel: Color = Color("9c98da") if blade_index == 0 else Color("d87f99")
	# Original high-detail handles and their winding wraps stay unlit.
	draw_circle(grip - tangent * 9.5, 4.7, Color("2e2231"))
	draw_circle(grip - tangent * 9.5, 2.4, second_metal)
	draw_line(grip - tangent * 8.5, guard, Color("221a29"), 8.0, true)
	draw_line(grip - tangent * 7.0, guard - tangent * 2.0, wrap, 5.1, true)
	for wrap_i in range(5):
		var at: Vector2 = grip - tangent * (5.2 - float(wrap_i) * 3.4)
		draw_line(at - normal * 2.6, at + normal * 2.6, Color("bca1ab"), 0.95, true)
	# Rose-hook-like guard is asymmetric to avoid a flat cross-shaped blade icon.
	draw_line(guard - normal * 12.0 - tangent * 3.0, guard + normal * 10.4 - tangent * 1.0, second_metal, 3.3, true)
	draw_line(guard - normal * 12.0 - tangent * 3.0, guard - normal * 10.0 - tangent * 7.5, second_metal, 2.1, true)
	draw_line(guard + normal * 10.4 - tangent * 1.0, guard + normal * 7.3 + tangent * 3.9, second_metal, 1.9, true)
	draw_circle(guard - tangent * 0.8, 3.8, jewel)
	# Narrow and dangerous pointed blade, broadened slightly at lower third.
	# The two steel families have genuinely different physical proportions.
	var lower_width: float = 5.3 if blade_index == 0 else 6.6
	var belly_width: float = 7.2 if blade_index == 0 else 5.0
	var belly: Vector2 = blade_root.lerp(blade_tip, 0.32)
	var high: Vector2 = blade_root.lerp(blade_tip, 0.72)
	draw_colored_polygon(PackedVector2Array([
		blade_root - normal * lower_width,
		belly - normal * belly_width,
		high - normal * (belly_width * 0.52),
		blade_tip,
		high + normal * 1.6,
		belly + normal * (lower_width * 0.46),
		blade_root + normal * (lower_width * 0.42)
	]), metal)
	draw_line(blade_root - normal * (lower_width * 0.65), belly - normal * (belly_width * 0.47), second_metal, 1.6, true)
	draw_line(belly - normal * (belly_width * 0.47), blade_tip, edge, 1.45, true)
	draw_line(blade_root + normal * 0.8, blade_tip - tangent * 3.0, second_metal, 0.9, true)
	# Fine fuller/grind line emphasizes the physical blade rather than a glow bar.
	draw_line(blade_root.lerp(blade_tip, 0.12), blade_root.lerp(blade_tip, 0.72), Color("f2cadb") if blade_index == 1 else Color("dfdce8"), 0.8, true)
