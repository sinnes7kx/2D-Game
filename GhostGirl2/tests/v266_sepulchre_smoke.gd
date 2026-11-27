extends SceneTree
const TRIAL = preload("res://scripts/sepulchre_gauntlet_v266.gd")
func _initialize() -> void:
	var paths: Array[String] = ["sepulchre_ossuary","sepulchre_thorn","sepulchre_crownless"]
	for d in range(1,4):
		var packed: PackedScene = load("res://scenes/rooms/"+paths[d-1]+".tscn")
		var chamber: Node2D = packed.instantiate() as Node2D
		var altar: Node = chamber.get_node("Gameplay/SepulchreAltar")
		assert(int(altar.get("depth"))==d)
		var wells: Node = chamber.get_node("Gameplay/SpawnWells")
		assert(wells.get_child_count()==6)
		for w in range(1,4):
			var lineup: Array[String] = TRIAL.recipe(d,w)
			assert(lineup.size()>0 and lineup.size()<=wells.get_child_count())
			if w==3:
				assert(lineup[0].begins_with("elite_"))
		if d<3:
			assert(not bool(chamber.get_node("Gameplay/Portals/Descent").get("opened")))
			assert(chamber.get_node("Gameplay/Portals/Descent").get("destination")==paths[d])
		assert(bool(chamber.get_node("Gameplay/Portals/Retreat").get("opened")))
		chamber.free()
	print("v266 Sepulchre layout and wave recipe assertions passed")
	quit()
