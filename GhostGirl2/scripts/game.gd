extends Node2D
## Act 1 scene orchestrator. All doors, carryables, plates, puzzle pieces,
## visual clues, collision bodies and effects are EDITABLE ROOM NODES.
## No dialogue, lore pop-ups, or runtime construction of puzzle props.

const ROOMS = {
	"moonwake_crypt": preload("res://scenes/rooms/moonwake_crypt.tscn"),
	"hollow_veil_moor": preload("res://scenes/rooms/hollow_veil_moor.tscn"),
	"garden": preload("res://scenes/rooms/garden.tscn"),
	"crypt_gallery": preload("res://scenes/rooms/crypt_gallery.tscn"),
	"garden_bridge": preload("res://scenes/rooms/garden_bridge.tscn"),
	"garden_arbor": preload("res://scenes/rooms/garden_arbor.tscn"),
	"moonthorn_woods": preload("res://scenes/rooms/moonthorn_woods.tscn"),
	"weeping_brook": preload("res://scenes/rooms/weeping_brook.tscn"),
	"briar_hollow": preload("res://scenes/rooms/briar_hollow.tscn"),
	"reliquary_path": preload("res://scenes/rooms/reliquary_path.tscn"),
	"blackbrick_court": preload("res://scenes/rooms/blackbrick_court.tscn"),
	"ashen_causeway": preload("res://scenes/rooms/ashen_causeway.tscn"),
	"ashglass_vault": preload("res://scenes/rooms/ashglass_vault.tscn"),
	"bellwether_court": preload("res://scenes/rooms/bellwether_court.tscn"),
	"candle_reliquary": preload("res://scenes/rooms/candle_reliquary.tscn"),
	"chapel": preload("res://scenes/rooms/chapel.tscn"),
	"cloister": preload("res://scenes/rooms/cloister.tscn"),
	"sanctum": preload("res://scenes/rooms/sanctum.tscn"),
	"lily_pond": preload("res://scenes/rooms/lily_pond.tscn"),
	"glasshouse": preload("res://scenes/rooms/glasshouse.tscn"),
	"observatory": preload("res://scenes/rooms/observatory.tscn")
}
const SWORD_LOOT_TABLE = [
	preload("res://items/dusk_needle.tres"),
	preload("res://items/thornwake_sabre.tres"),
	preload("res://items/vesper_rapier.tres"),
	preload("res://items/mourning_longsword.tres"),
	preload("res://items/bloodrose_falchion.tres"),
	preload("res://items/moonveil_grandblade.tres"),
	preload("res://items/rose_reaper_scythe.tres"),
	preload("res://items/lunar_vigil_halberd.tres"),
	preload("res://items/roseglass_dagger_v169.tres"),
	preload("res://items/moonwarden_spear_v169.tres"),
	preload("res://items/gravebell_maul_v170.tres"),
	preload("res://items/ashglass_warmaul_v170.tres"),
	preload("res://items/eclipse_twinblade_v170.tres"),
	preload("res://items/rosemirror_twinblade_v170.tres"),
	preload("res://items/nocturne_stiletto_v171.tres"),
	preload("res://items/briarwake_trident_v171.tres"),
	preload("res://items/moonlace_dual_daggers_v173.tres"),
	preload("res://items/gloamrose_dual_swords_v174.tres")
]
const BOW_LOOT_TABLE = [
	preload("res://items/thornrose_bow.tres"),
	preload("res://items/moonveil_bow.tres")
]
const MOON_SPELL_SCENE: PackedScene = preload("res://scenes/moon_spell.tscn")
const WAND_RELEASE_SCRIPT_V156: Script = preload("res://scripts/wand_release_fx_v156.gd")
const MOONFALL_SCENE: PackedScene = preload("res://scenes/moonfall_blizzard.tscn")
const ASTRAL_SCENE: PackedScene = preload("res://scenes/astral_rain_v127.tscn")
const ROSES_SCENE: PackedScene = preload("res://scenes/grasping_roses_v127.tscn")
const WORLD_DROP_SCENE: PackedScene = preload("res://scenes/world_drop.tscn")
const WORLD_SAVE_FILE: String = "user://ghost_girl_world_v1.json"
const GROUND_SAVE_FILE: String = "user://ghost_girl_ground_loot_v1.json"
const ROOM_TITLES = {
	"moonwake_crypt": "MOONWAKE CRYPT",
	"hollow_veil_moor": "HOLLOW VEIL MOOR",
	"garden": "THE WAKING GARDEN",
	"crypt_gallery": "THE MEMORIAL GALLERY",
	"garden_bridge": "THE BROKEN ROSE BRIDGE",
	"garden_arbor": "THE ROSE ARBOR",
	"moonthorn_woods": "MOONTHORN WOODS",
	"weeping_brook": "WEEPING BROOK",
	"briar_hollow": "BRIAR HOLLOW CROSSROADS",
	"reliquary_path": "FORGOTTEN RELIQUARY PATH",
	"blackbrick_court": "BLACKBRICK COURT",
	"ashen_causeway": "ASHEN CAUSEWAY",
	"ashglass_vault": "ASHGLASS VAULT",
	"bellwether_court": "BELLWETHER COURT",
	"candle_reliquary": "THE CANDLE RELIQUARY",
	"chapel": "CHAPEL OF SOFT ECHOES",
	"cloister": "THE WHISPERING CLOISTER",
	"sanctum": "THE MOONLIT SANCTUM",
	"lily_pond": "LILY MIRROR POOL",
	"glasshouse": "GLASSHOUSE OF WISHES",
	"observatory": "THE STARFALL OBSERVATORY"
}
const V132_VIGIL_IDS: Array[String] = ["v132_vigil_willow", "v132_vigil_graves", "v132_vigil_fen", "v132_vigil_ruins"]
const BELL_ORDER = ["bell_west", "bell_center", "bell_east"]
const FLOWER_ORDER = ["blossom_rose", "blossom_lily", "blossom_iris"]
const MIRROR_IDS = ["mirror_west", "mirror_north", "mirror_east"]
const MIRROR_ANSWERS = [2, 0, 3]

@onready var player = $GhostGirl
@onready var ui = $HUD
@onready var room_view: Node2D = $Room
@onready var reticle = $MouseThrowAim
@onready var inventory = $Inventory

var room: String = "moonwake_crypt"
var ground_records: Array[Dictionary] = []
var portals: Dictionary = {}
var puzzle_tokens: Dictionary = {}
var plates: Dictionary = {}
var weights: Dictionary = {}
var memories: Dictionary = {}
var beam: Node2D
var removed_room_items: Array[Node] = []
var current_target: Node2D
var garden_key_used: bool = false
var bells_solved: bool = false
var cloister_solved: bool = false
var found_last_memory: bool = false
var pond_solved: bool = false
var flowers_solved: bool = false
var mirrors_solved: bool = false
var final_star_seen: bool = false
var bell_progress: int = 0
var flower_progress: int = 0
# The first activated lantern shrine is used for in-session recovery.
var last_shrine_room: String = "moonwake_crypt"
var last_shrine_point: Vector2 = Vector2.ZERO

