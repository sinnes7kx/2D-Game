extends Node2D
## v1.72.2 — authored four-facing weapon strike poses.
## Uses the approved unarmed attack BODY frames; renders physical weapon
## geometry at eight authored poses per action, not stretched inventory icons.
## Glow reads get_weapon_span(), so light and the painted weapon cannot drift.
const STILETTO: String = "nocturne_stiletto_v171"
const TRIDENT: String = "briarwake_trident_v171"
var body: AnimatedSprite2D = null
var player: Node2D = null

static func install_attack_frames(sprite: AnimatedSprite2D) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	var frames: SpriteFrames = sprite.sprite_frames
	for weapon_art in ["nocturne_dagger", "briarwake_spear"]:
		for attack in ["light", "heavy"]:
			for face in ["front", "back", "left", "right"]:
				var base_name: String = "attack_" + attack + "_" + face
				var target: String = "attack_" + weapon_art + "_" + attack + "_" + face
				if not frames.has_animation(base_name):
					push_warning("Missing clean approved attack body: " + base_name)
					continue
				if frames.has_animation(target):
					frames.remove_animation(target)
				frames.add_animation(target)
				frames.set_animation_speed(target, 17.0 if weapon_art == "nocturne_dagger" else 12.0)
				frames.set_animation_loop(target, false)
				for i in range(frames.get_frame_count(base_name)):
					frames.add_frame(target, frames.get_frame_texture(base_name, i))

func _ready() -> void:
	body = get_parent() as AnimatedSprite2D
	player = body.get_parent() as Node2D if body != null else null
	z_as_relative = true
	z_index = 5
	set_process(true)

func _process(_delta: float) -> void:
	if body == null:
		return
	if str(body.animation).begins_with("attack_nocturne_dagger_") or str(body.animation).begins_with("attack_briarwake_spear_"):
		queue_redraw()

func _is_equipped(animation_name: String) -> bool:
	if player == null or player.get("world") == null:
		return false
	var world: Node = player.get("world") as Node
	if world == null:
		return false
	var inventory: Node = world.get("inventory") as Node
	if inventory == null:
		return false
	var equipped: GhostItemInstance = inventory.get_equipped("sword")
	if equipped == null or equipped.definition == null:
		return false
	var ident: String = str(equipped.definition.item_id)
	return (ident == STILETTO and animation_name.begins_with("attack_nocturne_dagger_")) or (ident == TRIDENT and animation_name.begins_with("attack_briarwake_spear_"))

func get_weapon_span(animation_name: String, frame_index: int) -> PackedVector2Array:
	var empty: PackedVector2Array = PackedVector2Array()
	if not _is_equipped(animation_name):
		return empty
	var spear: bool = animation_name.begins_with("attack_briarwake_spear_")
	var heavy: bool = animation_name.contains("_heavy_")
	var face: String = "front"
	for direction in ["front", "back", "left", "right"]:
		if animation_name.ends_with(direction):
			face = direction
			break
	var n: int = clampi(frame_index, 0, 7)
	var anchor: Vector2 = Vector2(29, 24)
	match face:
		"back": anchor = Vector2(25, 16)
		"left": anchor = Vector2(-23, 24)
		"right": anchor = Vector2(23, 24)
	var tips: Array[Vector2] = []
	if spear:
		match face:
			"front":
				tips = [Vector2(48, 86), Vector2(35, 83), Vector2(55, 58), Vector2(91, 23), Vector2(115, -17), Vector2(109, -32), Vector2(80, 37), Vector2(48, 86)]
			"back":
				tips = [Vector2(43, -49), Vector2(15, -73), Vector2(29, -94), Vector2(73, -104), Vector2(104, -83), Vector2(95, -55), Vector2(56, -60), Vector2(43, -49)]
			"left":
				tips = [Vector2(-29, 93), Vector2(-5, 77), Vector2(-38, 44), Vector2(-92, 21), Vector2(-115, 8), Vector2(-116, -7), Vector2(-77, 44), Vector2(-29, 93)]
			"right":
				tips = [Vector2(29, 93), Vector2(5, 77), Vector2(38, 44), Vector2(92, 21), Vector2(115, 8), Vector2(116, -7), Vector2(77, 44), Vector2(29, 93)]
	else:
		match face:
			"front":
				tips = [Vector2(42, 47), Vector2(18, 43), Vector2(43, 8), Vector2(72, 5), Vector2(83, 13), Vector2(70, 36), Vector2(51, 42), Vector2(42, 47)]
			"back":
				tips = [Vector2(32, -16), Vector2(15, -26), Vector2(37, -40), Vector2(65, -32), Vector2(78, -17), Vector2(57, -8), Vector2(36, -14), Vector2(32, -16)]
			"left":
				tips = [Vector2(-33, 44), Vector2(-8, 35), Vector2(-40, 6), Vector2(-67, 13), Vector2(-82, 16), Vector2(-70, 34), Vector2(-48, 39), Vector2(-33, 44)]
			"right":
				tips = [Vector2(33, 44), Vector2(8, 35), Vector2(40, 6), Vector2(67, 13), Vector2(82, 16), Vector2(70, 34), Vector2(48, 39), Vector2(33, 44)]
	# A heavy blow has a longer forearm extension, not a spinning flat weapon.
	var reach: Vector2 = tips[n] - anchor
	if heavy and n in [3, 4, 5]:
		tips[n] = anchor + reach * (1.13 if spear else 1.09)
	return PackedVector2Array([anchor, tips[n]])

