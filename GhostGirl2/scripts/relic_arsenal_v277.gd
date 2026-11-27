extends RefCounted
## Each item base owns its skill, projectile behavior, shape and damage budget.
## Spectral special shots are separate from physical archery/puzzle scoring.
const SHOT = preload("res://scripts/relic_skill_projectile_v277.gd")
const AUDIO = preload("res://scripts/combat_juice_v194.gd")
const IMPACT = preload("res://scripts/impact_spawner_v149.gd")
const PROFILES: Dictionary = {
	"cathedral_rapier_v283": {"name":"The Gilded Verdict","description":"Piercing golden thrust with high stagger","pattern":"single","count":1,"spread":0,"power":2.1,"speed":1250,"range":440,"stagger":2.2,"effect":"pierce","ink":"e9c694"},
	"moonneedle_rapier_v283": {"name":"Lunar Oath","description":"Twin piercing frost needles","pattern":"fan","count":2,"spread":6,"power":2,"speed":1320,"range":480,"stagger":0.9,"effect":"frost_pierce","ink":"a6d9f3"},
	"briar_hatchet_v283": {"name":"Briar's Severance","description":"Two returning spectral axe crescents","pattern":"blade","count":2,"spread":16,"power":1.9,"speed":720,"range":310,"stagger":1.25,"effect":"return","ink":"d89aa6"},
	"gravecleaver_axe_v283": {"name":"Gravecleaver's Toll","description":"A crushing explosive cleave","pattern":"blade","count":1,"spread":0,"power":2.25,"speed":560,"range":310,"stagger":2.4,"effect":"burst","ink":"c6bdd7"},
	"gallows_greataxe_v283": {"name":"Gallows Requiem","description":"Six radial staggering shockwaves","pattern":"radial","count":6,"spread":60,"power":2.3,"speed":480,"range":245,"stagger":2.1,"effect":"none","ink":"e0bc89"},
	"mourning_longsword": {"name":"Grief's Edge","description":"Two sweeping spectral crescents","pattern":"blade","count":2,"spread":22,"power":1.9,"speed":610,"range":285,"stagger":1.2,"effect":"none","ink":"c39cc3"},
	"moonveil_grandblade": {"name":"Hollow Moon","description":"A broad crescent bursts on contact","pattern":"blade","count":1,"spread":0,"power":2.25,"speed":490,"range":320,"stagger":1.8,"effect":"burst","ink":"c4c6f7"},
	"vesper_rapier": {"name":"Heart's Silence","description":"A precise piercing thrust","pattern":"single","count":1,"spread":0,"power":2,"speed":1260,"range":410,"stagger":1,"effect":"pierce","ink":"e7c2d5"},
	"lunar_vigil_halberd": {"name":"Endless Vigil","description":"A long-reaching staggering crescent","pattern":"blade","count":1,"spread":0,"power":2.2,"speed":680,"range":440,"stagger":2.7,"effect":"none","ink":"dad2ab"},
	"moonlace_dual_daggers_v173": {"name":"Moon's Teeth","description":"Twin piercing frost needles","pattern":"fan","count":2,"spread":9,"power":1.8,"speed":1150,"range":360,"stagger":0.9,"effect":"frost_pierce","ink":"b3d8fb"},
	"mourninglace_dual_daggers_v231": {"name":"Weeping Sisters","description":"Two spectral blades restore stamina on contact","pattern":"fan","count":2,"spread":15,"power":1.7,"speed":1000,"range":310,"stagger":0.9,"effect":"stamina","ink":"c4a4b9"},
	"gloamrose_dual_swords_v174": {"name":"Bride and Widow","description":"Two returning spectral blades","pattern":"blade","count":2,"spread":14,"power":1.9,"speed":790,"range":350,"stagger":1.2,"effect":"return","ink":"e6a8c1"},
	"cathedral_dual_swords_v233": {"name":"Broken Vows","description":"Twin crushing crescents","pattern":"blade","count":2,"spread":9,"power":2.15,"speed":650,"range":290,"stagger":2.35,"effect":"none","ink":"d7b78d"},
	"vesperthorn_dual_swords_v231": {"name":"Sorrow and Solace","description":"Twin rose blades restore 3 life per first contact","pattern":"blade","count":2,"spread":18,"power":1.75,"speed":740,"range":290,"stagger":1.05,"effect":"heal","ink":"df8da9"},
	"rosemirror_twinblade_v170": {"name":"Rose Reflection","description":"Four spectral crescents circle outward","pattern":"radial","count":4,"spread":90,"power":2,"speed":520,"range":230,"stagger":1.15,"effect":"none","ink":"e7b5ca"},
	"cathedral_thorn_twinblade_v231": {"name":"Martyr Crown","description":"Six radial stagger crescents","pattern":"radial","count":6,"spread":60,"power":2.25,"speed":480,"range":215,"stagger":2,"effect":"none","ink":"d2b58c"},
	"widowglass_twinblade_v231": {"name":"Widow Embrace","description":"Three piercing frost crescents","pattern":"blade","count":3,"spread":24,"power":1.9,"speed":680,"range":285,"stagger":1.1,"effect":"frost_pierce","ink":"b4b1f1"},
	"blackthorn_bow_v234": {"name":"Widow's Volley","description":"Five narrow arrows fan outward","pattern":"fan","count":5,"spread":8.0,"power":1.65,"speed":1030.0,"range":660.0,"stagger":0.9,"effect":"none","ink":"b989c5"},
	"moonveil_bow": {"name":"Lunar Needle","description":"A piercing frost arrow slows up to two enemies","pattern":"single","count":1,"spread":0.0,"power":1.8,"speed":1200.0,"range":880.0,"stagger":0.9,"effect":"frost_pierce","ink":"a7d9fb"},
	"thornrose_bow": {"name":"Briar's Mercy","description":"A wide triple volley restores stamina on first contact per arrow","pattern":"fan","count":3,"spread":16.0,"power":1.5,"speed":930.0,"range":620.0,"stagger":0.8,"effect":"stamina","ink":"d898a9"},
	"mourning_yew_bow_v238": {"name":"Grief Drawn","description":"A heavy arrow bursts around its first target","pattern":"single","count":1,"spread":0.0,"power":1.55,"speed":790.0,"range":720.0,"stagger":1.15,"effect":"burst","ink":"c4a0bb"},
	"reliquary_silver_bow_v234": {"name":"Silver Promise","description":"Returning silver arrow can strike a second distinct enemy","pattern":"single","count":1,"spread":0.0,"power":1.7,"speed":1100.0,"range":650.0,"stagger":0.95,"effect":"return","ink":"ddd9e5"},
	"v202_fletcher_moonflight_bow": {"name":"Falling Star","description":"Three fast piercing star arrows","pattern":"fan","count":3,"spread":6.0,"power":1.55,"speed":1370.0,"range":850.0,"stagger":0.8,"effect":"pierce","ink":"f0dbab"},
	"vesper_recurve_bow_v238": {"name":"Evenfall Aim","description":"Twin frost arrows spread and slow targets","pattern":"fan","count":2,"spread":10.0,"power":1.65,"speed":1230.0,"range":760.0,"stagger":0.85,"effect":"frost","ink":"b1a6ed"},
	"lament_moonbow": {"name":"Four Laments","description":"Four spectral arrows in a wide mourning fan","pattern":"fan","count":4,"spread":13.0,"power":1.8,"speed":960.0,"range":700.0,"stagger":1.05,"effect":"pierce","ink":"b8b8e3"},
	"rafterfall_moonbow": {"name":"Rafterfall","description":"Heavy arrow with exceptional stagger and short range","pattern":"single","count":1,"spread":0.0,"power":2.1,"speed":900.0,"range":520.0,"stagger":2.5,"effect":"none","ink":"d4b68f"},
	"mourning_girder_bow": {"name":"Girder's Resolve","description":"Three short-range stagger arrows","pattern":"fan","count":3,"spread":10.0,"power":1.8,"speed":850.0,"range":460.0,"stagger":2,"effect":"none","ink":"c5ae91"},
	"choral_moonbow": {"name":"Moon Choir","description":"Six spectral arrows spread in a wide choir","pattern":"fan","count":6,"spread":10.0,"power":1.9,"speed":1000.0,"range":620.0,"stagger":0.75,"effect":"none","ink":"d4c3f4"},
	"sunlace_longbow": {"name":"Sunlace","description":"A sunlit arrow bursts against clustered enemies","pattern":"single","count":1,"spread":0.0,"power":1.85,"speed":1260.0,"range":900.0,"stagger":0.9,"effect":"burst","ink":"ffca82"},
	"blackthorn_crossbow_v236": {"name":"Twin Requiem","description":"Twin heavy piercing bolts","pattern":"fan","count":2,"spread":4.0,"power":2,"speed":1550.0,"range":920.0,"stagger":1.1,"effect":"pierce","ink":"caa0c6"},
	"silver_reliquary_crossbow_v236": {"name":"Saint's Verdict","description":"A silver bolt restores life on its first enemy hit","pattern":"single","count":1,"spread":0.0,"power":1.85,"speed":1450.0,"range":900.0,"stagger":1,"effect":"heal","ink":"f7e5c4"},
	"vesper_latch_crossbow_v237": {"name":"The Last Word","description":"Three fast bolts slow enemies","pattern":"fan","count":3,"spread":7.0,"power":1.8,"speed":1480.0,"range":780.0,"stagger":1,"effect":"frost","ink":"a2c6e8"},
	"ossuary_arbalest_v237": {"name":"Bone Covenant","description":"One crushing bolt bursts on impact","pattern":"single","count":1,"spread":0.0,"power":2.05,"speed":1250.0,"range":880.0,"stagger":2.1,"effect":"burst","ink":"ddd4b7"},
	"ashglass_warmaul_v170": {"name":"Cathedral Ruin","description":"A radial eight-wave ground shock","pattern":"radial","count":8,"spread":45.0,"power":2.3,"speed":440.0,"range":165.0,"stagger":1.5,"effect":"none","ink":"d9a6a4"},
	"v203_mournful_mace": {"name":"Mercy Denied","description":"A focused crushing ground wave","pattern":"wave","count":1,"spread":0.0,"power":2.25,"speed":490.0,"range":300.0,"stagger":3.2,"effect":"none","ink":"d6b7a4"},
	"v203_nightchain_flail": {"name":"Unbroken Chain","description":"Five chained waves sweep a broad frontal arc","pattern":"wave","count":5,"spread":22.0,"power":2,"speed":530.0,"range":245.0,"stagger":1.65,"effect":"none","ink":"aa9dc5"},
	"v203_rosequartz_morningstar": {"name":"Dawn Sorrow","description":"Six radial waves restore stamina on contact","pattern":"radial","count":6,"spread":60.0,"power":1.8,"speed":465.0,"range":190.0,"stagger":1.2,"effect":"stamina","ink":"e5a4be"},
	"frostveil_bow_v277": {"name":"Winter's Choir","description":"A broad frost fan of five slowing arrows","pattern":"fan","count":5,"spread":11.0,"power":1.85,"speed":1040.0,"range":680.0,"stagger":0.95,"effect":"frost","ink":"9adfe9"},
	"mourning_star_crossbow_v277": {"name":"Astral Sentence","description":"A long-range returning piercing bolt","pattern":"single","count":1,"spread":0.0,"power":2.1,"speed":1540.0,"range":960.0,"stagger":1.35,"effect":"return_pierce","ink":"c7a8ff"},
	"hollowbell_maul_v277": {"name":"Hollow Cathedral","description":"Three seismic waves burst on enemy contact","pattern":"wave","count":3,"spread":18.0,"power":2.1,"speed":420.0,"range":290.0,"stagger":2,"effect":"burst","ink":"e0bb83"}
}

