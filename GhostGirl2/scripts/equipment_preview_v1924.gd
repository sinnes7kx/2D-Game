extends SubViewportContainer
## The actual player scene and its existing equipped renderers in an isolated
## 2D viewport. No gameplay processing, collisions, camera or save operations.
const PLAYER = preload("res://scenes/player.tscn")
class PreviewWorld extends Node:
	var inventory: Node

var viewport: SubViewport
var preview_world: PreviewWorld
var actor: CharacterBody2D
var body: AnimatedSprite2D
var inventory: Node
var facing_index: int = 0
var preview_zoom: float = 1.0
var preview_pan: Vector2 = Vector2.ZERO
const BASE_SCALE: float = 1.55
const BASE_POSITION: Vector2 = Vector2(117, 204)
const ZOOM_PIVOT: Vector2 = Vector2(117, 118)
const FACES: Array[String] = ["front", "right", "back", "left"]
const DIRECTIONS: Array[Vector2] = [Vector2.DOWN, Vector2.RIGHT, Vector2.UP, Vector2.LEFT]

func bind_inventory(value: Node) -> void:
	inventory = value
	if is_instance_valid(preview_world):
		preview_world.inventory = value
	if is_visible_in_tree():
		activate()

func activate() -> void:
	if inventory == null:
		return
	if not is_instance_valid(actor):
		_build()
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	actor.process_mode = Node.PROCESS_MODE_INHERIT
	actor.set_process(false)
	actor.set_physics_process(false)
	actor.set_process_input(false)
	actor.set_process_unhandled_input(false)
	actor.set_process_unhandled_key_input(false)
	refresh()

func deactivate() -> void:
	if is_instance_valid(viewport):
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	if is_instance_valid(actor):
		actor.process_mode = Node.PROCESS_MODE_DISABLED

func _build() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	viewport = SubViewport.new()
	viewport.name = "EquipmentPreviewViewport"
	viewport.size = Vector2i(234, 236)
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.gui_disable_input = true
	viewport.world_2d = World2D.new()
	add_child(viewport)
	preview_world = PreviewWorld.new()
	preview_world.inventory = inventory
	viewport.add_child(preview_world)
	actor = PLAYER.instantiate() as CharacterBody2D
	actor.name = "EquipmentPreviewActor"
	actor.set("equipment_preview_only", true)
	actor.set("world", preview_world)
	actor.collision_layer = 0
	actor.collision_mask = 0
	var camera: Camera2D = actor.get_node("Camera2D")
	camera.enabled = false
	body = actor.get_node("Ghost") as AnimatedSprite2D
	body.sprite_frames = body.sprite_frames.duplicate() as SpriteFrames
	_apply_preview_zoom()
	preview_world.add_child(actor)
	actor.get_node("RoseHook").process_mode = Node.PROCESS_MODE_DISABLED
	for path in ["EquipmentVisuals", "Ghost/WeaponLayers", "Ghost/BowPaletteV139", "Ghost/EquippedPrestigeFX"]:
		var layer: Node = actor.get_node_or_null(path)
		if layer != null and layer.has_method("bind_inventory"):
			layer.call("bind_inventory", inventory)

func set_direction(index: int) -> void:
	facing_index = clampi(index, 0, FACES.size()-1)
	refresh()

func refresh() -> void:
	if not is_instance_valid(actor) or inventory == null:
		return
	actor.call("set_facing", DIRECTIONS[facing_index])
	var clip: String = str(actor.call("_weapon_motion_prefix", false)) + FACES[facing_index]
	if not body.sprite_frames.has_animation(clip):
		clip = "idle_" + FACES[facing_index]
	if body.sprite_frames.has_animation(clip) and (str(body.animation) != clip or not body.is_playing()):
		body.play(clip)
	# All visual layers share the live equipped item references, including
	# temporary debug overrides. Preview never calls equip, reroll or save.

func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_inside_tree():
		if is_visible_in_tree():
			activate()
		else:
			deactivate()

func _apply_preview_zoom() -> void:
	if not is_instance_valid(actor):
		return
	actor.scale = Vector2.ONE * BASE_SCALE * preview_zoom
	actor.position = ZOOM_PIVOT + (BASE_POSITION - ZOOM_PIVOT) * preview_zoom + preview_pan

func set_preview_zoom(value: float) -> void:
	preview_zoom = clampf(value, 1.0, 3.0)
	if is_equal_approx(preview_zoom, 1.0):
		preview_pan = Vector2.ZERO
	_apply_preview_zoom()

func reset_preview_zoom() -> void:
	preview_pan = Vector2.ZERO
	set_preview_zoom(1.0)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			set_preview_zoom(preview_zoom * (1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15))
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			reset_preview_zoom()
			accept_event()
	elif event is InputEventMouseMotion and preview_zoom > 1.0 and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		var factor: Vector2 = Vector2(234, 236) / size.max(Vector2.ONE)
		var limit: float = 120.0 * (preview_zoom - 1.0)
		preview_pan = (preview_pan + event.relative * factor).clamp(Vector2.ONE * -limit, Vector2.ONE * limit)
		_apply_preview_zoom()
		accept_event()
