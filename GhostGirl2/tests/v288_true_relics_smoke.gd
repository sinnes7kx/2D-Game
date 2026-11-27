extends SceneTree
const MECHANICS = preload("res://scripts/relic_mechanics_v288.gd")
const GROUND = preload("res://scripts/relic_ground_v288.gd")
const SPECIAL = preload("res://scripts/unique_specials_v261.gd")
const ARSENAL = preload("res://scripts/relic_arsenal_v277.gd")
const PLAYER = preload("res://scripts/player.gd")
const FX = preload("res://scripts/relic_cyclone_fx_v288.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	assert(MECHANICS.CHANNELS.size()==2)
	assert(MECHANICS.AREAS.size()==3)
	assert(MECHANICS.GROUND_SKILLS.size()==4)
	assert(MECHANICS.GROUND_SKILLS["hollowbell_maul_v277"]=="bells")
	assert(MECHANICS.parry_contact_v289(Vector2(100,20),Vector2.RIGHT))
	assert(not MECHANICS.parry_contact_v289(Vector2(-100,0),Vector2.RIGHT))
	assert(not MECHANICS.parry_contact_v289(Vector2(300,0),Vector2.RIGHT))
	assert(MECHANICS.cooldown("ivory_duelist_rapier_v286")==2.5)
	assert(MECHANICS.cooldown("hollowbell_maul_v277")==5.0)
	var spin: Dictionary = MECHANICS.CHANNELS["rosemirror_twinblade_v170"]
	var cyclone: Dictionary = MECHANICS.CHANNELS["cathedral_thorn_twinblade_v231"]
	assert(spin["mode"]=="hybrid" and cyclone["mode"]=="cyclone")
	assert(float(cyclone["drain"])>float(spin["drain"]))
	assert(float(cyclone["radius"])>float(spin["radius"]))
	assert(float(spin["move"])>0.0 and float(cyclone["move"])>0.0)
	assert(GROUND.blade_sweep_contact(Vector2(90,0),0.0,0.2,111.0,18.0))
	assert(GROUND.blade_sweep_contact(Vector2(-90,0),0.0,0.2,111.0,18.0))
	assert(not GROUND.blade_sweep_contact(Vector2(0,90),0.0,0.2,111.0,18.0))
	assert(not GROUND.blade_sweep_contact(Vector2(120,0),0.0,0.2,111.0,18.0))
	assert(GROUND.blade_sweep_contact(Vector2(90,0),TAU-0.1,0.2,111.0,18.0))
	assert(not SPECIAL.is_throw("drowned_fork"))
	assert(SPECIAL.is_throw("heavens_reach"))
	assert(MECHANICS.cooldown("frostveil_bow_v277")==6.2)
	assert(MECHANICS.cooldown("lunar_vigil_halberd")==7.8)
	assert(MECHANICS.cooldown("rosehook_bearded_axe_v286")==7.1)
	var expected: Dictionary = {
		"rosemirror_twinblade_v170":"rosemirror_twinblade_v170",
		"cathedral_thorn_twinblade_v231":"cathedral_thorn_twinblade_v231",
		"frostveil_bow_v277":"frostveil_bow_v277",
		"lunar_vigil_halberd":"lunar_vigil_halberd",
		"rosehook_bearded_axe_v286":"rosehook_bearded_axe_v286",
		"briarwake_trident_v171":"drowned_fork",
		"ossuary_poleaxe_v286":"ossuary_poleaxe_v286",
		"gallows_greataxe_v283":"gallows_greataxe_v283"
	}
	for base in expected:
		var data: GhostItemData = load("res://items/"+str(base)+".tres")
		assert(data!=null)
		var unique: GhostItemInstance = GhostItemGenerator.create(data,288101,"unique")
		var normal: GhostItemInstance = GhostItemGenerator.create(data,288101,"normal")
		assert(SPECIAL.kind(unique)==expected[base])
		assert(SPECIAL.kind(normal).is_empty())
		assert(not SPECIAL.label(unique).is_empty())
		var id: String = expected[base]
		assert(MECHANICS.is_channel(id) or MECHANICS.AREAS.has(id) or MECHANICS.GROUND_SKILLS.has(id))
	print("v2.88 eight bespoke relic routes, angular blade contact, ownership and cooldown definitions PASS")
	quit(0)
