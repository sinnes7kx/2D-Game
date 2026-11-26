extends Node2D
## Layered cosmetics share Ghost Girl's exact animated transform.
## Weapon artwork is integrated in the approved directional body animations.
## v1.60 also enables a dedicated wand-hand overlay to replace the placeholder look.
var inventory
const GENTLE = preload("res://scripts/gentle_weapon_motion_v191.gd")
const WEAPON_SURFACE = preload("res://scripts/weapon_surface_v190.gd")
const HEAD_COSMETICS_V202 = preload("res://scripts/head_cosmetics_v202.gd")
const WAND_ANCHORS_V216 = preload("res://scripts/wand_anchors_v216.gd")
var wand_surface_key: String = ""
var wand_surface: ShaderMaterial
@onready var player_art: AnimatedSprite2D = get_parent().get_node("Ghost") as AnimatedSprite2D
@onready var wings: Sprite2D = $Wings
@onready var pendant: Sprite2D = $Trinket
@onready var wand_visual: Sprite2D = get_parent().get_node("Ghost/WandVisual") as Sprite2D
@onready var sword_visual: Sprite2D = get_parent().get_node("Hand/SwordVisual") as Sprite2D

# v1.62: three equipment-layer wand silhouettes, not changes to Ghost Girl art.
# Selection is cosmetic-UID-derived through visual_seed(), stable in saved looks.
const WAND_POSE_ATLASES = [
	preload("res://assets/equipment/wands_v163/crystal_rose_poses_v163.png"),
	preload("res://assets/equipment/wands_v163/moonlit_censer_poses_v163.png"),
	preload("res://assets/equipment/wands_v163/thorn_crescent_poses_v163.png")
]
const WAND_POSE_GUIDES_PATH: String = "res://resources/wand_pose_guides_v163.json"
const WAND_FRAME_SIZE: Vector2 = Vector2(176, 176)
var wand_pose_rows: Dictionary = {}
var last_wand_animation: String = ""
var last_wand_frame: int = -1
var last_wand_sprite_index: int = -1
var last_dress: GhostItemInstance = null
var last_dress_palette: int = -999
var aura_time: float = 0.0
var dress_aura_enabled: bool = false
var dress_signature: int = 0
var accessories_glow: bool = false
var accessory_color: Color = Color("ceb5ee")
var dress_glow_color: Color = Color("d9c4ff")
var dress_glow_color_b: Color = Color("f8dbff")
var dress_palette: Array[Color] = [Color("d9c4ff"), Color("f8dbff")]
var ambient_particle_sources: Array = []
# Stable, sprite-attached halo instead of repeated broad circles that shimmer
# against different walking frames. Visual-only; never saved.
const MYTHIC_HALO_TEXTURE: Texture2D = preload("res://assets/effects/mythic_dress_halo_v1642.png")
var mythic_dress_halo: Sprite2D = null

func _item_ambient_color(item: GhostItemInstance) -> Color:
	if item == null:
		return Color(0.82, 0.76, 0.94, 1.0)
	var gradient: Array[Color] = item.glow_gradient_colors()
	return gradient[1] if gradient.size() >= 2 else item.palette_color()

func _item_has_ambient_particles(item: GhostItemInstance) -> bool:
	if item == null:
		return false
	return GhostWeaponFXLibrary.tier(item.quality) >= 2 or item.visual_signature() > 0

