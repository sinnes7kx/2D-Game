extends SceneTree
const FAMILIAR = preload("res://scripts/moonmoth_companion_v202.gd")
const INVENTORY = preload("res://scripts/inventory.gd")
const ARSENAL = preload("res://scripts/relic_arsenal_v277.gd")
const SPECIAL = preload("res://scripts/unique_specials_v261.gd")
const INNATE = preload("res://scripts/unique_innate_v274.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var samples: int = 0
	for shape in range(4):
		for step in range(101):
			var reach: float = (18.0+shape*1.9)*lerpf(0.55,1.0,float(step)/100.0)
			for side in [-1.0,1.0]:
				for upper in [true,false]:
					var points: PackedVector2Array = FAMILIAR.wing_outline_v282(Vector2(2,-1),side,reach if upper else reach*0.64,15.0+shape*1.6 if upper else 10.0+shape*1.1,upper)
					assert(points.size()==16)
					assert(not points[0].is_equal_approx(points[-1]))
					assert(Geometry2D.triangulate_polygon(points).size()==42)
					samples+=1
	assert(ARSENAL.PROFILES.size()==29)
	assert(SPECIAL.SPECIALS.size()==6)
	assert(INNATE.POWERS.size()==59)
	var inventory: Node = INVENTORY.new()
	# Detached inventory, persist=false: never touch the user's live save.
	var result: Dictionary = inventory.call("deliver_relic_samples_v282",false)
	assert(int(result["vault"])==28 and int(result["backpack"])==0)
	assert(inventory.get("vault").size()==28)
	assert(inventory.get("contents").is_empty())
	for item in inventory.get("vault"):
		assert(item.quality=="unique")
		assert(not SPECIAL.label(item).is_empty() or not preload("res://scripts/unique_innate_v274.gd").label(item).is_empty())
	var again: Dictionary = inventory.call("deliver_relic_samples_v282",false)
	assert(int(again["vault"])==0 and int(again["backpack"])==0)
	assert(inventory.get("vault").size()==28)
	inventory.free()
	print("v2.82 familiar geometry, %d wing samples and idempotent stash delivery PASS"%samples)
	quit(0)
