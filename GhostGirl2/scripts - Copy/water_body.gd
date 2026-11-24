@tool
class_name GhostWaterBody
extends Area2D
## Editor-owned physical water polygon. There is NO fishing gameplay yet.
## Future rods will ask every GhostWaterBody whether a cast point is inside it.
@export_enum("stream", "river", "pond", "lake", "marsh") var water_kind: String = "river"
@export var fishing_enabled: bool = true
@export var future_loot_profile: String = "river_common"
@export var water_label: String = "Unnamed water"
@export var show_outline_in_editor: bool = true
@onready var water_polygon: CollisionPolygon2D = $WaterPolygon
# Local points of spell-created ice. They deliberately do not persist in saves.
var ice_patches: Array[Dictionary] = []

func _ready() -> void:
	collision_layer = 16
	collision_mask = 0
	monitorable = true
	monitoring = false
	if not Engine.is_editor_hint():
		add_to_group("water_body")

func contains_world_point(world_point: Vector2) -> bool:
	if water_polygon == null or water_polygon.polygon.size() < 3:
		return false
	var local_point: Vector2 = water_polygon.to_local(world_point)
	return Geometry2D.is_point_in_polygon(local_point, water_polygon.polygon)

func can_cast_to(world_point: Vector2) -> bool:
	return fishing_enabled and contains_world_point(world_point)

func freeze_near(world_point: Vector2, world_radius: float, seconds: float) -> bool:
	if water_polygon == null or water_polygon.polygon.size() < 3:
		return false
	var center: Vector2 = water_polygon.to_local(world_point)
	var boundary: PackedVector2Array = water_polygon.polygon
	var nearest: Vector2 = center
	var distance: float = 0.0
	if not Geometry2D.is_point_in_polygon(center, boundary):
		distance = INF
		for i in range(boundary.size()):
			var close_point: Vector2 = Geometry2D.get_closest_point_to_segment(center, boundary[i], boundary[(i + 1) % boundary.size()])
			var trial: float = center.distance_to(close_point)
			if trial < distance:
				distance = trial
				nearest = close_point
	if distance > world_radius:
		return false
	var spread: float = minf(190.0, maxf(65.0, world_radius * 0.78))
	for existing in ice_patches:
		if str(existing.get("kind", "")) == "bridge":
			continue
		var previous_center: Vector2 = existing["center"]
		if previous_center.distance_to(nearest) < 80.0:
			existing["time_left"] = maxf(float(existing["time_left"]), seconds)
			queue_redraw()
			return true
	ice_patches.append({"center": nearest, "radius": spread, "time_left": seconds})
	queue_redraw()
	return true

func freeze_arrow_segment(world_start: Vector2, world_end: Vector2, seconds: float = 10.0) -> bool:
	# The physical, wall-clipped frost arrow touches an editable water polygon.
	# Extend its direction to find the opposite bank. The resulting ice strip
	# is temporary and never changes the original painting or save data.
	if water_polygon == null or water_polygon.polygon.size() < 3:
		return false
	var origin: Vector2 = water_polygon.to_local(world_start)
	var end: Vector2 = water_polygon.to_local(world_end)
	var travel: Vector2 = end - origin
	if travel.length_squared() < 0.001:
		return false
	var dir: Vector2 = travel.normalized()
	var edge_points: Array[Vector2] = []
	var edge: PackedVector2Array = water_polygon.polygon
	for i in range(edge.size()):
		var crossing: Variant = Geometry2D.segment_intersects_segment(origin, end, edge[i], edge[(i + 1) % edge.size()])
		if crossing is Vector2:
			edge_points.append(crossing)
	var inside_start: bool = Geometry2D.is_point_in_polygon(origin, edge)
	var inside_end: bool = Geometry2D.is_point_in_polygon(end, edge)
	if edge_points.is_empty() and not inside_start and not inside_end:
		return false
	var entry: Vector2 = edge_points[0] if not edge_points.is_empty() else origin
	var projected_end: Vector2 = entry + dir * 310.0
	var far_bank: Vector2 = projected_end
	var closest_distance: float = INF
	for i in range(edge.size()):
		var crossing: Variant = Geometry2D.segment_intersects_segment(entry + dir * 2.0, projected_end, edge[i], edge[(i + 1) % edge.size()])
		if crossing is Vector2:
			var distance: float = entry.distance_to(crossing)
			if distance < closest_distance and distance > 3.0:
				closest_distance = distance
				far_bank = crossing
	var begin: Vector2 = entry - dir * 16.0
	var finish: Vector2 = far_bank + (dir * 16.0 if closest_distance != INF else Vector2.ZERO)
	for patch in ice_patches:
		if str(patch.get("kind", "")) != "bridge":
			continue
		var center: Vector2 = (patch["a"] + patch["b"]) * 0.5
		if center.distance_squared_to((begin + finish) * 0.5) < 90.0 * 90.0:
			patch["time_left"] = maxf(float(patch["time_left"]), seconds)
			queue_redraw()
			return true
	ice_patches.append({"kind": "bridge", "a": begin, "b": finish, "radius": 43.0, "time_left": seconds})
	queue_redraw()
	return true