func _rebuild_ambient_sources(feather: GhostItemInstance, amulet: GhostItemInstance, wand_item: GhostItemInstance) -> void:
	ambient_particle_sources.clear()
	var fabric: GhostItemInstance = inventory.get_equipped("dress") if inventory != null else null
	if _item_has_ambient_particles(fabric):
		ambient_particle_sources.append({"anchor": Vector2(0, 8), "radius": Vector2(18, 34), "color": _item_ambient_color(fabric), "count": 4})
	if _item_has_ambient_particles(feather):
		ambient_particle_sources.append({"anchor": Vector2(0, -76), "radius": Vector2(16, 10), "color": _item_ambient_color(feather), "count": 3})
	if _item_has_ambient_particles(amulet):
		ambient_particle_sources.append({"anchor": Vector2(0, -16), "radius": Vector2(10, 8), "color": _item_ambient_color(amulet), "count": 2})
	if _item_has_ambient_particles(wand_item):
		ambient_particle_sources.append({"anchor": Vector2(8, -8), "radius": Vector2(12, 10), "color": _item_ambient_color(wand_item), "count": 3})
	var sword_item: GhostItemInstance = inventory.get_equipped("sword") if inventory != null else null
	if _item_has_ambient_particles(sword_item):
		ambient_particle_sources.append({"anchor": Vector2(10, -8), "radius": Vector2(14, 12), "color": _item_ambient_color(sword_item), "count": 3})
	# A named socketable gives the dress/accessory a *tiny* distinct light.
	# Weapon jewels are handled by EquippedPrestigeFX to avoid duplicates.
	for slot in ["dress", "wings", "helm", "trinket", "charm"]:
		var gear: GhostItemInstance = inventory.get_equipped(slot)
		if gear == null:
			continue
		var anchor: Vector2 = Vector2(0, 7)
		if slot in ["wings", "helm"]:
			anchor = Vector2(0, -76)
		elif slot in ["trinket", "charm"]:
			anchor = Vector2(0, -16)
		for jewel in gear.socketed:
			if not (jewel is Dictionary):
				continue
			var jewel_id: String = str(jewel.get("id", ""))
			var ink: Color = Color.TRANSPARENT
			match jewel_id:
				"malady_jewel": ink = Color("e38a9f")
				"delirium_jewel": ink = Color("98c5f4")
				"exile_jewel": ink = Color("efd5a1")
				_: continue
			ambient_particle_sources.append({"anchor": anchor, "radius": Vector2(8, 11), "color": ink, "count": 2})

func _draw_firefly_cluster(anchor: Vector2, radius: Vector2, color: Color, count: int) -> void:
	for i in range(count):
		var t: float = aura_time * (0.34 + float(i) * 0.05) + float(i) * 2.13
		var bob: Vector2 = Vector2(cos(t * 1.1) * radius.x, sin(t * 0.8 + float(i)) * radius.y)
		var p: Vector2 = anchor + bob
		var glow: float = 0.45 + 0.55 * (0.5 + 0.5 * sin(t * 2.2 + float(i) * 0.7))
		draw_circle(p, 4.1, Color(color.r, color.g, color.b, 0.010 * glow))
		draw_circle(p, 2.1, Color(color.r, color.g, color.b, 0.020 * glow))
		draw_circle(p, 0.95 + 0.25 * float(i % 2), Color(color.r, color.g, color.b, 0.085 * glow))

func _load_wand_pose_rows() -> void:
	# The same cached authored guide is used for wand art, glimmer and
	# actual projectile origin. No independent per-facing offset table.
	wand_pose_rows = WAND_ANCHORS_V216.rows()

func _apply_wand_pose() -> void:
	if wand_visual == null or player_art == null:
		return
	var anim: String = str(player_art.animation)
	var frame_index: int = int(player_art.frame)
	var fallback_face: String = str(get_parent().get("facing_name"))
	if not wand_pose_rows.has(anim):
		anim = "wand_idle_" + fallback_face
	var row_data: Dictionary = wand_pose_rows.get(anim, {})
	var row: int = int(row_data.get("row", 0))
	var count: int = maxi(1, int(row_data.get("count", 1)))
	if GENTLE.modular_idle(str(player_art.animation)):
		frame_index = 0
	frame_index = clampi(frame_index, 0, count - 1)
	if last_wand_animation == anim and last_wand_frame == frame_index:
		return
	last_wand_animation = anim
	last_wand_frame = frame_index
	wand_visual.region_rect = Rect2(Vector2(float(frame_index), float(row)) * WAND_FRAME_SIZE, WAND_FRAME_SIZE)

func _ready() -> void:
	_load_wand_pose_rows()
	if player_art.material != null:
		player_art.material = player_art.material.duplicate(true)
	wings.hide()
	var head_layer: Node2D = HEAD_COSMETICS_V202.new() as Node2D
	head_layer.name = "HeadCosmeticsV202"
	add_child(head_layer)
	pendant.hide()
	wand_visual.hide()
	sword_visual.hide()
	var add_mat: CanvasItemMaterial = CanvasItemMaterial.new()
	add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = add_mat
	mythic_dress_halo = Sprite2D.new()
	mythic_dress_halo.name = "MythicDressHalo"
	mythic_dress_halo.texture = MYTHIC_HALO_TEXTURE
	mythic_dress_halo.show_behind_parent = true
	mythic_dress_halo.z_index = -3
	mythic_dress_halo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	mythic_dress_halo.visible = false
	var halo_material: CanvasItemMaterial = CanvasItemMaterial.new()
	halo_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	mythic_dress_halo.material = halo_material
	player_art.add_child(mythic_dress_halo)

