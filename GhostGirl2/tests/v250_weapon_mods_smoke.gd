extends SceneTree
const MOD = preload("res://scripts/weapon_mods_v250.gd")
const BOW = preload("res://items/thornrose_bow.tres")
func _initialize() -> void:
	var item: GhostItemInstance = GhostItemGenerator.create(BOW, 123456, "unique")
	assert(item.weapon_mod in [MOD.EXTRA, MOD.RETURN])
	assert(item.display_name() == "Briar's Mercy")
	assert(GhostItemGenerator.create(BOW, 123456, "unique").weapon_mod == item.weapon_mod)
	assert(MOD.roll("sword","bow","normal",123456) == "")
	assert(MOD.sanitize(MOD.RETURN,"wand","blade","unique") == MOD.RETURN)
	assert(MOD.sanitize("frostbite","wand","blade","unique") == "")
	assert(MOD.sanitize("vigor","sword","maul","rare") == "vigor")
	assert(MOD.sanitize("soul_siphon","sword","blade","normal") == "")
	assert(MOD.sanitize("", "sword","bow","unique") == "")
	assert(MOD.projectile_count(MOD.EXTRA,1) == 3)
	assert(MOD.projectile_count(MOD.EXTRA,2) == 4)
	assert(is_equal_approx(MOD.volley_multiplier(MOD.EXTRA)/3.0,0.5))
	assert(is_equal_approx(MOD.angle(0,3),-MOD.angle(2,3)))
	assert(is_zero_approx(MOD.angle(1,3)))
	assert(MOD.roll("sword","maul","unique",999) in MOD.MELEE)
	var genuine: String = item.weapon_mod
	item.debug_weapon_mod = MOD.RETURN if genuine == MOD.EXTRA else MOD.EXTRA
	assert(item.active_weapon_mod(false) == genuine)
	if OS.is_debug_build():
		assert(item.active_weapon_mod(true) == item.debug_weapon_mod)
	assert(item.weapon_mod == genuine)
	var innate = preload("res://scripts/unique_innate_v274.gd")
	assert(innate.POWERS.size()==50)
	var resources: Array[String] = []
	_collect_equipment_paths_v274("res://items",resources)
	var covered: int = 0
	var unique_names: Dictionary = {}
	for path in resources:
		var template: GhostItemData = load(path) as GhostItemData
		if template==null or template.item_class!="equipment" or template.equip_slot=="none":
			continue
		var candidate: GhostItemInstance = GhostItemGenerator.create(template,27401,"unique")
		var active_label: String = preload("res://scripts/unique_specials_v261.gd").label(candidate)
		var passive_label: String = innate.label(candidate)
		assert(not active_label.is_empty() or not passive_label.is_empty(),"Missing unique power: "+path)
		assert(active_label.is_empty() or passive_label.is_empty(),"Double unique power: "+path)
		var label: String = passive_label if active_label.is_empty() else active_label
		assert(not unique_names.has(label),"Duplicate unique power: "+label)
		unique_names[label]=true
		covered+=1
	assert(covered==80)
	var fixed_bonus: Dictionary = innate.bonuses(item)
	assert(fixed_bonus.size()==2)
	assert(float(item.all_stats()["melee_power_pct"])>=float(fixed_bonus["melee_power_pct"]))
	assert(innate.bonuses(GhostItemGenerator.create(BOW,123456,"normal")).is_empty())
	assert(innate.bonuses(GhostItemGenerator.create(preload("res://items/nocturne_stiletto_v171.tres"),123456,"unique")).is_empty())
	var names: Dictionary = {}
	for key in innate.POWERS:
		var profile: Array = innate.POWERS[key]
		assert(profile.size()==5 and profile[1]!=profile[3])
		assert(not names.has(profile[0]))
		names[profile[0]]=true
	var material = preload("res://scripts/gothic_material_v274.gd")
	var plate: StyleBoxTexture = material.plate(Color("17111b"),Color("947650"),18,true)
	assert(plate.texture.get_size()==Vector2(128,96))
	assert(plate.texture==material.plate(Color("17111b"),Color("947650"),18,true).texture)
	var guard = preload("res://scripts/thrown_weapon_lock_v273.gd").new()
	assert(not guard.busy())
	var stale: Node = Node.new()
	guard.register(stale)
	assert(not guard.busy()) # detached nodes never lock combat
	stale.free()
	var fixture: Node = Node.new()
	var other: Node = Node.new()
	root.add_child(fixture)
	root.add_child(other)
	guard.register(fixture)
	guard.register(other)
	assert(guard.busy())
	fixture.free()
	assert(guard.busy())
	other.free()
	assert(not guard.busy())
	var familiar_fx = preload("res://scripts/moonmoth_companion_v202.gd")
	assert(familiar_fx.profile_v273("test",123)==familiar_fx.profile_v273("test",123))
	assert(int(familiar_fx.profile_v273("test",123)["motif"]) in range(8))
	var specials = preload("res://scripts/unique_specials_v261.gd")
	var spear: GhostItemInstance = GhostItemGenerator.create(preload("res://items/moonwarden_spear_v169.tres"),123,"unique")
	assert(specials.kind(spear) == "heavens_reach")
	assert(specials.kind(GhostItemGenerator.create(preload("res://items/moonwarden_spear_v169.tres"),123,"normal")) == "")
	assert(specials.count("drowned_fork") == 3)
	assert(specials.count("roseglass_fan")==3 and specials.is_dagger_throw("vespers_return"))
	assert(specials.kind(GhostItemGenerator.create(preload("res://items/cinderveil_dirk_v238.tres"),2721,"unique"))=="ember_return")
	assert(specials.kind(GhostItemGenerator.create(preload("res://items/roseglass_dagger_v169.tres"),2722,"unique"))=="roseglass_fan")
	assert(specials.kind(GhostItemGenerator.create(preload("res://items/rose_reaper_scythe.tres"),2723,"unique"))=="reverie_wave")
	var env = preload("res://scripts/archery_environment_v272.gd")
	assert(env.segment_intersects_fire(Vector2.ZERO,Vector2(100,0),Vector2(40,5),10.0))
	assert(not env.segment_intersects_fire(Vector2.ZERO,Vector2(30,0),Vector2(60,0),10.0))
	assert(is_equal_approx(env.impact_power(100.0,true),125.0))
	assert(env.effective_element(2,true)==1 and env.effective_element(2,false)==2)
	var panel: Script = preload("res://scripts/equipment_panel.gd")
	assert("companion" in panel.SLOT_NAMES)
	var player_script = preload("res://scripts/player.gd")
	assert(player_script.TWINBLADE_FIRST_GATE_V272>player_script.TWINBLADE_SECOND_GATE_V272)
	assert(is_equal_approx(player_script.TWINBLADE_HIT_POWER_V272*2.0,1.30))
	assert(not player_script.twinblade_second_due_v272(true,0.31,1.0))
	assert(player_script.twinblade_second_due_v272(true,0.30,1.0))
	assert(not player_script.twinblade_second_due_v272(false,0.0,1.0))
	var stiletto: GhostItemInstance = GhostItemGenerator.create(preload("res://items/nocturne_stiletto_v171.tres"),265137,"unique")
	assert(specials.kind(stiletto)=="vespers_return")
	assert(specials.kind(GhostItemGenerator.create(stiletto.definition,265137,"normal"))=="")
	var dagger = preload("res://scripts/returning_stiletto_v265.gd").new()
	dagger.power=100.0
	assert(is_equal_approx(dagger.damage_now(),72.0))
	assert(dagger.register_contact(11) and not dagger.register_contact(11))
	assert(dagger.register_contact(12))
	dagger.begin_return()
	assert(dagger.returning and is_equal_approx(dagger.damage_now(),65.0))
	assert(dagger.register_contact(11) and not dagger.register_contact(11))
	assert(dagger.register_contact(12) and dagger.register_contact(13) and dagger.register_contact(14))
	assert(not dagger.register_contact(15))
	dagger.begin_return()
	assert(not dagger.register_contact(11))
	var fx = preload("res://scripts/stiletto_fx_v267.gd")
	assert(fx.opacity(0.0,2.0,0.0)==0.0)
	assert(fx.opacity(1.0,0.0,0.0)==0.0)
	assert(fx.opacity(1.0,2.0,1.0)==0.0)
	assert(fx.opacity(0.5,2.0,0.5)<fx.opacity(0.5,2.0,0.0))
	assert(fx.duration_for("return_hit")>fx.duration_for("hit"))
	dagger.call("_record_trail",Vector2.ZERO,Vector2(390,0))
	assert(dagger.trail.size()<=dagger.TRAIL_LIMIT)
	assert(dagger.trail.size()>5)
	for i in range(1,dagger.trail.size()):
		assert(is_equal_approx(dagger.trail[i-1].distance_to(dagger.trail[i]),dagger.TRAIL_STEP))
	dagger.free()
	var eclipse: GhostItemInstance = GhostItemGenerator.create(preload("res://items/eclipse_twinblade_v170.tres"),262137,"unique")
	assert(specials.kind(eclipse) == "eclipse_dance")
	assert(specials.kind(GhostItemGenerator.create(eclipse.definition,262137,"normal")) == "")
	var dance = preload("res://scripts/eclipse_dance_v262.gd")
	assert(dance.timings(1).size()==4 and dance.timings(2).size()==2)
	assert(dance.motion(1,0.5)>0.0 and dance.motion(2,0.55)<0.0)
	assert(dance.can_chain(0.6) and not dance.can_chain(0.1))
	assert(dance.spin(1,dance.FIRST)>TAU)
	var faces: Dictionary = {}
	for i in range(80):
		var t: float = dance.FIRST*float(i)/80.0
		faces[dance.facing_at(Vector2.RIGHT,1,t)] = true
		assert(dance.frame_at(1,t,8) in range(8))
		assert(is_equal_approx(dance.blade_axis(Vector2.RIGHT,1,t).length(),1.0))
	assert(faces.size()==4)
	assert(dance.blade_axis(Vector2.RIGHT,1,dance.FIRST).is_equal_approx(dance.blade_axis(Vector2.RIGHT,2,0.0)))
	assert(dance.chain_remaining(0.6)>dance.chain_remaining(1.0))
	assert(dance.chain_remaining(0.1)==0.0)
	var total: float = 0.0
	for stage in [1,2]:
		for i in range(dance.timings(stage).size()):
			total += dance.hit_multiplier(stage,i)
	assert(is_equal_approx(total,1.75))
	var inventory: Node = preload("res://scripts/inventory.gd").new()
	var saved: Dictionary = inventory.call("_serialize_item", item, Vector2i.ZERO)
	var restored: GhostItemInstance = inventory.call("_deserialize_item", saved)
	assert(restored != null and restored.weapon_mod == item.weapon_mod)
	assert(restored.debug_weapon_mod.is_empty())
	assert(restored.item_seed == item.item_seed and restored.affixes == item.affixes)
	saved.erase("weapon_mod_v250")
	var legacy: GhostItemInstance = inventory.call("_deserialize_item", saved)
	assert(legacy != null and legacy.weapon_mod.is_empty())
	# Old scenes could still export 72. Restore and withdraw by grid fit.
	inventory.set("capacity",72)
	var pet = preload("res://items/moonwisp_companion_v239.tres")
	var records: Array = []
	for i in range(90):
		var specimen: GhostItemInstance = GhostItemGenerator.create(pet,261000+i,"normal")
		records.append(inventory.call("_serialize_item",specimen,Vector2i(i%10,i/10)))
	var recovery: Dictionary = {"items":records,"grid_rows":6,"vault":[records[0].duplicate(true)],"collected":{"v261_lanternhaven_moonwisp_01":true},"equipment":{"companion":89}}
	assert(inventory.call("_restore_save_data",recovery))
	assert(inventory.get("contents").size()==90)
	assert(inventory.get("unresolved_backpack").is_empty())
	assert(inventory.call("get_equipped","companion").item_seed==261089)
	assert(inventory.call("has_collected","v261_lanternhaven_moonwisp_01"))
	assert(inventory.call("vault_withdraw",0,false))
	assert(inventory.get("contents").size()==91)
	inventory.free()
	var spell: Node2D = preload("res://scripts/moon_spell.gd").new()
	spell.set("spell_form", 7)
	spell.set("damage", 10.0)
	spell.call("_begin_return", Vector2(20, 40))
	assert(bool(spell.get("returning")) and int(spell.get("spell_form")) == 0)
	assert(is_equal_approx(float(spell.get("damage")), 6.0))
	spell.free()
	print("v251 weapon mods: deterministic rolls, save roundtrip, legacy defaults and return phase")
	quit(0)

func _collect_equipment_paths_v274(path: String,out: Array[String]) -> void:
	var dir: DirAccess = DirAccess.open(path)
	if dir==null:
		return
	for file in dir.get_files():
		if file.ends_with(".tres"):
			out.append(path.path_join(file))
	for folder in dir.get_directories():
		if not folder.begins_with("."):
			_collect_equipment_paths_v274(path.path_join(folder),out)