func _ready() -> void:
	player.world = self
	reticle.player = player
	ui.bind_inventory(inventory)
	_grant_v14_first_sword()
	player.get_node("EquipmentVisuals").bind_inventory(inventory)
	player.get_node("Ghost/WeaponLayers").bind_inventory(inventory)
	player.get_node("Ghost/BowPaletteV139").bind_inventory(inventory)
	# v1.52: editor-visible FX node guarantees a single initialized overlay.
	# Do not dynamically spawn a second invisible or unbound glow.
	var prestige: Node2D = player.get_node_or_null("Ghost/EquippedPrestigeFX") as Node2D
	if prestige != null:
		prestige.call("bind_inventory", inventory)
	# Subtle idle aether near the wand is item-seeded, not an inventory icon.
	var wand_glimmer: Node2D = Node2D.new()
	wand_glimmer.set_script(preload("res://scripts/wand_idle_glimmer.gd"))
	player.hand.add_child(wand_glimmer)
	wand_glimmer.call("bind_inventory", inventory)
	inventory.equipment_changed.connect(_on_equipment_changed)
	_restore_world_progress()
	_load_ground_records()
	_bind_room()
	_spawn_saved_ground_records()
	_update_camera_limits()
	ui.set_dew(player.dew_charges, player.MAX_DEW)


# Give one starter blade to both new and migrated saves; leave it unequipped
# so the repaired unarmed animation can be tested immediately.
func _grant_v14_first_sword() -> void:
	if inventory.has_collected("v14_starter_blade"):
		return
	if not inventory.has_item("dusk_needle"):
		var first_blade: GhostItemInstance = inventory.add_loot(SWORD_LOOT_TABLE[0] as GhostItemData, 140014, "normal")
		if first_blade == null:
			return  # Inventory full: retry next load, never delete existing gear.
	inventory.collected_pickups["v14_starter_blade"] = true
	inventory.save_game()
	ui.show_pickup("DUSK NEEDLE · open I / C to equip", Color("ead38c"))

func _roll_sword_drop(original: GhostItemData, seed_value: int) -> GhostItemData:
	if original == null or original.unique or original.item_class != "equipment":
		return original
	# A small independent share of new monster drops can be bows.
	# Existing saved item instances remain untouched.
	if posmod(seed_value, 23) == 0:
		return BOW_LOOT_TABLE[posmod(int(seed_value / 23), BOW_LOOT_TABLE.size())] as GhostItemData
	# One in seven ordinary monster drops becomes a sword, deterministic by seed.
	if posmod(seed_value, 7) != 0:
		return original
	var picked: int = posmod(int(seed_value / 7), SWORD_LOOT_TABLE.size())
	return SWORD_LOOT_TABLE[picked] as GhostItemData

func _on_equipment_changed() -> void:
	# Vitality rolls change maximum HP, never allow health to exceed the new cap.
	player.health = minf(player.health, player.maximum_health())
	ui.set_health(player.health, player.maximum_health())