static func has_skill(id: String) -> bool:
	return PROFILES.has(id)

static func base_key(item: Variant) -> String:
	if item==null or item.definition==null:
		return ""
	var id: String = str(item.definition.item_id)
	if has_skill(id):
		return id
	var basename: String = item.definition.resource_path.get_file().get_basename()
	return basename if has_skill(basename) else ""

static func label(id: String) -> String:
	var p: Dictionary = PROFILES.get(id,{})
	return "" if p.is_empty() else str(p["name"])+" · "+str(p["description"])

static func launch(actor: CharacterBody2D, item: GhostItemInstance, heading: Vector2, id: String, origin: Vector2) -> bool:
	if not has_skill(id) or item==null or item.definition==null or base_key(item)!=id or item.is_broken():
		return false
	if item.quality!="unique" and not item.definition.unique:
		return false
	var world: Node = actor.get("world")
	var root: Node = actor.get_tree().current_scene
	if world==null or root==null or world.get("inventory").get_equipped("sword")!=item:
		return false
	var p: Dictionary = PROFILES[id]
	var count: int = int(p["count"])
	var axis: Vector2 = heading.normalized()
	if axis.is_zero_approx():
		axis=Vector2.DOWN
	var radial: bool = p["pattern"]=="radial"
	var wave: bool = radial or p["pattern"]=="wave"
	if wave:
		origin=actor.global_position+Vector2(0,-21)+axis*12.0
	var power: float = item.weapon_damage()*float(p["power"])*(1.0+float(actor.call("_stat","melee_power_pct"))/100.0)
	if wave:
		power*=1.0+float(actor.call("_stat","heavy_power_pct"))/100.0
	for i in range(count):
		var shot: Node2D = SHOT.new()
		shot.set("profile",p)
		shot.set("direction",axis.rotated(TAU*float(i)/float(count) if radial else deg_to_rad((float(i)-float(count-1)*0.5)*float(p["spread"]))))
		shot.set("speed",float(p["speed"]))
		shot.set("range_left",float(p["range"]))
		shot.set("damage",power/float(count))
		shot.set("caster",actor)
		shot.set("caster_rid",actor.get_rid())
		shot.set("is_crossbow_bolt",true)
		shot.set("secondary_projectile",true)
		shot.set("charged",str(p["effect"]).contains("pierce"))
		shot.set("can_return",str(p["effect"]).begins_with("return"))
		shot.set("visual_glow_scale",preload("res://scripts/visual_choices_v216.gd").effect_scale(item))
		shot.set("full_palette",item.glow_gradient_colors())
		root.add_child(shot)
		shot.global_position=origin
		world.call("track_room_effect",shot)
	AUDIO.play(root,origin,"ground_slam" if wave else ("crossbow_fire" if item.weapon_style()=="crossbow" else "charged_swing"),-12.0)
	IMPACT.burst(root,origin,"slam",0.85 if wave else 0.42,axis,item.visual_seed())
	actor.set("camera_kick",maxf(float(actor.get("camera_kick")),5.0 if wave else 2.8))
	actor.set("camera_push",-axis*(3.4 if wave else 1.8))
	return true
