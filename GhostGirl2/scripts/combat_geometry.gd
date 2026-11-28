extends RefCounted
## Pure geometry and shared collision queries for physical combat.
## Callers own timing, stamina, damage, stagger, effects and hit ledgers.
## Geometry is not proof of contact; a live enemy and clear path are required.

const WORLD_MASK: int = 2
const WORLD_AND_PROPS_MASK: int = 6

static func facing_contact(offset: Vector2, axis: Vector2, minimum_squared: float, minimum_dot: float) -> bool:
	return offset.length_squared() > minimum_squared and not axis.is_zero_approx() and offset.normalized().dot(axis.normalized()) >= minimum_dot

static func cone_contact(offset: Vector2, axis: Vector2, reach: float, minimum_squared: float, minimum_dot: float) -> bool:
	return offset.length_squared() <= reach * reach and facing_contact(offset, axis, minimum_squared, minimum_dot)

static func is_hittable(candidate: Variant) -> bool:
	return is_instance_valid(candidate) and candidate is Node2D and not candidate.is_queued_for_deletion() and candidate.has_method("hit")

# Preserve the caller's collision mask and ray height. Ground relics used
# a <1 px short-path guard; ordinary melee historically always raycast.
static func obstruction(actor: CharacterBody2D, from: Vector2, to: Vector2, mask: int) -> Dictionary:
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(from, to, mask, [actor.get_rid()])
	return actor.get_world_2d().direct_space_state.intersect_ray(query)

static func ground_path_clear(actor: CharacterBody2D, from: Vector2, to: Vector2) -> bool:
	return from.distance_squared_to(to) < 1.0 or obstruction(actor, from, to, WORLD_AND_PROPS_MASK).is_empty()