func _bind_room() -> void:
	# Clear temporary challenge statuses when reloading, changing or resting in a room.
	ui.set_echo_trial_progress(false)
	ui.set_rose_run_progress(false)
	portals.clear()
	puzzle_tokens.clear()
	plates.clear()
	weights.clear()
	memories.clear()
	if room_view.has_node("Gameplay/V127SpellReliquaries"):
		for shrine in room_view.get_node("Gameplay/V127SpellReliquaries").get_children():
			if shrine.has_method("restore_from_inventory"):
				shrine.call("restore_from_inventory", inventory)
	if room_view.has_node("Gameplay/MoonfallReliquary"):
		room_view.get_node("Gameplay/MoonfallReliquary").call("restore_from_inventory", inventory)
	if room_view.has_node("Gameplay/CollectionExhibition"):
		for display in room_view.get_node("Gameplay/CollectionExhibition").get_children():
			display.call("bind_inventory", inventory)
	if room_view.has_node("Gameplay/WeaponShowcases"):
		# v1.72.2: nested floor-armory pickups must be restored too.
		for rack in room_view.get_node("Gameplay/WeaponShowcases").find_children("*", "Node2D", true, false):
			if rack.has_method("restore_from_inventory"):
				rack.call("restore_from_inventory", inventory)
	if room_view.has_node("Gameplay/V138FletcherShowcase"):
		for rack in room_view.get_node("Gameplay/V138FletcherShowcase").get_children():
			if rack.has_method("restore_from_inventory"):
				rack.call("restore_from_inventory", inventory)
	if room_view.has_node("Gameplay/Collectibles"):
		for pickup in room_view.get_node("Gameplay/Collectibles").get_children():
			var data: Resource = pickup.get("item_data") as Resource
			if data != null and (inventory.has_collected(str(pickup.get("pickup_id"))) or (bool(data.get("unique")) and inventory.has_item(str(data.get("item_id"))))):
				pickup.remove_from_group("interactable")
				pickup.hide()
				pickup.queue_free()
	if room_view.has_node("Gameplay/TreasureChests"):
		for chest in room_view.get_node("Gameplay/TreasureChests").get_children():
			var chest_id: String = str(chest.get("chest_id"))
			if inventory.has_collected(chest_id):
				chest.set("opened", true)
				chest.remove_from_group("interactable")
	# v1.32 Moor Vigil: restore editor-placed memorials, boss altar and
	# cosmetic attunement after chest state is restored.
	for container_path in ["Gameplay/V132Vigil", "Gameplay/V132Attunements", "Gameplay/V134VesperVigil"]:
		var container: Node = room_view.get_node_or_null(container_path)
		if container != null:
			for prop in container.get_children():
				if prop.has_method("restore_from_inventory"):
					prop.call("restore_from_inventory", inventory)
	# v1.35 falling-world supports and salvage seals restore after chests.
	# Supports go first so reward seals read their final persisted states.
	var falling_world: Node = room_view.get_node_or_null("Gameplay/V135FallingWorld")
	if falling_world != null:
		for prop in falling_world.get_children():
			if prop.has_method("restore_from_inventory"):
				prop.call("restore_from_inventory", inventory)
	# v1.46.4: early authored hook supports use the same persistent
	# collected-pickup flags as existing collapse sites.
	var early_puzzles: Node = room_view.get_node_or_null("Gameplay/V1464EarlyPuzzles")
	if early_puzzles != null:
		for prop in early_puzzles.get_children():
			if prop.has_method("restore_from_inventory"):
				prop.call("restore_from_inventory", inventory)
	# v1.48: bridge Rose Path restores the one-time coffer before players can interact.
	var rose_path: Node = room_view.get_node_or_null("Gameplay/V148RoseRun")
	if rose_path != null and rose_path.has_method("restore_from_inventory"):
		rose_path.call("restore_from_inventory", inventory)
	# v1.47: optional echo trials and the ordered Gallery chimes restore
	# after ordinary chests. Old saves need no migration or new world schema.
	var early_trials: Node = room_view.get_node_or_null("Gameplay/V147Trials")
	if early_trials != null:
		for trial in early_trials.get_children():
			if trial.has_method("restore_from_inventory"):
				trial.call("restore_from_inventory", inventory)
	var rose_relay: Node = room_view.get_node_or_null("Gameplay/V147RoseRelay")
	if rose_relay != null and rose_relay.has_method("restore_from_inventory"):
		rose_relay.call("restore_from_inventory", inventory)
	# v1.37 Bellroot Chorus: restore each bell's distinct interaction methods
	# before the optional reward seals read their progress.
	var bellroot: Node = room_view.get_node_or_null("Gameplay/V137Bellroots")
	if bellroot != null:
		for device in bellroot.get_children():
			if device.has_method("restore_from_inventory") and device.is_in_group("hook_switch"):
				device.call("restore_from_inventory", inventory)
		for device in bellroot.get_children():
			if device.has_method("restore_from_inventory") and device.is_in_group("v137_chorus_vault"):
				device.call("restore_from_inventory", inventory)
	# v1.38: restore all four elemental bow targets and the two reward
	# seals before the player can interact with their linked chests.
	var bow_riddles: Node = room_view.get_node_or_null("Gameplay/V138BowRiddles")
	if bow_riddles != null:
		for mark in bow_riddles.get_children():
			if mark.has_method("restore_from_inventory"):
				mark.call("restore_from_inventory", inventory)
	# v1.39: restore environmental arrow objects after chest open-state is read.
	var elemental_world: Node = room_view.get_node_or_null("Gameplay/V139ElementalWorld")
	if elemental_world != null:
		for device in elemental_world.get_children():
			if device.has_method("restore_from_inventory"):
				device.call("restore_from_inventory", inventory)
	# v1.40: generic fire/light objects work in every room, not just moor
	# puzzle targets. Restore after chests so revealed rewards stay opened.
	var elemental_anywhere: Node = room_view.get_node_or_null("Gameplay/V140ElementalWorld")
	if elemental_anywhere != null:
		for prop in elemental_anywhere.get_children():
			if prop.has_method("restore_from_inventory"):
				prop.call("restore_from_inventory", inventory)
	# v1.46: restore Blackbrick Court's two optional Ashglass signals. Each
	# signal restores its gate and chest together from an existing save flag.
	var ashglass: Node = room_view.get_node_or_null("Gameplay/V146CourtSignals")
	if ashglass != null:
		for device in ashglass.get_children():
			if device.has_method("restore_from_inventory"):
				device.call("restore_from_inventory", inventory)
	# v1.44: persistent causeway openings and the light-hidden eastern cache.
	var causeways: Node = room_view.get_node_or_null("Gameplay/V144MoonrootCauseways")
	if causeways != null:
		for device in causeways.get_children():
			if device.has_method("restore_from_inventory"):
				device.call("restore_from_inventory", inventory)
	# v1.45: restore the two aftershock memories AFTER room chests and
	# v1.44 causeways, so revealed rewards remain consistent after a reload.
	var living_moor: Node = room_view.get_node_or_null("Gameplay/V145LivingMoor")
	if living_moor != null:
		for memory in living_moor.get_children():
			if memory.has_method("restore_from_inventory"):
				memory.call("restore_from_inventory", inventory)
	# v1.33 Bellglass Echoes: post-Warden discoveries remain independently
	# persistent. Restore the vault before the three echo nodes so any
	# completed relic can safely refresh its reward gate.
	var bellglass: Node = room_view.get_node_or_null("Gameplay/V133Afterglow")
	if bellglass != null:
		for prop in bellglass.get_children():
			if prop.has_method("restore_from_inventory"):
				prop.call("restore_from_inventory", inventory)
	# Reapply save-compatible spell relays before the player can open a chest.
	for group_path in ["Gameplay/V128BloomRelays", "Gameplay/V128BowTargets", "Gameplay/V131MoonshotBloom"]:
		var group_node: Node = room_view.get_node_or_null(group_path)
		if group_node != null:
			for device in group_node.get_children():
				if device.has_method("restore_secret"):
					device.call("restore_secret", inventory)
	if room_view.has_node("Gameplay/RestShrines"):
		for resting in room_view.get_node("Gameplay/RestShrines").get_children():
			resting.set("activated", room == last_shrine_room and resting.global_position.distance_to(last_shrine_point) < 20.0)
	if room_view.has_node("Gameplay/HookAnchors"):
		for rose in room_view.get_node("Gameplay/HookAnchors").get_children():
			if rose.has_method("restore_secret"):
				rose.call("restore_secret", inventory)
	for node in room_view.get_node("Gameplay/Portals").get_children():
		portals[node.name] = node
		node.set("opened", _portal_unlocked(str(node.get("destination"))))
	for node in room_view.get_node("Gameplay/PuzzlePieces").get_children():
		puzzle_tokens[node.name] = node
	for node in room_view.get_node("Gameplay/Plates").get_children():
		plates[node.name] = node
		if node.has_method("restore_secret"):
			node.call("restore_secret", inventory)
	for node in room_view.get_node("Gameplay/Carryables").get_children():
		weights[node.name] = node
	for node in room_view.get_node("Gameplay/Memories").get_children():
		memories[node.name] = node
	beam = room_view.get_node_or_null("Gameplay/Effects/LightPath") as Node2D
	if room == "cloister" and cloister_solved:
		plates["Seal"].activated = true
	if room == "lily_pond" and pond_solved:
		for item in plates.values():
			item.activated = true
	if room == "chapel" and bells_solved:
		for token_id in BELL_ORDER:
			puzzle_tokens[token_id].lit = true
	if room == "glasshouse" and flowers_solved:
		for token_id in FLOWER_ORDER:
			puzzle_tokens[token_id].lit = true
	if room == "observatory":
		if mirrors_solved:
			for i in range(3):
				puzzle_tokens[MIRROR_IDS[i]].orientation = MIRROR_ANSWERS[i]
		_update_beam(false)
	if room == "sanctum" and found_last_memory:
		memories["LostMemory"].awakened = true
	if room == "observatory" and final_star_seen:
		memories["FinalStar"].awakened = true
	ui.set_location(str(ROOM_TITLES.get(room, "")))
	refresh_vigil_hud()

func refresh_vigil_hud() -> void:
	if ui == null or not ui.has_method("set_vigil_status"):
		return
	var count: int = 0
	for memory_id in V132_VIGIL_IDS:
		if inventory.has_collected(memory_id):
			count += 1
	ui.call("set_vigil_status", room == "hollow_veil_moor", count, inventory.has_collected("v132_moor_warden_defeated"))
	if ui.has_method("set_bellglass_status"):
		var echo_count: int = 0
		for echo_id in ["v133_bellglass_hook", "v133_bellglass_frost", "v133_bellglass_bow"]:
			if inventory.has_collected(echo_id):
				echo_count += 1
		ui.call("set_bellglass_status", room == "hollow_veil_moor", inventory.has_collected("v132_moor_warden_defeated"), echo_count)

func _portal_unlocked(destination: String) -> bool:
	match room:
		"moonwake_crypt": return true
		"garden": return garden_key_used if destination == "chapel" else true
		"chapel": return bells_solved if destination == "cloister" else true
		"cloister": return cloister_solved if destination == "sanctum" else true
		"sanctum": return found_last_memory if destination == "lily_pond" else true
		"lily_pond": return pond_solved if destination == "glasshouse" else true
		"glasshouse": return flowers_solved if destination == "observatory" else true
		_: return true

