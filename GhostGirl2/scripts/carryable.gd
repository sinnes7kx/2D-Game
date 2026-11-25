extends RigidBody2D
## A real planar RigidBody2D plus an independent vertical Z arc.
## Godot's 2D gravity alone would pull the crate south in a top-down view,
## so we model height separately and render the art above the ground shadow.
const PHYSICAL_FEEL: Script = preload("res://scripts/impact_spawner_v149.gd")

@export var interaction_name: String = "Moonstone crate"
@export var impact_visual: PackedScene = preload("res://scenes/impact_effect.tscn")
var impact_cooldown: float = 0.0
var thrown_timer: float = 0.0
var held: bool = false
# One genuine stone impact per throw; cosmetic rebounds cannot farm puzzle hits.
var v201_cave_impact_delivered: bool = false
var v201_previous_thrown_speed: float = 0.0
var z_height: float = 0.0
var z_velocity: float = 0.0
var original_collision_layer: int = 4
var original_collision_mask: int = 7

@onready var art: Sprite2D = $Art
@onready var shadow: Node2D = $Shadow

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("carryable")
	original_collision_layer = collision_layer
	original_collision_mask = collision_mask
	gravity_scale = 0.0
	contact_monitor = true
	max_contacts_reported = 4
	body_entered.connect(_on_body_impact)

func _physics_process(delta: float) -> void:
	impact_cooldown = maxf(0.0, impact_cooldown - delta)
	thrown_timer = maxf(0.0, thrown_timer - delta)
	if thrown_timer > 0.0 and not held:
		v201_previous_thrown_speed = linear_velocity.length()
	if held:
		return
	if z_height > 0.0 or z_velocity > 0.0:
		z_velocity -= 840.0 * delta
		z_height += z_velocity * delta
		if z_height <= 0.0:
			z_height = 0.0
			if thrown_timer > 0.0 and absf(z_velocity) > 100.0:
				_spawn_impact()
			if absf(z_velocity) > 125.0:
				z_velocity = -z_velocity * 0.26
			else:
				z_velocity = 0.0
	art.position.y = -28.0 - z_height
	shadow.modulate.a = clampf(1.0 - z_height / 170.0, 0.15, 1.0)

func pick_up(attachment: Marker2D) -> void:
	if held:
		return
	held = true
	v201_cave_impact_delivered = false
	v201_previous_thrown_speed = 0.0
	thrown_timer = 0.0
	freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	collision_layer = 0
	collision_mask = 0
	z_height = 0.0
	z_velocity = 0.0
	reparent(attachment, true)
	position = Vector2.ZERO
	rotation = 0.0
	art.position = Vector2(0, -15)
	shadow.visible = false

func release_to(parent_node: Node2D, world_position: Vector2, direction: Vector2, should_throw: bool, character: PhysicsBody2D) -> void:
	if not held:
		return
	reparent(parent_node, true)
	global_position = world_position
	rotation = 0.0
	held = false
	v201_cave_impact_delivered = false
	v201_previous_thrown_speed = 0.0
	thrown_timer = 2.7 if should_throw else 0.0
	shadow.visible = true
	collision_layer = original_collision_layer
	collision_mask = original_collision_mask
	freeze = false
	sleeping = false
	z_height = 27.0 if should_throw else 12.0
	z_velocity = 300.0 if should_throw else 52.0
	var throw_bonus: float = 0.0
	if should_throw and get_tree().current_scene != null and get_tree().current_scene.has_node("Inventory"):
		throw_bonus = float(get_tree().current_scene.get_node("Inventory").call("get_stat_total", "throw_force_pct"))
	linear_velocity = direction * (470.0 if should_throw else 92.0) * (1.0 + throw_bonus / 100.0)
	v201_previous_thrown_speed = linear_velocity.length()
	angular_velocity = randf_range(-2.0, 2.0) if should_throw else 0.0
	add_collision_exception_with(character)
	get_tree().create_timer(0.48).timeout.connect(func() -> void:
		if is_instance_valid(character) and is_instance_valid(self):
			remove_collision_exception_with(character)
	)

func _on_body_impact(other: Node) -> void:
	var impact_speed: float = maxf(v201_previous_thrown_speed, linear_velocity.length())
	if not held and thrown_timer > 0.0 and impact_speed > 135.0:
		# The player can improvise with a real carried stone. Only a genuine
		# high-speed collision with the cave obstruction counts, once per throw.
		if not v201_cave_impact_delivered and other != null and other.is_in_group("v201_cave_blocker") and other.has_method("receive_thrown_impact"):
			v201_cave_impact_delivered = true
			other.call("receive_thrown_impact", impact_speed, global_position)
		_spawn_impact()

func _spawn_impact() -> void:
	if impact_cooldown > 0.0 or impact_visual == null:
		return
	impact_cooldown = 0.20
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return
	var effect: Node2D = impact_visual.instantiate() as Node2D
	scene_root.add_child(effect)
	effect.global_position = global_position + Vector2(0.0, -4.0)
	PHYSICAL_FEEL.burst(scene_root, global_position + Vector2(0.0, -5.0), "crate", clampf(linear_velocity.length() / 360.0, 0.65, 1.35), linear_velocity.normalized(), roundi(global_position.x * 7.0))
	PHYSICAL_FEEL.rumble(global_position, 3.1)