func bind_inventory(value: Node) -> void:
	inventory = value
	if not inventory.equipment_changed.is_connected(refresh):
		inventory.equipment_changed.connect(refresh)
	if not inventory.contents_changed.is_connected(refresh):
		inventory.contents_changed.connect(refresh)
	refresh()

func refresh() -> void:
	if inventory == null or not is_node_ready():
		return
	var fabric: GhostItemInstance = inventory.get_equipped("dress")
	last_dress = fabric
	last_dress_palette = fabric.palette_index if fabric != null else -1
	dress_signature = fabric.visual_signature() if fabric != null else 0
	dress_aura_enabled = dress_signature in [4, 5]
	if fabric != null:
		var cloth_gradient: Array[Color] = fabric.glow_gradient_colors()
		dress_glow_color = cloth_gradient[0]
		dress_glow_color_b = cloth_gradient[-1]
		dress_palette = cloth_gradient
	# Signature 4 owns a constant halo. The old blinking drawn-body aura is
	# skipped for this signature, while small firefly particles remain.
	if mythic_dress_halo != null:
		mythic_dress_halo.visible = dress_signature == 4
		if dress_signature == 4:
			var halo_tint: Color = dress_glow_color.lerp(dress_glow_color_b, 0.52).lightened(0.31)
			mythic_dress_halo.modulate = Color(halo_tint.r, halo_tint.g, halo_tint.b, 0.42)
	var cloth_shader: ShaderMaterial = player_art.material as ShaderMaterial
	if cloth_shader != null:
		cloth_shader.set_shader_parameter("tint_strength", 0.0)
		cloth_shader.set_shader_parameter("dress_tint", fabric.palette_color() if fabric != null else Color.WHITE)
		cloth_shader.set_shader_parameter("cloth_filagree_strength", 0.0)
		cloth_shader.set_shader_parameter("cloth_filagree_phase", float(posmod(fabric.visual_seed(), 997)) * TAU / 997.0 if fabric != null else 0.0)
	var feather: GhostItemInstance = inventory.get_equipped("wings")
	# Old Rosewing Mantle retains its exact former appearance; new head
	# accessories use a separate, frame-attached overlay, not the old tiara.
	wings.visible = feather != null and feather.definition != null and str(feather.definition.item_id) == "rosewing_mantle"
	if feather != null:
		wings.modulate = feather.palette_color()
	accessories_glow = feather != null and (GhostWeaponFXLibrary.tier(feather.quality) >= 2 or feather.visual_signature() in [4, 5])
	if accessories_glow:
		accessory_color = feather.glow_gradient_colors()[1]
	var amulet: GhostItemInstance = inventory.get_equipped("trinket")
	if amulet == null:
		amulet = inventory.get_equipped("charm")
	pendant.visible = amulet != null and str(get_parent().get("facing_name")) != "back"
	if amulet != null:
		pendant.modulate = amulet.palette_color()
		accessories_glow = accessories_glow or (GhostWeaponFXLibrary.tier(amulet.quality) >= 2 or amulet.visual_signature() in [4, 5])
		if not wings.visible and accessories_glow:
			accessory_color = amulet.glow_gradient_colors()[1]
	var weapon: GhostItemInstance = inventory.get_equipped("sword")
	if weapon == null:
		weapon = inventory.get_equipped("wand")
	if cloth_shader != null:
		cloth_shader.set_shader_parameter("weapon_accent", weapon.weapon_base_color() if weapon != null and weapon.get_slot() == "sword" else (weapon.palette_color() if weapon != null else Color.WHITE))
		cloth_shader.set_shader_parameter("weapon_strength", 0.0)
	sword_visual.hide()
	wand_visual.hide()
	_rebuild_ambient_sources(feather, amulet, inventory.get_equipped("wand"))
	var head_layer: Node2D = get_node_or_null("HeadCosmeticsV202") as Node2D
	if head_layer != null:
		head_layer.queue_redraw()
	queue_redraw()