func _physics_process(_delta: float) -> void:
	if room == "cloister" and not cloister_solved:
		if _has_weight(plates["Seal"], weights.values()):
			cloister_solved = true
			_save_world_progress()
			plates["Seal"].activated = true
			portals["sanctum"].opened = true
	if room == "lily_pond" and not pond_solved:
		var both_active: bool = true
		for plate in plates.values():
			plate.activated = _has_weight(plate, weights.values())
			if not plate.activated:
				both_active = false
		if both_active:
			pond_solved = true
			_save_world_progress()
			portals["glasshouse"].opened = true

func _has_weight(plate: Node2D, candidates: Array) -> bool:
	for item in candidates:
		if is_instance_valid(item) and not item.held and item.z_height < 13.0:
			if item.global_position.distance_to(plate.global_position) < 46.0:
				return true
	return false

func _process(_delta: float) -> void:
	current_target = _choose_target()
	if current_target == null:
		var switch_hint: String = _rose_switch_hint()
		if switch_hint.is_empty() and player.carrying == null:
			switch_hint = _rose_weight_hint()
		ui.set_prompt("G  DROP    R  THROW" if player.carrying != null else switch_hint)
	elif current_target.is_in_group("moor_vigil_memory"):
		ui.set_prompt("E  AWAKEN MEMORIAL")
	elif current_target.is_in_group("moor_vigil_altar"):
		ui.set_prompt("E  CONSULT THE FOUR LAMENTS")
	elif current_target.is_in_group("v134_vesper_vigil"):
		ui.set_prompt("E  BEGIN VESPER VIGIL" if not bool(current_target.get("active")) else "HOLD THE VESPER CIRCLE")
	elif current_target.is_in_group("v134_story_slab"):
		ui.set_prompt("E  READ INSCRIPTION")
	elif current_target.is_in_group("v132_relic_attunement"):
		ui.set_prompt("E  ATTUNE EQUIPPED RARE RELIC")
	elif current_target.is_in_group("world_loot"):
		ui.set_prompt("E  COLLECT " + str(current_target.get("display_title")))
	elif current_target.is_in_group("v127_spell_reliquary"):
		var key_hint: String = str(current_target.get("key_hint"))
		ui.set_prompt("E  STUDY SPELL" if not bool(current_target.get("learned")) else key_hint + "  CAST (WITH WAND)")
	elif current_target.is_in_group("moonfall_shrine"):
		ui.set_prompt("E  STUDY MOONFALL" if not inventory.has_collected("v125_moonfall_unlocked") else "Z  MOONFALL (WITH WAND)")
	elif current_target.is_in_group("v148_rose_run"):
		ui.set_prompt(str(current_target.call("prompt_text")))
	elif current_target.is_in_group("v147_echo_trial"):
		ui.set_prompt(str(current_target.call("prompt_text")))
	elif current_target.is_in_group("rest_shrine"):
		ui.set_prompt("E  REST")
	elif current_target.is_in_group("moor_waystone"):
		ui.set_prompt("E  READ WAYSTONE")
	elif current_target.is_in_group("weapon_rack"):
		var showcase_item: GhostItemData = current_target.get("item_data") as GhostItemData
		ui.set_prompt("E  TAKE " + showcase_item.display_name.to_upper() if showcase_item != null else "E  INSPECT")
	elif current_target.is_in_group("treasure_chest"):
		ui.set_prompt("E  OPEN")
	elif current_target.is_in_group("collectible"):
		ui.set_prompt("E  TAKE")
	elif current_target.is_in_group("carryable"):
		ui.set_prompt("E  PICK UP  ·  Q  PULL" if player.carrying == null else "")
	elif current_target.is_in_group("room_portal"):
		if current_target.is_in_group("v1464_floor_breach"):
			ui.set_prompt("E  DESCEND")
		elif room == "garden" and str(current_target.get("destination")) == "chapel" and not garden_key_used:
			ui.set_prompt("E  USE KEY" if inventory.has_item("moon_rose_key") else "")
		else:
			ui.set_prompt("E  ENTER" if bool(current_target.get("opened")) else "")
	elif current_target.is_in_group("v182_exhibition"):
		ui.set_prompt("E  INSPECT DISPLAY")
	elif current_target.is_in_group("interactable"):
		ui.set_prompt("E  INTERACT")
	else:
		ui.set_prompt("")
	ui.set_carrying(player.carrying != null)

# Contextual hint only when aiming at a live rose-seal switch; never add
# permanent HUD clutter during exploration or combat.
func _rose_switch_hint() -> String:
	if player == null or player.rose_hook == null or ui.is_menu_open():
		return ""
	var origin: Vector2 = player.hand.global_position
	var pointer: Vector2 = player.get_global_mouse_position() - origin
	if pointer.length_squared() < 40.0:
		return ""
	for node in get_tree().get_nodes_in_group("hook_switch"):
		if not is_instance_valid(node) or not (node is Node2D) or node.get("activated") == true:
			continue
		var target: Node2D = node as Node2D
		var delta_to: Vector2 = target.global_position - origin
		if delta_to.length() < player.rose_hook._effective_range() and delta_to.length() > 45.0 and delta_to.normalized().dot(pointer.normalized()) > 0.94:
			return str(node.call("hook_prompt")) if node.has_method("hook_prompt") else "F  RELEASE ROSE SEAL"
	return ""

# Only show the tutorial hint near an unsolved, authored physical weight plate.
# Carryable targeting retains priority so E always names the actual crate.
func _rose_weight_hint() -> String:
	for plate in get_tree().get_nodes_in_group("rose_weight_plate"):
		if not is_instance_valid(plate) or not plate is Node2D or bool(plate.get("activated")):
			continue
		if player.global_position.distance_to(plate.global_position) < 225.0:
			return "Q  PULL OBJECT  ·  E  LIFT  ·  G  DROP ON ROSE"
	return ""

func _choose_target():
	var best: Node2D = null
	var distance_best: float = INF
	for item in get_tree().get_nodes_in_group("interactable"):
		if not is_instance_valid(item) or item.is_queued_for_deletion():
			continue
		if not item is Node2D:
			continue
		if item.is_in_group("carryable") and bool(item.get("held")):
			continue
		var spatial: Node2D = item as Node2D
		var delta_to: Vector2 = spatial.global_position - player.global_position
		var distance: float = delta_to.length()
		if distance > 115.0 or distance < 0.1:
			continue
		if delta_to.normalized().dot(player.facing) < (0.0 if distance < 46.0 else 0.32):
			continue
		if distance < distance_best:
			distance_best = distance
			best = spatial
	return best

