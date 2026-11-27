extends RefCounted
## Base-specific abilities of genuine unique weapons. No changes to loot rolls.
const SPECIALS: Dictionary = {
	"moonwarden_spear_v169": "heavens_reach",
	"briarwake_trident_v171": "drowned_fork",
	"gravebell_maul_v170": "last_toll"
}
const NAMES: Dictionary = {
	"heavens_reach": "Heaven's Reach · Returning spear throw",
	"drowned_fork": "Drowned Crown · Three spectral spears",
	"last_toll": "Last Toll · Traveling shockwave"
}

static func kind(item: Variant) -> String:
	if item == null or item.definition == null or item.quality != "unique" or item.is_broken():
		return ""
	return str(SPECIALS.get(str(item.definition.item_id),""))

static func label(item: Variant) -> String:
	return str(NAMES.get(kind(item),""))

static func count(id: String) -> int:
	return 3 if id == "drowned_fork" else 1

static func launch(actor: CharacterBody2D, item: GhostItemInstance, heading: Vector2, id: String) -> void:
	if kind(item) != id or heading.is_zero_approx():
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
	var n: int = count(id)
	var power: float = (34.0 + item.weapon_damage()) * (1.0+float(actor.call("_stat","melee_power_pct"))/100.0) * (1.0+float(actor.call("_stat","heavy_power_pct"))/100.0)
	for i in range(n):
		var shot: Node2D = preload("res://scripts/special_projectile_v261.gd").new()
		shot.set("special_id",id)
		shot.set("direction",heading.rotated(deg_to_rad((float(i)-float(n-1)*0.5)*12.0)))
		shot.set("speed",780.0 if id != "last_toll" else 470.0)
		shot.set("damage",power*1.10/float(n))
		shot.set("range_left",560.0 if id != "last_toll" else 310.0)
		shot.set("caster",actor)
		shot.set("caster_rid",actor.get_rid())
		shot.set("is_crossbow_bolt",true)
		shot.set("secondary_projectile",true)
		shot.set("can_return",id == "heavens_reach")
		shot.set("full_palette",item.glow_gradient_colors())
		shot.set("visual_glow_scale",preload("res://scripts/visual_choices_v216.gd").effect_scale(item))
		root.add_child(shot)
		shot.global_position = origin
		world.call("track_room_effect",shot)
