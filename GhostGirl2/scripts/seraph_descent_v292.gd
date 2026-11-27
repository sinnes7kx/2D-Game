extends RefCounted
const GROUND = preload("res://scripts/relic_ground_v288.gd")
const DURATION: float = 0.96
const RISE_HIT: float = 0.22
const FALL_HIT: float = 0.73
const COST: float = 32.0

static func height_at(age: float) -> float:
	var t: float = clampf(age/DURATION,0.0,1.0)
	return 66.0*sin(PI*t)

static func speed_at(age: float) -> float:
	if age<0.24:
		return 95.0
	if age<0.46:
		return 36.0
	if age<0.75:
		return 310.0
	return 42.0*(1.0-clampf((age-0.75)/(DURATION-0.75),0.0,1.0))

static func contact(offset: Vector2,axis: Vector2,descending: bool) -> bool:
	var reach: float = 192.0 if descending else 142.0
	return not axis.is_zero_approx() and offset.length_squared()<=reach*reach and (offset.length_squared()<=24.0*24.0 or offset.normalized().dot(axis.normalized())>=(0.10 if descending else 0.38))

static func strike(actor: CharacterBody2D,axis: Vector2,damage: float,descending: bool) -> int:
	var hits: int = 0
	var seen: Dictionary = {}
	for enemy in actor.get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or not enemy is Node2D or not enemy.has_method("hit"):
			continue
		var point: Vector2 = (enemy as Node2D).global_position
		if seen.has(enemy.get_instance_id()) or not contact(point-actor.global_position,axis,descending) or not GROUND.clear_path(actor,actor.global_position,point):
			continue
		seen[enemy.get_instance_id()]=true
		enemy.call("hit",damage,2.4 if descending else 1.0)
		hits+=1
	return hits