func interact() -> void:
	var target = _choose_target()
	if target == null:
		return
	if target.is_in_group("v182_exhibition"):
		var displayed: GhostItemInstance = target.call("get_displayed_item") as GhostItemInstance
		ui.call("open_exhibition", int(target.get("slot")), displayed)
		return
	if target.is_in_group("moor_vigil_memory"):
		if target.call("awaken", inventory):
			ui.show_pickup("LAMENT AWAKENED · " + str(target.get("memory_title")), Color("e7c6e7"))
			var vigil_altar: Node = room_view.get_node_or_null("Gameplay/V132Vigil/V132WardenAltar")
			if vigil_altar != null and vigil_altar.has_method("refresh_progress"):
				vigil_altar.call("refresh_progress")
			refresh_vigil_hud()
		return
	if target.is_in_group("moor_vigil_altar"):
		ui.show_pickup(str(target.call("try_awaken")), Color("edd5ad"))
		refresh_vigil_hud()
		return
	if target.is_in_group("v134_vesper_vigil"):
		ui.show_pickup(str(target.call("try_begin")), Color("e5cce8"))
		return
	if target.is_in_group("v134_story_slab"):
		ui.show_pickup(str(target.get("slab_title")) + " · " + str(target.get("inscription")), Color("d4c6e0"))
		return
	if target.is_in_group("v132_relic_attunement"):
		ui.show_pickup(str(target.call("try_attune", inventory)), Color("d7bae9"))
		return
	if target.is_in_group("v127_spell_reliquary"):
		var key: String = str(target.get("unlock_id"))
		if not inventory.has_collected(key):
			inventory.collected_pickups[key] = true
			inventory.save_game()
			target.call("restore_from_inventory", inventory)
			ui.show_pickup("SPELL LEARNED  ·  EQUIP WAND  ·  " + str(target.get("key_hint")) + " TO CAST", Color("ddb8ee"))
		else:
			ui.show_pickup("SPELL ALREADY LEARNED", Color("ddb8ee"))
		return
	if target.is_in_group("moonfall_shrine"):
		if not inventory.has_collected("v125_moonfall_unlocked"):
			inventory.collected_pickups["v125_moonfall_unlocked"] = true
			inventory.save_game()
			target.call("restore_from_inventory", inventory)
			ui.show_pickup("MOONFALL LEARNED  ·  EQUIP WAND  ·  Z TO CAST", Color("b9d9ff"))
		else:
			ui.show_pickup("MOONFALL  ·  Z  ·  37 STAMINA  ·  6.2s RECHARGE", Color("b9d9ff"))
		return
	if target.is_in_group("v148_rose_run"):
		var rose_reply: String = str(target.call("interact"))
		if not rose_reply.is_empty():
			ui.show_pickup(rose_reply, Color("ead1ee"))
		return
	if target.is_in_group("v147_echo_trial"):
		var reply: String = str(target.call("interact"))
		if not reply.is_empty():
			ui.show_pickup(reply, Color("e6c5e1"))
		return
	if target.is_in_group("rest_shrine"):
		_activate_shrine(target)
		return
	if target.is_in_group("moor_waystone"):
		ui.show_pickup(str(target.get("region_title")) + "  ·  " + str(target.get("route_hint")), Color("ddc1d8"))
		return
	if target.is_in_group("world_loot"):
		var original: GhostItemInstance = target.get("dropped_instance") as GhostItemInstance
		var found: GhostItemInstance = inventory.add_existing_item(original) if original != null else inventory.add_loot(target.get("item_data") as GhostItemData, int(target.get("loot_seed")), "" if str(target.get("guaranteed_quality")) == "random" else str(target.get("guaranteed_quality")))
		if found != null:
			var saved_drop_id: String = str(target.get("persistent_drop_id"))
			if not saved_drop_id.is_empty():
				_forget_ground_record(saved_drop_id)
			ui.show_pickup("%s · %s" % [found.quality.to_upper(), found.display_name()], found.quality_color())
			target.remove_from_group("interactable")
			target.queue_free()
		else:
			ui.show_pickup("BACKPACK FULL")
		return
	if target.is_in_group("weapon_rack"):
		var id: String = str(target.get("pickup_id"))
		if id.is_empty() or inventory.has_collected(id):
			return
		var template: GhostItemData = target.get("item_data") as GhostItemData
		var acquired: GhostItemInstance = inventory.add_loot(template, int(target.get("item_seed")), str(target.get("guaranteed_quality")))
		if acquired == null:
			ui.show_pickup("BACKPACK FULL")
			return
		inventory.collected_pickups[id] = true
		inventory.save_game()
		target.call("restore_from_inventory", inventory)
		ui.show_pickup(("ARMORY FIND · " if bool(target.get("ground_display")) else "RELIC SHOWCASE · ") + acquired.display_name(), acquired.quality_color())
		return
	if target.is_in_group("treasure_chest"):
		var chest_id: String = str(target.get("chest_id"))
		if not inventory.has_collected(chest_id):
			var forced: String = str(target.get("guaranteed_quality"))
			var data: GhostItemData = target.get("loot_data") as GhostItemData
			var rolled: GhostItemInstance = inventory.add_loot(data, int(target.get("loot_seed")), "" if forced == "random" else forced)
			if rolled != null:
				inventory.collected_pickups[chest_id] = true
				inventory.save_game()
				target.set("opened", true)
				target.remove_from_group("interactable")
				ui.show_pickup("%s  ·  %s" % [rolled.quality.to_upper(), rolled.display_name()], rolled.quality_color())
			else:
				ui.show_pickup("BACKPACK FULL")
		return
	if target.is_in_group("collectible"):
		var data: Resource = target.get("item_data") as Resource
		var found: GhostItemInstance = inventory.add_pickup(data as GhostItemData, str(target.get("pickup_id")), int(target.get("item_seed")))
		if found != null:
			ui.show_pickup(found.display_name())
			target.queue_free()
		else:
			ui.show_pickup("INVENTORY FULL")
		return
	if target.is_in_group("carryable"):
		if player.carrying == null:
			player.carrying = target
			target.pick_up(player.hand)
		return
	if target.is_in_group("room_portal"):
		var destination: String = str(target.get("destination"))
		if room == "garden" and destination == "chapel" and not garden_key_used:
			if inventory.has_item("moon_rose_key"):
				garden_key_used = true
				_save_world_progress()
				target.set("opened", true)
				ui.show_pickup("THE CHAPEL GATE IS OPEN")
			return
		if bool(target.get("opened")):
			_enter_room(destination)
		return
	if puzzle_tokens.has(target.name):
		_touch_puzzle_piece(str(target.name))
		return
	if memories.has(target.name):
		_touch_memory(str(target.name))

func _touch_puzzle_piece(id: String) -> void:
	if id.begins_with("bell_"):
		if bells_solved:
			return
		if id == BELL_ORDER[bell_progress]:
			puzzle_tokens[id].lit = true
			bell_progress += 1
			if bell_progress == BELL_ORDER.size():
				bells_solved = true
				_save_world_progress()
				portals["cloister"].opened = true
		else:
			bell_progress = 0
			for token_id in BELL_ORDER:
				puzzle_tokens[token_id].lit = false
		return
	if id.begins_with("blossom_"):
		if flowers_solved:
			return
		if id == FLOWER_ORDER[flower_progress]:
			puzzle_tokens[id].lit = true
			flower_progress += 1
			if flower_progress == FLOWER_ORDER.size():
				flowers_solved = true
				_save_world_progress()
				portals["observatory"].opened = true
				# Restoring flowers is an emotional story moment, not a generic action.
				ui.set_expression("smiling", 2.5)
		else:
			flower_progress = 0
			for token_id in FLOWER_ORDER:
				puzzle_tokens[token_id].lit = false
		return
	if id.begins_with("mirror_") and not mirrors_solved:
		puzzle_tokens[id].orientation = (int(puzzle_tokens[id].orientation) + 1) % 4
		_update_beam(true)

