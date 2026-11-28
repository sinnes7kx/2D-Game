extends RefCounted
const GROUND = preload("res://scripts/relic_ground_v288.gd")
const MELEE_RULES = preload("res://scripts/combat/melee_rules.gd")
const AUDIO = preload("res://scripts/combat_juice_v194.gd")
const CHANNELS: Dictionary = {
	"rosemirror_twinblade_v170":{"mode":"hybrid","drain":21.0,"move":0.80,"radius":111.0,"pulse":0.23,"power":0.34,"outer_radius":132.0,"outer_power":0.25},
	"cathedral_thorn_twinblade_v231":{"mode":"cyclone","drain":25.0,"move":0.92,"radius":145.0,"pulse":0.26,"power":0.39}
}
# The previous area-spell specials are retired. Preserve item IDs and the
# compatibility symbol, not the old spell routes.
const AREAS: Dictionary = {}
const PHYSICAL: Dictionary = {
	"lunar_vigil_halberd":{"range":176.0,"dot":0.74,"power":1.75,"poise":2.5,"cooldown":3.8},
	"rosehook_bearded_axe_v286":{"range":128.0,"dot":0.34,"power":1.55,"poise":3.0,"cooldown":3.2}
}
const VOLLEY: Dictionary = {"frostveil_bow_v277":4.0}

static func physical_contact(offset: Vector2, axis: Vector2, reach: float, cone: float) -> bool:
	return MELEE_RULES.frontal_contact(offset,axis,4.0,reach,cone)

static func _physical_strike(actor: CharacterBody2D,item: GhostItemInstance,axis: Vector2,id: String,root: Node) -> void:
	var profile: Dictionary = PHYSICAL[id]
	var damage: float = item.weapon_damage()*float(profile["power"])*(1.0+float(actor.call("_stat","melee_power_pct"))/100.0)
	var hits: int=0
	for other in actor.get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(other) or other.is_queued_for_deletion() or not other is Node2D or not other.has_method("hit"):
			continue
		var point: Vector2=(other as Node2D).global_position
		if not physical_contact(point-actor.global_position,axis,float(profile["range"]),float(profile["dot"])) or not GROUND.clear_path(actor,actor.global_position,point):
			continue
		other.call("hit",damage,float(profile["poise"]))
		preload("res://scripts/impact_spawner_v149.gd").burst(root,point,"slam",0.6,axis,item.visual_seed())
		hits+=1
	if hits>0:
		AUDIO.play(root,actor.global_position,"ground_slam",-15.0)
		actor.set("camera_kick",maxf(float(actor.get("camera_kick")),3.7))
		if item.ethereal:
			actor.get("world").inventory.wear_ethereal(item)
	actor.call("relic_commit_v288",id,cooldown(id))
const GROUND_SKILLS: Dictionary = {
	"drowned_fork":"impale",
	"ossuary_poleaxe_v286":"fissure",
	"gallows_greataxe_v283":"ring",
	"hollowbell_maul_v277":"bells"
}
static func bloom_v290(age: float) -> float:
	return smoothstep(0.35,1.15,age)

static func hybrid_radius_v290(age: float) -> float:
	return lerpf(111.0,132.0,bloom_v290(age))

static func is_channel(id: String) -> bool:
	return CHANNELS.has(id)

static func parry_contact_v289(offset: Vector2,axis: Vector2) -> bool:
	return MELEE_RULES.frontal_contact(offset,axis,4.0,220.0,0.60)

static func cooldown(id: String) -> float:
	if id=="seraph_descent":
		return 4.0
	if id=="ivory_duelist_rapier_v286":
		return 2.5
	if PHYSICAL.has(id):
		return float(PHYSICAL[id]["cooldown"])
	if VOLLEY.has(id):
		return float(VOLLEY[id])
	if id=="hollowbell_maul_v277":
		return 5.0
	if GROUND_SKILLS.has(id):
		return 2.4
	return 0.0

static func launch(actor: CharacterBody2D,item: GhostItemInstance,axis: Vector2,id: String) -> bool:
	if not PHYSICAL.has(id) and not GROUND_SKILLS.has(id):
		return false
	var world: Node = actor.get("world")
	var root: Node = actor.get_tree().current_scene
	if world==null or root==null or item==null or item.is_broken() or world.inventory.get_equipped("sword")!=item:
		return false
	if not actor.call("relic_ready_v288",id):
		return false
	if PHYSICAL.has(id):
		_physical_strike(actor,item,axis,id,root)
		return true
	else:
		var effect: Node2D = GROUND.new()
		var power: float = (18.0+item.weapon_damage())*1.65*(1.0+float(actor.call("_stat","melee_power_pct"))/100.0)
		effect.position=(root as Node2D).to_local(actor.global_position) if root is Node2D else actor.global_position
		effect.call("configure",actor,str(GROUND_SKILLS[id]),axis,power,Color("d9bce2") if id=="drowned_fork" else Color("e4c59d"))
		root.add_child(effect)
		world.call("track_room_effect",effect)
		AUDIO.play(root,actor.global_position,"ground_slam",-14.0)
		if item.ethereal:
			world.inventory.wear_ethereal(item)
	actor.call("relic_commit_v288",id,cooldown(id))
	return true
