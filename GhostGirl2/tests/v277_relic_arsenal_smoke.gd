extends SceneTree
const ARSENAL = preload("res://scripts/relic_arsenal_v277.gd")
const SPECIAL = preload("res://scripts/unique_specials_v261.gd")
const INNATE = preload("res://scripts/unique_innate_v274.gd")
const GRADE = preload("res://scripts/gothic_grade_v277.gd")
const SHOT = preload("res://scripts/relic_skill_projectile_v277.gd")

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	assert(ARSENAL.PROFILES.size()==23)
	assert(SPECIAL.SPECIALS.size()==12)
	assert(INNATE.POWERS.size()==50)
	var names: Dictionary = {}
	for id in ARSENAL.PROFILES:
		var profile: Dictionary = ARSENAL.PROFILES[id]
		assert(not names.has(profile["name"]))
		names[profile["name"]]=true
		assert(not INNATE.POWERS.has(id))
		assert(not SPECIAL.SPECIALS.has(id))
		assert(int(profile["count"])>=1 and int(profile["count"])<=8)
		assert(float(profile["power"])>0.0 and float(profile["power"])<=2.3)
		assert(float(profile["speed"])>0.0 and float(profile["range"])>0.0)
		var data: GhostItemData = GhostItemData.new()
		data.item_id=str(id)
		data.equip_slot="sword"
		data.weapon_style="bow"
		var unique: GhostItemInstance = GhostItemGenerator.create(data,277123,"unique")
		var normal: GhostItemInstance = GhostItemGenerator.create(data,277123,"normal")
		assert(SPECIAL.kind(unique)==id)
		assert(SPECIAL.kind(normal).is_empty())
		assert(SPECIAL.label(unique)==ARSENAL.label(id))
		var shot: Node2D = SHOT.new()
		shot.set("profile",profile)
		assert(is_equal_approx(float(shot.call("contact_stagger_v276")),float(profile["stagger"])))
		shot.free()
	var grade: CanvasLayer = GRADE.new()
	root.add_child(grade)
	assert(grade.layer==10)
	assert(grade.get("screen_rect").mouse_filter==Control.MOUSE_FILTER_IGNORE)
	assert(GRADE.STRENGTH[0]==0.0)
	assert(GRADE.STRENGTH[3]>GRADE.STRENGTH[2])
	assert(grade.get("grade_material").shader!=null)
	grade.queue_free()
	print("v2.77 relic skill identities, bounded profiles and grade layer PASS")
	quit(0)