func _update_beam(allow_solve: bool) -> void:
	if beam == null:
		return
	var segments: int = 1
	for i in range(3):
		var piece = puzzle_tokens[MIRROR_IDS[i]]
		var aligned: bool = int(piece.orientation) == MIRROR_ANSWERS[i]
		piece.lit = aligned
		if aligned and segments == i + 1:
			segments += 1
	beam.set("segments_lit", segments)
	if allow_solve and segments == 4:
		mirrors_solved = true
		_save_world_progress()

func _touch_memory(id: String) -> void:
	if id == "LostMemory" and not found_last_memory:
		found_last_memory = true
		_save_world_progress()
		memories[id].awakened = true
		portals["lily_pond"].opened = true
		ui.set_expression("crying", 3.8)
	if id == "FinalStar" and mirrors_solved and not final_star_seen:
		final_star_seen = true
		_save_world_progress()
		memories[id].awakened = true
		ui.set_expression("smiling", 5.0)

func _enter_room(next_room: String) -> void:
	if not ROOMS.has(next_room):
		return
	var previous_room: String = room
	if player.carrying != null:
		var held_item = player.carrying
		player.carrying = null
		held_item.queue_free()
	for item in removed_room_items:
		if is_instance_valid(item):
			item.queue_free()
	removed_room_items.clear()
	player.clear_lock_target()
	# Cancel active hooks before freeing the old room's target nodes.
	player.rose_hook.cancel_hook()
	# Removing the old room immediately also removes its groups from targeting.
	remove_child(room_view)
	room_view.queue_free()
	var packed: PackedScene = ROOMS[next_room] as PackedScene
	room_view = packed.instantiate() as Node2D
	room_view.name = "Room"
	add_child(room_view)
	move_child(room_view, 0)
	room = next_room
	player.velocity = Vector2.ZERO
	var spawn: Marker2D = room_view.get_node_or_null("SpawnPoints/From_" + previous_room) as Marker2D
	if spawn == null:
		spawn = room_view.get_node("SpawnPoints/Default") as Marker2D
	player.global_position = spawn.global_position
	player.set_facing(Vector2.UP)
	player.reset_action_state()
	_bind_room()
	_spawn_saved_ground_records()
	_update_camera_limits()

func _update_camera_limits() -> void:
	var painted: Sprite2D = room_view.get_node("PaintedRoom") as Sprite2D
	var dimensions: Vector2 = painted.texture.get_size() if painted.texture != null else Vector2(2389, 1792)
	# Additional walkable art in the original room extends the camera limits.
	var armory_wing: Node = room_view.get_node_or_null("ArmoryWingV172")
	if armory_wing != null:
		dimensions.x = maxf(dimensions.x, float(armory_wing.get("room_right_edge")))
	var camera: Camera2D = player.get_node("Camera2D") as Camera2D
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = roundi(dimensions.x)
	camera.limit_bottom = roundi(dimensions.y)

func get_throw_direction() -> Vector2:
	if OS.has_feature("mobile"):
		return player.facing
	var target: Vector2 = get_global_mouse_position() - player.global_position
	return player.facing if target.length_squared() < 400.0 else target.normalized()

func drop_held(should_throw: bool, aimed_direction: Vector2 = Vector2.ZERO) -> void:
	if player.carrying == null:
		return
	var item = player.carrying
	player.carrying = null
	var direction: Vector2 = aimed_direction.normalized() if should_throw and aimed_direction.length_squared() > 0.001 else player.facing
	var landing_pos: Vector2 = player.global_position + direction * (66.0 if should_throw else 57.0)
	item.release_to(self, landing_pos, direction, should_throw, player)
	removed_room_items.append(item)

func cast_spell(direction: Vector2, charged: bool = false) -> void:
	if inventory.get_equipped("wand") == null:
		return
	var bolt = MOON_SPELL_SCENE.instantiate()
	add_child(bolt)
	removed_room_items.append(bolt)
	var aim: Vector2 = direction.normalized() if direction.length_squared() > 0.001 else player.facing
	bolt.global_position = player.global_position + Vector2(0, -44) + aim * 29.0
	var intended: Vector2 = player.spell_aim_point
	bolt.direction = (intended - bolt.global_position).normalized() if intended.distance_squared_to(bolt.global_position) > 25.0 else aim
	bolt.owner_rid = player.get_rid()
	bolt.caster = player
	bolt.damage = (35.0 if charged else 14.0) * (1.0 + inventory.get_stat_total("spell_power_pct") / 100.0)
	if charged:
		bolt.damage *= 1.0 + inventory.get_stat_total("charged_spell_pct") / 100.0
	bolt.charged = charged
	bolt.speed = 530.0 if charged else 770.0
	# The wand's saved cosmetic affix determines form, colour, and motif.
	# This is one gameplay projectile even for twin/triple wisps or beams.
	var wand: GhostItemInstance = inventory.get_equipped("wand")
	if wand != null:
		var appearance: Dictionary = wand.effect_rolls()
		bolt.effect_motif = int(appearance["motif"])
		# Cosmetic colour is entirely independent from damage/loot rolls.
		# Each saved 128-bit appearance reproduces its own full-spectrum palette.
		var wand_gradient: Array[Color] = wand.glow_gradient_colors()
		bolt.effect_color = wand_gradient[0]
		bolt.accent_color = wand_gradient[1]
		bolt.gradient_c = wand_gradient[2]
		bolt.rare_signature = wand.visual_signature()
		bolt.mythic_layer_variant = wand.mythic_layer_variant()
		bolt.trail_style = int(appearance["trail"])
		bolt.effect_tier = int(appearance["tier"])
		bolt.impact_style = int(appearance["impact"])
		bolt.spell_form = int(appearance["form"])
		bolt.effect_seed = wand.visual_seed()
		# One purely visual release flash at the projectile origin. No hitbox.
		var release_fx: Node2D = Node2D.new()
		release_fx.set_script(WAND_RELEASE_SCRIPT_V156)
		add_child(release_fx)
		release_fx.global_position = bolt.global_position
		release_fx.call("configure", wand_gradient[0], wand_gradient[1], wand_gradient[2], wand.visual_seed(), charged, wand.visual_signature(), wand.mythic_layer_variant())

