@tool
extends Node2D
## A short, OPTIONAL sequence of independent jumps across spectral thorns.
## Checkpoints are editor-owned Marker2D children called Step1, Step2, Step3.
## The whole sequence remains cosmetic except for its ONE persistent reward.
@export var route_title: String = "Moonstep Path"
@export var discovery_id: String = "v124_moor_step_path"
@export var reward_data: GhostItemData
@export var reward_seed: int = 124100
@export_enum("normal", "magic", "rare", "set", "unique") var reward_quality: String = "rare"
@export_range(18.0, 70.0, 1.0) var step_radius: float = 45.0
@export_range(180.0, 800.0, 1.0) var route_reset_distance: float = 560.0
var progress: int = 0
var completed: bool = false
var elapsed: float = 0.0
var last_jump_origin: Vector2 = Vector2.INF
var steps: Array[Marker2D] = []

func _ready() -> void:
	for i in range(1, 4):
		var marker: Marker2D = get_node_or_null("Step%d" % i) as Marker2D
		if marker != null:
			steps.append(marker)
	if Engine.is_editor_hint():
		return
	var root: Node = get_tree().current_scene
	if root != null and root.has_node("Inventory"):
		completed = bool(root.get_node("Inventory").call("has_collected", discovery_id))

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or completed or steps.size() != 3:
		return
	var girl: Node = get_tree().get_first_node_in_group("ghost_girl_player")
	if not (girl is Node2D):
		return
	var world_point: Vector2 = (girl as Node2D).global_position
	if progress > 0 and world_point.distance_to(steps[progress - 1].global_position) > route_reset_distance:
		progress = 0
		last_jump_origin = Vector2.INF
	var remaining: float = float(girl.get("jump_time_left"))
	var duration: float = float(girl.get("jump_duration"))
	if remaining <= 0.0 or duration <= 0.0:
		return
	var airborne_fraction: float = 1.0 - remaining / duration
	if airborne_fraction < 0.25 or airborne_fraction > 0.92:
		return
	var jump_started: Vector2 = girl.get("jump_origin")
	if jump_started == last_jump_origin or world_point.distance_to(jump_started) < 30.0:
		return
	if world_point.distance_to(steps[progress].global_position) > step_radius:
		return
	last_jump_origin = jump_started
	progress += 1
	if progress >= 3:
		_claim_reward()
	else:
		var main: Node = get_tree().current_scene
		if main != null and main.has_node("HUD"):
			main.get_node("HUD").call("show_pickup", "%s · STEP %d/3" % [route_title.to_upper(), progress], Color("d6c2ed"))
	queue_redraw()

func _claim_reward() -> void:
	var root: Node = get_tree().current_scene
	if root == null or not root.has_node("Inventory"):
		return
	var inv: Node = root.get_node("Inventory")
	var prize: GhostItemInstance = inv.add_loot(reward_data, reward_seed, reward_quality) if reward_data != null else null
	if prize == null:
		# Inventory-full retry is safe: step three can be visited again after unloading.
		progress = 2
		if root.has_node("HUD"):
			root.get_node("HUD").call("show_pickup", "PACK FULL · CLEAR SPACE AND REPEAT FINAL JUMP")
		return
	var records: Dictionary = inv.get("collected_pickups") as Dictionary
	records[discovery_id] = true
	inv.save_game()
	completed = true
	if root.has_node("HUD"):
		root.get_node("HUD").call("show_pickup", "%s · %s" % [route_title.to_upper(), prize.display_name()], Color("efd49d"))

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _draw() -> void:
	if steps.size() != 3:
		return
	for i in range(steps.size()):
		var point: Vector2 = to_local(steps[i].global_position)
		var lit: bool = completed or i < progress
		var tint: Color = Color("9ab4bd") if lit else Color("dab8ec")
		var alpha: float = 0.12 if completed else (0.32 + 0.09 * sin(elapsed * 1.6 + float(i)))
		draw_circle(point, step_radius + 8.0, Color(tint.r, tint.g, tint.b, alpha * 0.12))
		draw_arc(point, step_radius, elapsed * 0.35, elapsed * 0.35 + TAU * 0.88, 36, Color(tint.r, tint.g, tint.b, alpha + 0.18), 2.2, true)
		for c in range(4):
			var a: float = float(c) * TAU / 4.0 + elapsed * (0.5 if i == progress else 0.12)
			draw_circle(point + Vector2.from_angle(a) * (step_radius * 0.65), 2.8, Color(tint.r, tint.g, tint.b, alpha + 0.12))
		if i > 0:
			var previous: Vector2 = to_local(steps[i - 1].global_position)
			var path_tint: Color = Color(0.72, 0.61, 0.80, 0.17 if not completed else 0.10)
			for dot in range(1, 8):
				draw_circle(previous.lerp(point, float(dot) / 8.0), 1.8, path_tint)