func movement_multiplier_at(world_point: Vector2) -> float:
	if not contains_world_point(world_point):
		return 1.0
	var local_point: Vector2 = water_polygon.to_local(world_point)
	for patch in ice_patches:
		var radius: float = float(patch["radius"])
		if str(patch.get("kind", "")) == "bridge":
			var foot: Vector2 = Geometry2D.get_closest_point_to_segment(local_point, patch["a"], patch["b"])
			if local_point.distance_squared_to(foot) <= radius * radius:
				return 1.0
		elif local_point.distance_squared_to(patch["center"]) <= radius * radius:
			return 1.0 # Moonfall turns the mire temporarily firm beneath your feet.
	return 0.77 if water_kind == "marsh" else 0.84


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return
	var had_ice: bool = not ice_patches.is_empty()
	for i in range(ice_patches.size() - 1, -1, -1):
		var patch: Dictionary = ice_patches[i]
		patch["time_left"] = float(patch["time_left"]) - delta
		if float(patch["time_left"]) <= 0.0:
			ice_patches.remove_at(i)
	if had_ice:
		queue_redraw()

func _draw() -> void:
	var polygon_node: CollisionPolygon2D = get_node_or_null("WaterPolygon") as CollisionPolygon2D
	if polygon_node == null or polygon_node.polygon.size() < 3:
		return
	var pts: PackedVector2Array = polygon_node.polygon
	if Engine.is_editor_hint():
		if not show_outline_in_editor:
			return
		draw_colored_polygon(pts, Color(0.36, 0.63, 1.0, 0.08))
		for i in range(pts.size()):
			draw_line(pts[i], pts[(i + 1) % pts.size()], Color(0.66, 0.83, 1.0, 0.62), 2.0, true)
		return
	# Ice is only drawn inside the hand-authored water polygon. It melts away
	# naturally when the spell expires, without modifying background textures.
	for patch in ice_patches:
		var radius: float = float(patch["radius"])
		var fade: float = clampf(float(patch["time_left"]) / 1.2, 0.0, 1.0)
		if str(patch.get("kind", "")) == "bridge":
			var a: Vector2 = patch["a"]
			var b: Vector2 = patch["b"]
			var side: Vector2 = (b - a).normalized().orthogonal() * radius
			var corners: PackedVector2Array = PackedVector2Array([a + side, b + side, b - side, a - side])
			draw_colored_polygon(corners, Color(0.61, 0.84, 0.96, 0.23 * fade))
			for i in range(7):
				var t: float = float(i) / 7.0
				var point: Vector2 = a.lerp(b, t)
				draw_line(point - side * 0.9, point + side * 0.9, Color(0.85, 0.95, 1.0, 0.38 * fade), 1.5, true)
			continue
		var center: Vector2 = patch["center"]
		for ring in range(4):
			var r: float = radius * (0.33 + float(ring) * 0.17)
			var previous: Vector2 = center + Vector2(r, 0)
			for k in range(1, 51):
				var a: float = float(k) * TAU / 50.0
				var current: Vector2 = center + Vector2.from_angle(a) * r
				if Geometry2D.is_point_in_polygon(current, pts) and Geometry2D.is_point_in_polygon(previous, pts):
					draw_line(previous, current, Color(0.78, 0.90, 1.0, fade * 0.19), 1.9, true)
				previous = current
		for j in range(18):
			var a: float = float(j) * 2.39996
			var p: Vector2 = center + Vector2.from_angle(a) * radius * (0.21 + 0.65 * float(j % 5) / 5.0)
			if Geometry2D.is_point_in_polygon(p, pts):
				draw_line(p - Vector2(3.0, 4.0), p + Vector2(4.0, 3.0), Color(0.82, 0.93, 1.0, fade * 0.24), 1.4, true)