func cast_moonfall(target_position: Vector2) -> void:
	var wand: GhostItemInstance = inventory.get_equipped("wand")
	if wand == null or not inventory.has_collected("v125_moonfall_unlocked"):
		return
	# Target is intentionally cursor/lock-aimed, with line of sight checked so
	# players cannot conjure frost through stone or destructible cover.
	var start: Vector2 = player.global_position + Vector2(0.0, -28.0)
	var offset: Vector2 = target_position - start
	var point: Vector2 = start + offset.limit_length(570.0)
	var space: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var trace: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(start, point)
	trace.collision_mask = 6
	trace.exclude = [player.get_rid()]
	var obstruction: Dictionary = space.intersect_ray(trace)
	if not obstruction.is_empty():
		point = obstruction.get("position", point)
	var storm: Node2D = MOONFALL_SCENE.instantiate() as Node2D
	storm.set("appearance_seed", wand.visual_seed())
	storm.set("damage_per_pulse", 7.8 * (1.0 + inventory.get_stat_total("spell_power_pct") / 100.0))
	storm.set("style_index", GhostWeaponFXLibrary.moonfall_style(wand.visual_seed(), wand.quality))
	var signature: Dictionary = wand.effect_rolls()
	storm.set("main_color", GhostWeaponFXLibrary.color(int(signature["color"])).lerp(Color("b9dfff"), 0.58))
	storm.set("accent_color", GhostWeaponFXLibrary.color(int(signature["accent"])).lerp(Color("e3f5ff"), 0.33))
	add_child(storm)
	removed_room_items.append(storm)
	storm.global_position = point

func _v127_aimed_area_point(target_position: Vector2) -> Vector2:
	# The target cannot be summoned through masonry or movable cover.
	var start: Vector2 = player.global_position + Vector2(0.0, -28.0)
	var endpoint: Vector2 = start + (target_position - start).limit_length(590.0)
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(start, endpoint)
	query.collision_mask = 6
	query.exclude = [player.get_rid()]
	var wall: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
	return wall.get("position", endpoint) if not wall.is_empty() else endpoint

func _v127_spawn_area(scene: PackedScene, target_position: Vector2, is_astral: bool) -> void:
	var wand: GhostItemInstance = inventory.get_equipped("wand")
	if wand == null:
		return
	var effect: Node2D = scene.instantiate() as Node2D
	if effect == null:
		return
	var signature: Dictionary = wand.effect_rolls()
	effect.set("seed_value", wand.visual_seed())
	effect.set("rarity", GhostWeaponFXLibrary.tier(wand.quality))
	effect.set("primary", GhostWeaponFXLibrary.color(int(signature["color"])).lerp(Color("d6b9ed"), 0.48))
	effect.set("secondary", GhostWeaponFXLibrary.color(int(signature["accent"])).lerp(Color("efd1eb"), 0.38))
	if is_astral:
		effect.set("pulse_damage", 10.5 * (1.0 + inventory.get_stat_total("spell_power_pct") / 100.0))
	else:
		effect.set("one_hit_damage", 14.0 * (1.0 + inventory.get_stat_total("spell_power_pct") / 100.0))
	add_child(effect)
	removed_room_items.append(effect)
	effect.global_position = _v127_aimed_area_point(target_position)

func cast_astral_rain(target_position: Vector2) -> void:
	if inventory.has_collected("v127_astral_rain_unlocked"):
		_v127_spawn_area(ASTRAL_SCENE, target_position, true)

func cast_grasping_roses(target_position: Vector2) -> void:
	if inventory.has_collected("v127_grasping_roses_unlocked"):
		_v127_spawn_area(ROSES_SCENE, target_position, false)

func grant_enemy_loot(data: GhostItemData, seed_value: int, quality_choice: String) -> void:
	if data == null:
		return
	var quality: String = "" if quality_choice == "random" else quality_choice
	var reward: GhostItemInstance = inventory.add_loot(_roll_sword_drop(data, seed_value), seed_value, quality)
	if reward != null:
		ui.show_pickup("%s  ·  %s" % [reward.quality.to_upper(), reward.display_name()], reward.quality_color())
	else:
		ui.show_pickup("BACKPACK FULL")

func _give_weapon_test_samples() -> void:
	# Optional testing action; existing saves remain intact and no duplicates
	# are created. Real copies can also be found in the new world chests.
	var found: int = 0
	for path in ["res://items/rose_reaper_scythe.tres", "res://items/lunar_vigil_halberd.tres"]:
		var template: GhostItemData = load(path) as GhostItemData
		if template != null and not inventory.has_item(template.item_id):
			if inventory.add_loot(template, 160016 + found, "normal") != null:
				found += 1
	ui.show_pickup("WEAPON TRIAL · %d NEW ITEMS · OPEN I" % found)

# Explicit trial shortcut for the rare beam modifier. A matching rare wand
# also exists naturally behind the two rose seals in Hollow Veil Moor.
# Never alter existing equipment when granting the test copy.
func _give_luminous_lance_trial() -> void:
	if inventory.has_collected("v117_luminous_lance_trial"):
		ui.show_pickup("LUMINOUS LANCE TRIAL ALREADY CLAIMED · OPEN I")
		return
	var wand_template: GhostItemData = load("res://items/briar_wand.tres") as GhostItemData
	var trial: GhostItemInstance = inventory.add_loot(wand_template, 117171, "rare") if wand_template != null else null
	if trial == null:
		ui.show_pickup("BACKPACK FULL · MAKE ROOM FOR THE LANCE WAND")
		return
	inventory.collected_pickups["v117_luminous_lance_trial"] = true
	inventory.save_game()
	ui.show_pickup("LUMINOUS LANCE · RARE WAND · OPEN I TO EQUIP", Color("f5eacb"))

# Developer shortcut for immediate combat verification without walking through
# the whole adventure. This does not change the normal start location.
func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F3:
			_give_luminous_lance_trial()
		if event.physical_keycode == KEY_F6:
			_enter_room("hollow_veil_moor")
		elif event.physical_keycode == KEY_F7:
			_give_weapon_test_samples()
		elif event.physical_keycode == KEY_F9:
			_enter_room("blackbrick_court")
		elif event.physical_keycode == KEY_F10:
			_enter_room("candle_reliquary")
		elif event.physical_keycode == KEY_F11:
			_enter_room("ashen_causeway")
		elif event.physical_keycode == KEY_F12:
			_enter_room("ashglass_vault")
		elif event.physical_keycode == KEY_F8:
			_enter_room("bellwether_court")

func track_room_effect(effect: Node) -> void:
	removed_room_items.append(effect)

func spawn_world_loot(data: GhostItemData, seed_value: int, quality: String, point: Vector2) -> void:
	if data == null:
		return
	var drop: Node2D = WORLD_DROP_SCENE.instantiate() as Node2D
	drop.set("item_data", _roll_sword_drop(data, seed_value))
	drop.set("loot_seed", seed_value)
	drop.set("guaranteed_quality", quality)
	drop.global_position = point
	add_child(drop)
	removed_room_items.append(drop)

