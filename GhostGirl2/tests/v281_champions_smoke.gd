extends SceneTree
const BOSS = preload("res://scripts/arena_boss_v279.gd")
const ARENA = preload("res://scripts/arena_controller_v279.gd")
const PLAQUE = preload("res://scripts/arena_challenge_v279.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	assert(BOSS.champion_pattern("iron",2,0,350.0)==["iron_charge","shield_lance","iron_charge"])
	assert(BOSS.champion_pattern("iron",2,0,100.0).size()==4)
	assert(BOSS.champion_pattern("bell",2,1,300.0)==["bell_wave","bell_wave","bell_wave"])
	assert(BOSS.champion_pattern("astral",2,0,400.0)==["astral_seal","astral_seal","astral_seal","astral_beam"])
	var keys: Dictionary = {}
	for id in ARENA.ORDER:
		for key in [ARENA.victory_key(id),ARENA.reward_key(id),ARENA.champion_key(id),ARENA.flawless_key(id)]:
			assert(not keys.has(key))
			keys[key]=true
		var boss: CharacterBody2D = BOSS.new()
		boss.set("boss_id",id)
		boss.set("champion",true)
		root.add_child(boss)
		assert(is_equal_approx(float(boss.get("health")),float(BOSS.DATA[id]["hp"])*1.28))
		assert(int(boss.get("damage_taken_contacts"))==0)
		boss.free()
		var plaque: Node2D = PLAQUE.new()
		plaque.set("boss_id",id)
		root.add_child(plaque)
		assert(plaque.has_method("_draw_contact_shadow"))
		plaque.free()
	assert(keys.size()==12)
	print("v2.81 champion attack patterns, health, save flags and plaque helper PASS")
	quit(0)