func _process(delta: float) -> void:
	aura_time += delta
	if inventory == null:
		return
	var dress_now: GhostItemInstance = inventory.get_equipped("dress")
	if dress_now != last_dress or (dress_now != null and dress_now.palette_index != last_dress_palette):
		refresh()
	var player = get_parent()
	transform = player_art.transform
	var facing: String = str(player.get("facing_name"))
	var sway: float = sin(Time.get_ticks_msec() * 0.001 * 1.8)
	# Recast the old wings slot as a delicate tiara/headpiece.
	wings.position = Vector2(-1.0 if facing == "left" else (1.0 if facing == "right" else 0.0), -74.0 + sway * 0.25)
	wings.rotation = sway * 0.010 + (-0.025 if facing == "left" else (0.025 if facing == "right" else 0.0))
	wings.scale = Vector2(0.54 if facing in ["left", "right"] else 0.60, 0.36 + 0.01 * sway)
	wings.modulate.a = 0.90 if facing == "back" else 0.96
	wings.z_index = 7
	pendant.visible = (inventory.get_equipped("trinket") != null or inventory.get_equipped("charm") != null) and facing != "back"
	pendant.position = Vector2(-5 if facing == "left" else (5 if facing == "right" else 0), -15 + sway * 0.6)
	pendant.rotation = sway * 0.015
	pendant.scale = Vector2.ONE
	sword_visual.hide()
	wand_visual.hide()
	var wand_item: GhostItemInstance = inventory.get_equipped("wand")
	if wand_item != null:
		var visual_index: int = posmod(wand_item.visual_seed(), WAND_POSE_ATLASES.size())
		if visual_index != last_wand_sprite_index or wand_visual.texture == null:
			last_wand_sprite_index = visual_index
			wand_visual.texture = WAND_POSE_ATLASES[visual_index]
			last_wand_animation = ""
			last_wand_frame = -1
		var surface_key: String = WEAPON_SURFACE.key(wand_item)
		if wand_surface == null or surface_key != wand_surface_key:
			wand_surface_key = surface_key
			if wand_surface == null:
				wand_surface = ShaderMaterial.new()
			WEAPON_SURFACE.configure(wand_surface, wand_item.collector_appearance(), WAND_FRAME_SIZE, false)
			wand_visual.material = wand_surface
		wand_visual.region_filter_clip_enabled = true
		wand_visual.region_enabled = true
		wand_visual.show()
		wand_visual.modulate = Color(1.0, 1.0, 1.0, 0.98 * wand_item.weapon_opacity())
		wand_visual.position = Vector2.ZERO
		wand_visual.rotation = 0.0
		wand_visual.scale = Vector2.ONE
		wand_visual.flip_h = false
		# All poses are painted into Ghost-local coordinates. The actual
		# animation frame, not a static facing rotation, selects the artwork.
		_apply_wand_pose()
		if str(player_art.animation).begins_with("wand_idle_"):
			var guide: Dictionary = wand_pose_rows.get(str(player_art.animation), {})
			var lines: Array = guide.get("guides", [])
			if not lines.is_empty() and lines[0].size() == 4:
				var grip: Vector2 = Vector2(float(lines[0][0]), float(lines[0][1]))
				var angle: float = GENTLE.angle_at(GENTLE.phase_of(player_art))
				wand_visual.rotation = angle
				wand_visual.position = grip - grip.rotated(angle)
		wand_visual.show_behind_parent = facing == "back"
		wand_visual.z_index = -2 if facing == "back" else 6
	if dress_aura_enabled or accessories_glow or wand_item != null or not ambient_particle_sources.is_empty():
		queue_redraw()

