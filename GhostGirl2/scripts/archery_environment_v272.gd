extends RefCounted
## Physical fire transfer and room-local embedded shafts, never new damage areas.
const FIRE_BONUS: float = 1.25
const EMBED_LIMIT: int = 40
const EMBED_SECONDS: float = 24.0

static func segment_intersects_fire(start: Vector2,end: Vector2,center: Vector2,radius: float) -> bool:
	var segment: Vector2 = end-start
	var t: float = clampf((center-start).dot(segment)/maxf(segment.length_squared(),0.00001),0.0,1.0)
	return start.lerp(end,t).distance_squared_to(center)<=radius*radius

static func effective_element(base: int,ignited: bool) -> int:
	return 1 if ignited else base

static func impact_power(base: float,ignited: bool) -> float:
	return base*(FIRE_BONUS if ignited else 1.0)

static func crosses_fire(projectile: Node2D,start: Vector2,end: Vector2) -> bool:
	for group in ["v146_live_fire","arrow_fire_source_v272"]:
		for source in projectile.get_tree().get_nodes_in_group(group):
			if not is_instance_valid(source) or not source is Node2D or source.is_queued_for_deletion():
				continue
			var flame: Vector2 = source.global_position+Vector2(0,-24)
			var radius: float = 38.0
			if source.has_method("arrow_fire_center_v272"):
				flame=source.call("arrow_fire_center_v272")
				radius=44.0
			if not segment_intersects_fire(start,end,flame,radius):
				continue
			var path: Vector2 = end-start
			var t: float = clampf((flame-start).dot(path)/maxf(path.length_squared(),0.00001),0.0,1.0)
			var point: Vector2 = start.lerp(end,t)
			var probe: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(point,flame,6)
			var wall: Dictionary = projectile.get_world_2d().direct_space_state.intersect_ray(probe)
			if wall.is_empty() or wall.get("collider")==source:
				return true
	return false
