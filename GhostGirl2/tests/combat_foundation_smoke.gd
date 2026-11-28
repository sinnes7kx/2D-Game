extends SceneTree
const RULES = preload("res://scripts/combat/melee_rules.gd")
const PLAYER = preload("res://scripts/player.gd")
const RELICS = preload("res://scripts/relic_mechanics_v288.gd")

func _initialize() -> void:
	# Original balance fixture: light reach, heavy reach, light multiplier,
	# heavy multiplier, light dot, heavy dot, poise. Independent of new module.
	var expected: Dictionary = {
		"blade":[144.0,174.0,1.0,1.0,0.32,0.12,1.0],
		"scythe":[184.0,216.0,0.95,1.06,0.12,-0.05,1.12],
		"halberd":[206.0,242.0,1.08,1.28,0.48,0.34,1.35],
		"dagger":[112.0,143.0,0.77,0.90,0.10,0.08,0.70],
		"dual_dagger":[122.0,153.0,0.80,0.96,0.15,0.14,0.73],
		"dual_sword":[165.0,199.0,0.97,1.18,0.12,0.08,0.96],
		"spear":[213.0,252.0,0.96,1.18,0.71,0.64,1.12],
		"rapier":[176.0,214.0,0.94,1.10,0.91,0.86,0.85],
		"axe":[172.0,208.0,1.09,1.37,0.15,-0.02,1.52],
		"maul":[173.0,211.0,1.13,1.45,0.23,0.04,1.65],
		"twinblade":[168.0,206.0,0.87,1.05,0.01,-0.10,0.85]
	}
	for family in expected:
		var row: Array = expected[family]
		for heavy in [false,true]:
			var h: int = int(heavy)
			for combo in range(3):
				var profile = RULES.base_profile(family,heavy,true,combo)
				assert(is_equal_approx(profile.reach,float(row[h])))
				assert(is_equal_approx(profile.power,(34.0 if heavy else [16.0,19.0,24.0][combo])*float(row[2+h])))
				assert(is_equal_approx(profile.arc,float(row[4+h])))
				assert(is_equal_approx(profile.poise,float(row[6])))
	assert(RULES.base_profile("unarmed",false,false,0).reach==106.0)
	assert(RULES.base_profile("unarmed",true,false,0).reach==128.0)
	for i in range(8):
		var aim: Vector2 = Vector2.from_angle(float(i)*PI/4.0)
		assert(RULES.frontal_contact(aim*60.0,aim,4.0,100.0,0.60))
		assert(not RULES.frontal_contact(-aim*60.0,aim,4.0,100.0,0.60))
		assert(not RULES.frontal_contact(aim*101.0,aim,4.0,100.0,0.60))
		assert(not RULES.frontal_contact(Vector2.ZERO,aim,4.0,100.0,0.60))
		assert(PLAYER.parry_result(0.10,aim,aim*60.0)==2)
		assert(RELICS.physical_contact(aim*60.0,aim,100.0,0.60))
		assert(RELICS.parry_contact_v289(aim*60.0,aim))
	assert(RULES.frontal_contact(Vector2(100,0),Vector2.RIGHT,4.0,100.0,1.0))
	assert(not RULES.frontal_contact(Vector2(2,0),Vector2.RIGHT,4.0,100.0,0.60))
	assert(not RULES.frontal_contact(Vector2(60,0),Vector2.ZERO,4.0,100.0,0.60))
	assert(RULES.frontal_contact(Vector2(10000,0),Vector2.RIGHT,1.0,-1.0,0.50))
	print("Combat foundation: 66 legacy weapon profiles and shared frontal geometry PASS")
	quit(0)