func _draw() -> void:
	# Node transform is already copied from Ghost. Draw in Ghost-local coords.
	for src in ambient_particle_sources:
		_draw_firefly_cluster(src.get("anchor", Vector2.ZERO), src.get("radius", Vector2(10, 10)), src.get("color", Color(0.85, 0.8, 0.95, 1.0)), int(src.get("count", 2)))
	if accessories_glow:
		var flicker: float = 0.85 + 0.15 * sin(aura_time * 1.9)
		draw_circle(Vector2(0, -34), 16.0, Color(accessory_color.r, accessory_color.g, accessory_color.b, 0.023 * flicker))
		for i in range(3):
			var p: Vector2 = Vector2(cos(aura_time * 0.8 + i * 2.1) * 14.0, -31.0 + sin(aura_time + i * 2.1) * 10.0)
			draw_circle(p, 1.5, Color(accessory_color.r, accessory_color.g, accessory_color.b, 0.17))
	if not dress_aura_enabled:
		return
	if dress_signature == 4:
		# Deliberately constant brightness: only a few tiny fireflies drift.
		# No pulse or broad transient disks that blink during walking.
		for k in range(5):
			var phase: float = aura_time * (0.34 + 0.045 * float(k)) + float(k) * 1.65
			var point: Vector2 = Vector2(sin(phase) * (8.0 + float(k)), 36.0 - float(k) * 17.0 + cos(phase * 0.7) * 3.0)
			var ink: Color = GhostCosmeticRNGV152.sample_palette(dress_palette, float(k) / 4.0).lightened(0.28)
			draw_circle(point, 3.2, Color(ink.r, ink.g, ink.b, 0.031))
			draw_circle(point, 1.1, Color(ink.r, ink.g, ink.b, 0.24))
		return
	var pulse: float = 0.88 + 0.12 * sin(aura_time * 1.8)
	var center: Vector2 = Vector2(0, 18)
	var aura_alpha_mul: float = 1.0
	if dress_signature == 4:
		aura_alpha_mul = 1.95
	elif dress_signature == 5:
		aura_alpha_mul = 1.40
	# Soft body aura behind and around Ghost Girl. Kept compact so it reads as
	# a rare blessing, not a giant fog effect.
	for i in range(8):
		var t: float = float(i) / 7.0
		var col: Color = GhostCosmeticRNGV152.sample_palette(dress_palette, t)
		var at: Vector2 = center + Vector2(sin(aura_time * 0.9 + t * 5.0) * 6.0, 18.0 - t * 56.0)
		draw_circle(at, (12.0 + t * 13.0) * pulse, Color(col.r, col.g, col.b, (0.010 + 0.006 * pulse) * aura_alpha_mul))
	draw_circle(center + Vector2(0, -4), 20.0 * pulse, Color(dress_glow_color.r, dress_glow_color.g, dress_glow_color.b, 0.022 * aura_alpha_mul))
	draw_circle(center + Vector2(0, 16), 26.0 * pulse, Color(dress_glow_color_b.r, dress_glow_color_b.g, dress_glow_color_b.b, 0.016 * aura_alpha_mul))
	if dress_signature == 4:
		# Mythic Radiance dress: stronger glimmer so it clearly reads in-game.
		for s in range(6):
			var st: float = aura_time * (0.9 + 0.08 * s) + s * 1.31
			var shimmer: Vector2 = center + Vector2(cos(st) * (10.0 + s), -8.0 + sin(st * 1.2) * (18.0 + 2.0 * s))
			var c: Color = GhostCosmeticRNGV152.sample_palette(dress_palette, float(s) / 5.0).lerp(Color.WHITE, 0.22)
			draw_circle(shimmer, 5.2, Color(c.r, c.g, c.b, 0.018 + 0.010 * pulse))
			draw_circle(shimmer, 2.0, Color(c.r, c.g, c.b, 0.10 + 0.04 * pulse))
			draw_circle(shimmer, 0.95, Color(1.0, 0.98, 1.0, 0.30 + 0.08 * pulse))
		for rail in [-1.0, 1.0]:
			var thread_from: Vector2 = center + Vector2(rail * 7.0, -28.0)
			var thread_to: Vector2 = center + Vector2(rail * 14.0, 24.0)
			draw_line(thread_from, thread_to, Color(dress_glow_color_b.r, dress_glow_color_b.g, dress_glow_color_b.b, 0.10 * pulse), 1.0, true)
		draw_circle(center + Vector2(0, -24), 18.0 * pulse, Color(dress_glow_color_b.r, dress_glow_color_b.g, dress_glow_color_b.b, 0.022))
	if dress_signature == 5:
		# The new super-rare appearance adds an overhead moonlet and threads.
		var moon: Vector2 = center + Vector2(0.0, -57.0)
		var edge: Color = dress_glow_color_b.lerp(Color.WHITE, 0.42)
		draw_arc(moon, 12.5, aura_time * 0.25, aura_time * 0.25 + PI * 1.53, 32, Color(edge.r, edge.g, edge.b, 0.23 * pulse), 1.4, true)
		for j in range(6):
			var f: float = float(j) / 5.0
			var tail: Vector2 = center + Vector2(sin(aura_time * 1.1 + j * 1.65) * 18.0, 28.0 - f * 67.0)
			var c: Color = GhostCosmeticRNGV152.sample_palette(dress_palette, f)
			draw_circle(tail, 2.0 + 0.4 * sin(aura_time * 2.0 + j), Color(c.r, c.g, c.b, 0.22 * pulse))
	for i in range(4 + (2 if dress_signature == 4 else 0)):
		var ang: float = aura_time * (0.55 + 0.08 * i) + i * 1.57
		var mote: Vector2 = center + Vector2(cos(ang) * (8.0 + i * 2.2), -8.0 + sin(ang * 1.3) * (18.0 + i * 2.0))
		var c: Color = GhostCosmeticRNGV152.sample_palette(dress_palette, float(i) / float(maxi(1, 3 + (2 if dress_signature == 4 else 0))))
		var alpha_boost: float = 1.0 if dress_signature != 4 else 1.55
		draw_circle(mote, 1.6 + 0.3 * float(i % 2), Color(c.r, c.g, c.b, 0.18 * alpha_boost))
