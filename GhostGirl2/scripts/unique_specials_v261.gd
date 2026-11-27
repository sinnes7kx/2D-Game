extends RefCounted
## Base-specific abilities of genuine unique weapons. No changes to loot rolls.
const ARSENAL = preload("res://scripts/relic_arsenal_v277.gd")
const SPECIALS: Dictionary = {
	"moonwarden_spear_v169": "heavens_reach",
	"briarwake_trident_v171": "drowned_fork",
	"gravebell_maul_v170": "last_toll",
	"eclipse_twinblade_v170": "eclipse_dance",
	"nocturne_stiletto_v171": "vespers_return",
	"cinderveil_dirk_v238": "ember_return",
	"roseglass_dagger_v169": "roseglass_fan",
	"rose_reaper_scythe": "reverie_wave",
	"silkglass_dirk_v276": "winter_return",
	"bellthorn_lance_v276": "bellthorn_judgment",
	"ivory_misericorde_v233": "ivory_return",
	"reliquary_knife_v238": "reliquary_fan"
}
const NAMES: Dictionary = {
	"heavens_reach": "Heaven's Reach · Returning spear throw",
	"drowned_fork": "Drowned Crown · Three spectral spears",
	"last_toll": "Last Toll · Traveling shockwave",
	"eclipse_dance": "Crimson Eclipse · Advancing blade dance and optional retreat",
	"vespers_return": "Vesper’s Return · Piercing throw, hits again on return",
	"ember_return": "Ember’s Promise · Burning returning dagger",
	"roseglass_fan": "Rose’s Secret · Three spectral needles",
	"reverie_wave": "Death’s Reverie · Traveling crescent",
	"winter_return": "Winterglass · Returning blade slows enemies",
	"bellthorn_judgment": "Bellthorn Judgment · Returning lance with crushing stagger",
	"ivory_return": "Ivory Absolution · Returning blade restores 3 life on first hit",
	"reliquary_fan": "Reliquary Seal · Three slowing spectral needles"
}

static func kind(item: Variant) -> String:
	if item == null or item.definition == null or (item.quality != "unique" and not item.definition.unique) or item.is_broken():
		return ""
	var base: String = str(item.definition.item_id)
	var relic: String = ARSENAL.base_key(item)
	return relic if not relic.is_empty() else str(SPECIALS.get(base,""))

static func label(item: Variant) -> String:
	var id: String = kind(item)
	return ARSENAL.label(id) if ARSENAL.has_skill(id) else str(NAMES.get(id,""))

static func count(id: String) -> int:
	return 3 if id in ["drowned_fork","roseglass_fan","reliquary_fan"] else 1

static func is_dagger_throw(id: String) -> bool:
	return id in ["vespers_return","ember_return","roseglass_fan","winter_return","ivory_return","reliquary_fan"]

static func is_throw(id: String) -> bool:
	return is_dagger_throw(id) or id in ["heavens_reach","drowned_fork","bellthorn_judgment"]

static func charge_power(charge: float) -> float:
	return lerpf(0.75,1.35,clampf(charge,0.0,1.0))

static func launch(actor: CharacterBody2D, item: GhostItemInstance, heading: Vector2, id: String, charge: float = 0.0) -> void:
	if kind(item) != id or heading.is_zero_approx() or id == "eclipse_dance" or actor.call("thrown_weapon_busy_v273"):
		return
	var world: Node = actor.get("world")
	var root: Node = actor.get_tree().current_scene
	if world == null or root == null:
		return
	var body: AnimatedSprite2D = actor.get_node_or_null("Ghost") as AnimatedSprite2D
	var origin: Vector2 = actor.global_position + Vector2(0,-39) + heading*18.0
	if body != null:
		var rig: Node = body.get_node_or_null("WeaponPoseV172")
		if rig != null and rig.has_method("get_weapon_span"):
			var span: PackedVector2Array = rig.call("get_weapon_span",str(body.animation),body.frame)
			if span.size() == 2:
				origin = body.to_global(span[0])
	if ARSENAL.has_skill(id):
		ARSENAL.launch(actor,item,heading,id,origin)
		return
	var n: int = count(id)
	var power: float = (34.0 + item.weapon_damage()) * (1.0+float(actor.call("_stat","melee_power_pct"))/100.0) * (1.0+float(actor.call("_stat","heavy_power_pct"))/100.0)
	if is_throw(id):
		charge=clampf(charge,0.0,1.0)
		power*=charge_power(charge)
		actor.set("camera_kick",maxf(float(actor.get("camera_kick")),lerpf(3.0,6.0,charge)))
		actor.set("camera_push",-heading.normalized()*lerpf(2.0,5.0,charge))
		preload("res://scripts/combat_juice_v194.gd").play(root,origin,"throw_release",-12.0)
		preload("res://scripts/impact_spawner_v149.gd").burst(root,origin,"slam",lerpf(0.4,0.8,charge),heading,item.visual_seed())
	if id in ["vespers_return","ember_return","winter_return","ivory_return"]:
		var dagger = preload("res://scripts/returning_stiletto_v265.gd").new()
		dagger.caster = actor
		dagger.direction = heading.normalized()
		dagger.power = power
		dagger.ember_v272 = id=="ember_return"
		dagger.throw_charge_v276=charge
		dagger.special_id_v276=id
		dagger.palette = item.glow_gradient_colors()
		dagger.glow = preload("res://scripts/visual_choices_v216.gd").effect_scale(item)
		root.add_child(dagger)
		dagger.global_position = origin
		world.call("track_room_effect",dagger)
		actor.call("register_thrown_weapon_v273",dagger)
		return
	for i in range(n):
		var shot: Node2D = preload("res://scripts/special_projectile_v261.gd").new()
		shot.set("special_id",id)
		shot.set("throw_charge_v276",charge)
		shot.set("direction",heading.rotated(deg_to_rad((float(i)-float(n-1)*0.5)*12.0)))
		shot.set("speed",(980.0 if id in ["roseglass_fan","reliquary_fan"] else (470.0 if id in ["last_toll","reverie_wave"] else 780.0)) * (lerpf(0.88,1.18,charge) if is_throw(id) else 1.0))
		shot.set("damage",power*1.10/float(n))
		shot.set("range_left",(360.0 if id in ["roseglass_fan","reliquary_fan"] else (310.0 if id in ["last_toll","reverie_wave"] else 560.0)) * (lerpf(0.85,1.15,charge) if is_throw(id) else 1.0))
		shot.set("caster",actor)
		shot.set("caster_rid",actor.get_rid())
		shot.set("is_crossbow_bolt",true)
		shot.set("secondary_projectile",true)
		shot.set("can_return",id in ["heavens_reach","bellthorn_judgment"])
		shot.set("full_palette",item.glow_gradient_colors())
		shot.set("visual_glow_scale",preload("res://scripts/visual_choices_v216.gd").effect_scale(item))
		root.add_child(shot)
		shot.global_position = origin
		world.call("track_room_effect",shot)
		if is_throw(id):
			actor.call("register_thrown_weapon_v273",shot)
