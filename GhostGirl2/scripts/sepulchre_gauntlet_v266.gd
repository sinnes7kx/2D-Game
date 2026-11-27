extends Node2D
## Room-local repeatable descent. No saved live enemy nodes, no per-kill loot.
const WRAITH = preload("res://scenes/rose_wraith.tscn")
const HUNTER = preload("res://scenes/gothic_hunter.tscn")
const TITLES: Array[String] = ["The Ossuary","The Thorn Reliquary","The Crownless Sepulchre"]
const FIRST_REWARDS = [
	preload("res://items/nocturne_stiletto_v171.tres"),
	preload("res://items/moonwarden_spear_v169.tres"),
	preload("res://items/eclipse_twinblade_v170.tres")
]
const REPEAT_REWARDS = [
	preload("res://items/nocturne_stiletto_v171.tres"),
	preload("res://items/rose_reaper_scythe.tres"),
	preload("res://items/briarwake_trident_v171.tres"),
	preload("res://items/rosemirror_twinblade_v170.tres")
]
enum {WAITING, WARNING, BATTLE, CLEARED}
@export_range(1,3) var depth: int = 1
var phase: int = WAITING
var wave: int = 0
var warning: float = 0.0
var elapsed: float = 0.0
var enemies: Array[Node2D] = []
var reward_claimed: bool = false
var run_seed: int = 0
var hit_count: int = 0
var previous_health: float = -1.0
var hud_delay: float = 0.0

static func recipe(level: int, round_index: int) -> Array[String]:
	match clampi(round_index,1,3):
		1:
			match level:
				1: return ["wraith","wraith","mourner"]
				2: return ["wraith","blade_hunter","mourner","occultist"]
				_: return ["blade_hunter","mourner","occultist","wraith","wraith"]
		2:
			match level:
				1: return ["mourner","blade_hunter","wraith","wraith"]
				2: return ["warder","bell_keeper","blade_hunter","occultist"]
				_: return ["warder","bell_keeper","blade_hunter","occultist","mourner"]
		_:
			match level:
				1: return ["elite_warder","wraith"]
				2: return ["elite_bell_keeper","blade_hunter"]
				_: return ["elite_blade_hunter","occultist","warder"]

func _ready() -> void:
	add_to_group("interactable")
	add_to_group("sepulchre_v266")
	set_process(false)

func _game() -> Node:
	return get_tree().current_scene

func prompt_text() -> String:
	match phase:
		WAITING: return "E  AWAKEN THE SEPULCHRE"
		WARNING: return "THE BELLS AWAKEN"
		BATTLE: return "DEFEAT THE GUARDIANS"
		CLEARED: return "E  CLAIM DEPTH REWARD" if not reward_claimed else "DEPTH CLEARED · DESCEND OR RETURN"
	return ""

func interact() -> String:
	var game: Node = _game()
	if game == null:
		return ""
	if phase == CLEARED:
		return _claim_reward(game)
	if phase != WAITING:
		return ""
	run_seed = randi_range(100000,2147000000)
	wave = 0
	elapsed = 0.0
	hit_count = 0
	previous_health = float(game.player.health)
	phase = WARNING
	warning = 1.75
	set_process(true)
	queue_redraw()
	return "DEPTH %d · THREE WAVES" % depth

func _process(delta: float) -> void:
	var game: Node = _game()
	if game == null or game.ui.is_menu_open():
		return
	if phase == WARNING or phase == BATTLE:
		elapsed += delta
		var hp: float = float(game.player.health)
		if previous_health >= 0.0 and hp < previous_health-0.1:
			hit_count += 1
		previous_health = hp
		hud_delay -= delta
		if hud_delay <= 0.0:
			hud_delay = 0.18
			game.ui.set_echo_trial_progress(true,"DEPTH %d · %s" % [depth,TITLES[depth-1]],maxi(1,wave),3,elapsed,hit_count)
	if phase == WARNING:
		warning -= delta
		if warning <= 0.0:
			_spawn_wave(game)
	elif phase == BATTLE:
		for enemy in enemies:
			if is_instance_valid(enemy) and not enemy.is_queued_for_deletion():
				return
		enemies.clear()
		if wave >= 3:
			phase = CLEARED
			var descent: Node = get_node_or_null("../Portals/Descent")
			if descent != null:
				descent.set("opened",true)
			game.ui.set_echo_trial_progress(false)
			game.ui.show_pickup("DEPTH CLEARED · CLAIM THE ALTAR REWARD",Color("e6cc98"))
			set_process(false)
		else:
			game.player.stamina = minf(game.player.MAX_STAMINA,game.player.stamina+22.0)
			game.ui.set_stamina(game.player.stamina,game.player.MAX_STAMINA)
			phase = WARNING
			warning = 2.0
			game.ui.show_pickup("THE NEXT BELL · TWO SECONDS",Color("bfb2d0"))
	queue_redraw()