# Diablo-style cursor release. A reference to the exact generated item is
# transferred to the world, never rerolled or discarded on a failed placement.
func drop_inventory_item(index: int) -> bool:
	if not inventory.can_drop(index):
		ui.show_pickup("PROTECTED OR QUEST TREASURES CANNOT BE DROPPED")
		return false
	var item: GhostItemInstance = inventory.get_item(index)
	if item == null or item.definition == null or item.definition.resource_path.is_empty():
		return false
	var direction: Vector2 = player.get_global_mouse_position() - player.global_position
	if direction.length_squared() < 16.0:
		direction = player.facing * 60.0
	var point: Vector2 = player.global_position + direction.limit_length(85.0)
	var ground: Node2D = WORLD_DROP_SCENE.instantiate() as Node2D
	if ground == null:
		return false
	ground.set("item_data", item.definition)
	ground.set("loot_seed", item.item_seed)
	ground.set("guaranteed_quality", item.quality)
	ground.set("dropped_instance", item)
	var drop_id: String = "%d_%d" % [Time.get_ticks_usec(), randi()]
	ground.set("persistent_drop_id", drop_id)
	add_child(ground)
	ground.global_position = point
	var removed: GhostItemInstance = inventory.take_item_at(index)
	if removed == null:
		ground.queue_free()
		return false
	ground_records.append(_ground_record(removed, drop_id, room, point))
	_save_ground_records()
	removed_room_items.append(ground)
	ui.show_pickup("DROPPED · " + removed.display_name(), removed.quality_color())
	return true

func _ground_record(item: GhostItemInstance, key: String, room_name: String, point: Vector2) -> Dictionary:
	return {
		"id": key, "room": room_name,
		"resource": item.definition.resource_path, "seed": item.item_seed,
		"quality": item.quality, "socketed": item.socketed.duplicate(true),
		"x": point.x, "y": point.y
	}

func _save_ground_records() -> void:
	var output: FileAccess = FileAccess.open(GROUND_SAVE_FILE, FileAccess.WRITE)
	if output != null:
		output.store_string(JSON.stringify({"version": 1, "drops": ground_records}))

func _load_ground_records() -> void:
	ground_records.clear()
	if not FileAccess.file_exists(GROUND_SAVE_FILE):
		return
	var source: FileAccess = FileAccess.open(GROUND_SAVE_FILE, FileAccess.READ)
	if source == null:
		return
	var parsed: Variant = JSON.parse_string(source.get_as_text())
	if not (parsed is Dictionary):
		return
	var saved: Variant = parsed.get("drops", [])
	if not (saved is Array):
		return
	for data in saved:
		if data is Dictionary and str(data.get("resource", "")).begins_with("res://"):
			ground_records.append(data.duplicate(true))

func _spawn_saved_ground_records() -> void:
	for record in ground_records:
		if str(record.get("room", "")) != room:
			continue
		var res_path: String = str(record.get("resource", ""))
		if not ResourceLoader.exists(res_path):
			continue
		var data: GhostItemData = load(res_path) as GhostItemData
		if data == null:
			continue
		var item: GhostItemInstance = GhostItemGenerator.create(data, int(record.get("seed", 0)), str(record.get("quality", "normal")))
		for socket in record.get("socketed", []):
			if socket is Dictionary and item.socketed.size() < item.sockets:
				item.socketed.append(socket.duplicate(true))
		var ground: Node2D = WORLD_DROP_SCENE.instantiate() as Node2D
		if ground == null:
			continue
		ground.set("item_data", data)
		ground.set("dropped_instance", item)
		ground.set("persistent_drop_id", str(record.get("id", "")))
		add_child(ground)
		ground.global_position = Vector2(float(record.get("x", 0.0)), float(record.get("y", 0.0)))
		removed_room_items.append(ground)

func _forget_ground_record(key: String) -> void:
	for i in range(ground_records.size() - 1, -1, -1):
		if str(ground_records[i].get("id", "")) == key:
			ground_records.remove_at(i)
			_save_ground_records()
			return

# Resting is free and resets nearby enemies, mirroring deliberate checkpoint
# preparation in a forgiving prototype. Inventory and socket rolls are untouched.
func _activate_shrine(shrine: Node2D) -> void:
	last_shrine_room = room
	last_shrine_point = shrine.global_position
	_save_world_progress()
	shrine.set("activated", true)
	# Re-enter the same authored room: enemies respawn and loose ground drops
	# clear, while opened chests and discovered secrets remain saved.
	_enter_room(room)
	player.global_position = last_shrine_point + Vector2(0.0, 73.0)
	player.health = player.maximum_health()
	player.stamina = player.MAX_STAMINA
	player.dew_charges = player.MAX_DEW
	player.rally_pool = 0.0
	player.rally_time_left = 0.0
	player.clear_lock_target()
	ui.set_health(player.health, player.maximum_health())
	ui.set_stamina(player.stamina, player.MAX_STAMINA)
	ui.set_dew(player.dew_charges, player.MAX_DEW)
	ui.show_pickup("EMBER RESTORED")

func return_after_defeat() -> void:
	var place: String = last_shrine_room if ROOMS.has(last_shrine_room) else "moonwake_crypt"
	_enter_room(place)
	if last_shrine_point != Vector2.ZERO:
		player.global_position = last_shrine_point + Vector2(0.0, 74.0)
	player.health = player.maximum_health()
	player.stamina = player.MAX_STAMINA
	player.dew_charges = player.MAX_DEW
	player.invulnerable_time = 2.0
	player.healing_time_left = 0.0
	ui.set_health(player.health, player.maximum_health())
	ui.set_dew(player.dew_charges, player.MAX_DEW)
	ui.show_pickup("THE EMBER CALLS YOU BACK")

# Persistent world state is intentionally distinct from seeded inventory data.
# Loading a v0.4 character with no world file starts from the default story state.
func _save_world_progress() -> void:
	var data: Dictionary = {
		"version": 1,
		"garden_key_used": garden_key_used,
		"bells_solved": bells_solved,
		"cloister_solved": cloister_solved,
		"found_last_memory": found_last_memory,
		"pond_solved": pond_solved,
		"flowers_solved": flowers_solved,
		"mirrors_solved": mirrors_solved,
		"final_star_seen": final_star_seen,
		"last_shrine_room": last_shrine_room,
		"last_shrine_point": [last_shrine_point.x, last_shrine_point.y]
	}
	var file: FileAccess = FileAccess.open(WORLD_SAVE_FILE, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data))

func _restore_world_progress() -> void:
	if not FileAccess.file_exists(WORLD_SAVE_FILE):
		return
	var file: FileAccess = FileAccess.open(WORLD_SAVE_FILE, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	var saved: Dictionary = parsed as Dictionary
	garden_key_used = bool(saved.get("garden_key_used", false))
	bells_solved = bool(saved.get("bells_solved", false))
	cloister_solved = bool(saved.get("cloister_solved", false))
	found_last_memory = bool(saved.get("found_last_memory", false))
	pond_solved = bool(saved.get("pond_solved", false))
	flowers_solved = bool(saved.get("flowers_solved", false))
	mirrors_solved = bool(saved.get("mirrors_solved", false))
	final_star_seen = bool(saved.get("final_star_seen", false))
	var saved_room: String = str(saved.get("last_shrine_room", "moonwake_crypt"))
	last_shrine_room = saved_room if ROOMS.has(saved_room) else "moonwake_crypt"
	var coords: Variant = saved.get("last_shrine_point", [])
	if coords is Array and coords.size() >= 2:
		last_shrine_point = Vector2(float(coords[0]), float(coords[1]))
