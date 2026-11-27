extends RefCounted
const GROUND = preload("res://scripts/relic_ground_v288.gd")
const AUDIO = preload("res://scripts/combat_juice_v194.gd")
const CHANNELS: Dictionary = {
	"rosemirror_twinblade_v170":{"mode":"spin","drain":17.0,"move":0.74,"radius":111.0,"pulse":0.23,"power":0.34},
	"cathedral_thorn_twinblade_v231":{"mode":"cyclone","drain":25.0,"move":0.92,"radius":145.0,"pulse":0.26,"power":0.39}
}
const AREAS: Dictionary = {
	"frostveil_bow_v277":"moonfall",
	"lunar_vigil_halberd":"astral",
	"rosehook_bearded_axe_v286":"roses"
}
const GROUND_SKILLS: Dictionary = {
	"drowned_fork":"impale",
	"ossuary_poleaxe_v286":"fissure",
	"gallows_greataxe_v283":"ring"
}
static func is_channel(id: String) -> bool:
	return CHANNELS.has(id)

static func parry_contact_v289(offset: Vector2,axis: Vector2) -> bool:
	return offset.length_squared()>4.0 and offset.length_squared()<=220.0*220.0 and not axis.is_zero_approx() and offset.normalized().dot(axis.normalized())>=0.60

static func cooldown(id: String) -> float:
	if id=="ivory_duelist_rapier_v286":
		return 2.5
	if AREAS.has(id):
		match AREAS[id]:
			"moonfall": return 6.2
			"astral": return 7.8
			"roses": return 7.1
	if GROUND_SKILLS.has(id):
		return 2.4
	return 0.0

static func launch(actor: CharacterBody2D,item: GhostItemInstance,axis: Vector2,id: String) -> bool:
	if not AREAS.has(id) and not GROUND_SKILLS.has(id):
		return false
	var world: Node = actor.get("world")
	var root: Node = actor.get_tree().current_scene
	if world==null or root==null or item==null or item.is_broken() or world.inventory.get_equipped("sword")!=item:
		return false
	if not actor.call("relic_ready_v288",id):
		return false
	if AREAS.has(id):
		var target: Vector2 = actor.global_position+axis.normalized()*350.0
		if not bool(actor.get("controller_active_v260")):
			target=actor.get_global_mouse_position()
		var lock: Node2D = actor.get("lock_target")
		if is_instance_valid(lock):
			target=lock.global_position
		if not bool(world.call("cast_relic_area_v288",str(AREAS[id]),item,target)):
			return false
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