func _spawn_wave(game: Node) -> void:
	wave += 1
	var lineup: Array[String] = recipe(depth,wave)
	var markers: Node = get_node("../SpawnWells")
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = run_seed+depth*100+wave
	var offset: int = rng.randi_range(0,markers.get_child_count()-1)
	for i in range(lineup.size()):
		var kind: String = lineup[i]
		var enemy: Node2D = (WRAITH if kind=="wraith" else HUNTER).instantiate() as Node2D
		var elite: bool = kind.begins_with("elite_")
		var point: Vector2 = (markers.get_child((i+offset)%markers.get_child_count()) as Marker2D).global_position
		if kind=="wraith":
			enemy.set("max_health",25.0+float(depth)*8.0)
			enemy.set("move_speed",88.0+depth*7.0)
			enemy.set("damage_to_player",6.0+depth*1.5)
			enemy.set("aggro_radius",1800.0)
			enemy.set("drop_data",null)
		else:
			enemy.set("archetype",kind.trim_prefix("elite_"))
			enemy.set("is_elite",elite)
			enemy.set("maximum_health",(95.0+depth*48.0) if elite else (40.0+depth*13.0))
			enemy.set("strike_damage",(13.0+depth*3.0) if elite else (7.0+depth*2.0))
			enemy.set("move_speed",85.0+depth*6.0)
			enemy.set("notice_range",1800.0)
			enemy.set("loot_template",null)
		# Spawn points are editor nodes; no random positions inside collision.
		add_child(enemy)
		enemy.global_position = point
		if kind!="wraith":
			enemy.set("home_position",point)
		enemy.add_to_group("sepulchre_enemy_v266")
		enemies.append(enemy)
	phase = BATTLE
	game.ui.show_pickup(("GUARDIAN AWAKENS" if wave==3 else "WAVE %d / 3" % wave),Color("d4b8c5"))

func _claim_reward(game: Node) -> String:
	if reward_claimed:
		return "REWARD CLAIMED · RETURN OR DESCEND"
	var flag: String = "v266_sepulchre_depth_%d_reward" % depth
	var first: bool = not game.inventory.has_collected(flag)
	var template: GhostItemData = FIRST_REWARDS[depth-1] if first else REPEAT_REWARDS[posmod(run_seed,REPEAT_REWARDS.size())]
	var quality: String = ("unique" if depth>=2 else "rare") if first else "rare"
	var item: GhostItemInstance = game.inventory.add_loot(template,run_seed+depth,quality,"")
	if item == null:
		return str(game.inventory.last_add_failure)
	if first:
		game.inventory.collected_pickups[flag] = true
		game.inventory.save_game()
	reward_claimed = true
	queue_redraw()
	return item.quality.to_upper()+" · "+item.display_name()

func _draw() -> void:
	var ink: Color = Color("c7ab82") if phase==CLEARED else Color("887b9a")
	draw_circle(Vector2.ZERO,35.0,Color(0.06,0.045,0.08,0.65))
	draw_arc(Vector2.ZERO,35.0,0.0,TAU,48,ink,1.8,true)
	draw_arc(Vector2.ZERO,27.0,0.0,TAU,36,Color(ink.r,ink.g,ink.b,0.45),1.0,true)
	for i in range(3):
		var a: float = float(i)*TAU/3.0-PI/2.0
		draw_circle(Vector2.from_angle(a)*31.0,4.0,ink if i<wave else Color("443c4a"))
	draw_line(Vector2(-12,0),Vector2(12,0),ink,2.0,true)
	draw_line(Vector2(0,-12),Vector2(0,12),ink,2.0,true)
