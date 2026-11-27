extends SceneTree
const TRIAL = preload("res://scripts/sepulchre_gauntlet_v266.gd")
func _initialize() -> void:
	var paths: Array[String] = ["sepulchre_ossuary","sepulchre_thorn","sepulchre_crownless"]
	for d in range(1,4):
		var packed: PackedScene = load("res://scenes/rooms/"+paths[d-1]+".tscn")
		var chamber: Node2D = packed.instantiate() as Node2D
		var altar: Node = chamber.get_node("Gameplay/SepulchreAltar")
		assert(int(altar.get("depth"))==d)
		assert(bool(altar.call("can_awaken_seal")))
		var seal1: Node = chamber.get_node("Gameplay/RitualSeal1")
		var seal2: Node = chamber.get_node("Gameplay/RitualSeal2")
		assert(seal1.position.distance_to(seal2.position)>500.0)
		assert(not bool(seal1.get("awakened")) and not bool(seal2.get("awakened")))
		assert(not str(seal1.call("interact")).is_empty())
		assert(int(altar.get("awakened_seals"))==1)
		assert(str(seal1.call("interact")).is_empty())
		assert(not str(seal2.call("interact")).is_empty())
		assert(int(altar.get("awakened_seals"))==2 and not bool(altar.call("can_awaken_seal")))
		var wells: Node = chamber.get_node("Gameplay/SpawnWells")
		assert(wells.get_child_count()==6)
		for w in range(1,4):
			var lineup: Array[String] = TRIAL.recipe(d,w)
			assert(lineup.size()>0 and lineup.size()<=wells.get_child_count())
			var chosen: Array[int] = TRIAL.well_order(1234+d*100+w,wells.get_child_count(),lineup.size())
			assert(chosen.size()==lineup.size())
			assert(chosen==TRIAL.well_order(1234+d*100+w,wells.get_child_count(),lineup.size()))
			for index in chosen:
				assert(index>=0 and index<wells.get_child_count() and chosen.count(index)==1)
			if w==3:
				assert(lineup[0].begins_with("elite_"))
		if d<3:
			assert(not bool(chamber.get_node("Gameplay/Portals/Descent").get("opened")))
			assert(chamber.get_node("Gameplay/Portals/Descent").get("destination")==paths[d])
		assert(bool(chamber.get_node("Gameplay/Portals/Retreat").get("opened")))
		chamber.free()
	print("v266 Sepulchre layout and wave recipe assertions passed")
	quit()