func _draw() -> void:
	if body == null:
		return
	var animation_name: String = str(body.animation)
	var span: PackedVector2Array = get_weapon_span(animation_name, body.frame)
	if span.size() != 2:
		return
	var grip: Vector2 = span[0]
	var tip: Vector2 = span[1]
	var axis: Vector2 = tip - grip
	if axis.length_squared() < 36.0:
		return
	var tangent: Vector2 = axis.normalized()
	var normal: Vector2 = Vector2(-tangent.y, tangent.x)
	z_index = -1 if animation_name.ends_with("back") else 5
	if animation_name.begins_with("attack_nocturne_dagger_"):
		_draw_nightglass_stiletto(grip, tip, tangent, normal)
	else:
		_draw_briarwake_trident(grip, tip, tangent, normal)

func _draw_nightglass_stiletto(grip: Vector2, tip: Vector2, tangent: Vector2, normal: Vector2) -> void:
	var guard: Vector2 = grip.lerp(tip, 0.22)
	var steel: Vector2 = grip.lerp(tip, 0.30)
	# Discrete fingers and dark hilt stay close to Ghost Girl's hand.
	draw_line(grip - tangent * 5.0, guard, Color("4b344e"), 5.4, true)
	draw_line(grip, guard, Color("aa829a"), 2.2, true)
	draw_line(guard - normal * 9.2 - tangent * 2.0, guard + normal * 9.2 - tangent * 2.0, Color("b6a2b5"), 2.7, true)
	draw_circle(guard, 3.4, Color("ab76d0"))
	# Slim original asymmetric darkglass blade and moon-silver cutting line.
	draw_colored_polygon(PackedVector2Array([steel + normal * 4.0, steel + tangent * 6.0 + normal * 1.5, tip, steel + tangent * 6.0 - normal * 2.1, steel - normal * 2.2]), Color("363046"))
	draw_line(steel + normal * 2.1, tip, Color("bcb1d7"), 1.4, true)
	draw_line(steel - normal * 1.0, tip - tangent * 3.2, Color("7677a6"), 0.9, true)
	draw_circle(grip, 3.9, Color("d3c5d5"))

func _draw_briarwake_trident(grip: Vector2, tip: Vector2, tangent: Vector2, normal: Vector2) -> void:
	var shaft_base: Vector2 = grip - tangent * 18.0
	var head: Vector2 = tip - tangent * 17.0
	# Rosewood haft with a pale winding thread and a second grip.
	draw_line(shaft_base, head, Color("2d1a2c"), 7.7, true)
	draw_line(shaft_base, head, Color("86526a"), 5.2, true)
	draw_line(shaft_base + normal * 1.1, head + normal * 1.1, Color("d8ac9c"), 1.3, true)
	for knot in range(3):
		var at: Vector2 = grip + tangent * float(knot * 12 + 4)
		draw_line(at - normal * 3.7, at + normal * 3.7, Color("d0a3b0"), 1.0, true)
	# Three physically distinct garnet tines; the outer tines curve inward.
	var left_base: Vector2 = head - normal * 8.4
	var right_base: Vector2 = head + normal * 8.4
	for side in [-1.0, 1.0]:
		var offset: Vector2 = normal * side * 9.3
		var fork: Vector2 = head + offset
		var prong_tip: Vector2 = tip - tangent * 2.0 + offset * 0.81
		draw_line(head, fork, Color("b37b8e"), 3.6, true)
		draw_line(fork, prong_tip, Color("d9b4b2"), 2.8, true)
		draw_line(prong_tip, prong_tip + tangent * 2.1, Color("f6d8c5"), 1.2, true)
	draw_line(head, tip, Color("e2bab6"), 4.0, true)
	draw_line(head + normal * 0.8, tip, Color("f1d5c7"), 1.5, true)
	draw_circle(head, 4.5, Color("8f3457"))
	draw_circle(head, 2.0, Color("d7a0b3"))
	# Two-hand bracing at the proper shaft distance from the forward hand.
	draw_circle(grip - tangent * 9.0, 4.8, Color("d8c7d6"))
	draw_circle(grip + tangent * 12.0, 4.5, Color("cab9cf"))
