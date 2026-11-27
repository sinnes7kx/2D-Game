extends RefCounted
## Track actual live projectiles; never persist transient combat state.
var shots: Array[WeakRef] = []

func register(shot: Node) -> void:
	if is_instance_valid(shot):
		shots.append(weakref(shot))

func busy() -> bool:
	for i in range(shots.size()-1,-1,-1):
		var shot: Node = shots[i].get_ref() as Node
		if not is_instance_valid(shot) or shot.is_queued_for_deletion() or not shot.is_inside_tree():
			shots.remove_at(i)
	return not shots.is_empty()

func clear() -> void:
	shots.clear()
