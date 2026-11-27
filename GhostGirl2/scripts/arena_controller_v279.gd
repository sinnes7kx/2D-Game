extends Node2D
## Persistent victory/claim flags use the existing inventory save dictionary.
## No normal monster drops or new save files; replays are for mastery.
const BOSS = preload("res://scripts/arena_boss_v279.gd")
const ORDER: Array[String] = ["iron","bell","astral"]
var world: Node
var active_boss: CharacterBody2D
var pending_id: String = ""
var countdown: float = 0.0
var champion_run: bool = false
var duel_seconds: float = 0.0
var start_health: float = 0.0
var damage_free: bool = true
var last_health: float = 0.0
var hud: CanvasLayer
var title_label: Label
var health_bar: ProgressBar
var detail_label: Label

static func victory_key(id: String) -> String:
	return "v279_arena_victory_"+id

static func reward_key(id: String) -> String:
	return "v279_arena_reward_"+id

static func champion_key(id: String) -> String:
	return "v281_arena_champion_"+id

static func flawless_key(id: String) -> String:
	return "v281_arena_flawless_"+id

func mastery(id: String) -> int:
	if not is_instance_valid(world):
		return 0
	if world.inventory.has_collected(flawless_key(id)):
		return 3
	if world.inventory.has_collected(champion_key(id)):
		return 2
	return 1 if world.inventory.has_collected(victory_key(id)) else 0

func bind(game: Node) -> void:
	world=game
	if hud==null:
		_build_hud()

func _build_hud() -> void:
	hud=CanvasLayer.new()
	hud.layer=19
	add_child(hud)
	var panel: Control = Control.new()
	panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	hud.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	panel.offset_left=-220
	panel.offset_right=220
	panel.offset_top=23
	panel.offset_bottom=92
	title_label=Label.new()
	title_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	title_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	title_label.position=Vector2(0,0)
	title_label.size=Vector2(440,25)
	title_label.add_theme_color_override("font_color",Color("eddcc5"))
	title_label.add_theme_color_override("font_outline_color",Color("251d2b"))
	title_label.add_theme_constant_override("outline_size",4)
	title_label.add_theme_font_size_override("font_size",19)
	panel.add_child(title_label)
	health_bar=ProgressBar.new()
	health_bar.position=Vector2(0,30)
	health_bar.size=Vector2(440,10)
	health_bar.show_percentage=false
	health_bar.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var bg: StyleBoxFlat = StyleBoxFlat.new()
	bg.bg_color=Color("231b2b")
	bg.border_color=Color("8f756e")
	bg.set_border_width_all(1)
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color=Color("b07886")
	health_bar.add_theme_stylebox_override("background",bg)
	health_bar.add_theme_stylebox_override("fill",fill)
	panel.add_child(health_bar)
	detail_label=Label.new()
	detail_label.position=Vector2(-80,44)
	detail_label.size=Vector2(600,24)
	detail_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	detail_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	detail_label.add_theme_color_override("font_color",Color("d9c6d9"))
	detail_label.add_theme_color_override("font_outline_color",Color("251d2b"))
	detail_label.add_theme_constant_override("outline_size",3)
	detail_label.add_theme_font_size_override("font_size",14)
	panel.add_child(detail_label)
	hud.visible=false

func busy() -> bool:
	return not pending_id.is_empty() or is_instance_valid(active_boss)

func prompt(id: String) -> String:
	if world==null or not BOSS.DATA.has(id):
		return ""
	if busy():
		return "DUEL IN PROGRESS"
	if world.inventory.has_collected(victory_key(id)) and not world.inventory.has_collected(reward_key(id)):
		return "E  CLAIM VICTORY RELIC"
	return "E  REMATCH   ·   SHIFT+E  CHAMPION" if mastery(id)>0 else "E  CHALLENGE"

func interact_boss(id: String, request_champion: bool = false) -> String:
	if world==null or not BOSS.DATA.has(id) or busy():
		return ""
	if request_champion and mastery(id)==0:
		return "DEFEAT THE NORMAL BOSS TO UNLOCK CHAMPION"
	if not request_champion and world.inventory.has_collected(victory_key(id)) and not world.inventory.has_collected(reward_key(id)):
		var data: GhostItemData = load(str(BOSS.DATA[id]["reward"])) as GhostItemData
		# Save the successful claim in the same inventory write as the item.
		# A full backpack does not consume the reward.
		world.inventory.collected_pickups[reward_key(id)]=true
		var reward: GhostItemInstance = world.inventory.add_loot(data,279100+ORDER.find(id),"unique","colosseum")
		if reward==null:
			world.inventory.collected_pickups.erase(reward_key(id))
			return "RELIC RESERVED · "+world.inventory.last_add_failure
		return "VICTORY RELIC · "+reward.display_name()
	if world.player.carrying!=null:
		return "PUT DOWN THE OBJECT BEFORE CHALLENGING"
	pending_id=id
	champion_run=request_champion
	duel_seconds=0.0
	damage_free=true
	countdown=2.5
	world.player.rose_hook.cancel_hook()
	world.player.clear_lock_target()
	world.player.reset_action_state()
	world.player.global_position=Vector2(900,760)
	world.player.velocity=Vector2.ZERO
	world.player.set_facing(Vector2.UP)
	world.player.snap_render_after_teleport()
	hud.visible=true
	return str(BOSS.DATA[id]["hint"])

func _physics_process(delta: float) -> void:
	if world==null or not is_instance_valid(world) or world.room!="colosseum":
		return
	if world.ui.is_menu_open():
		return
	if not pending_id.is_empty():
		countdown=maxf(0.0,countdown-delta)
		title_label.text=("CHAMPION · " if champion_run else "")+str(BOSS.DATA[pending_id]["title"])
		detail_label.text="DUEL BEGINS IN %.1f"%countdown
		health_bar.max_value=1
		health_bar.value=1
		if countdown<=0.0:
			_spawn()
	elif is_instance_valid(active_boss):
		duel_seconds+=delta
		var now: float = float(world.player.health)
		if now<last_health:
			damage_free=false
		last_health=now
		health_bar.max_value=float(active_boss.get("maximum_health"))
		health_bar.value=float(active_boss.get("health"))
		var state: int = int(active_boss.get("mode"))
		var attack: String = str(active_boss.get("attack"))
		var phase: int = int(active_boss.get("phase"))
		var hint: String = "PHASE %d"%phase
		var opening: String = str(active_boss.get("opening"))
		var remaining: Array = active_boss.get("followups")
		if state==BOSS.STAGGER or state==BOSS.RECOVER:
			hint=opening if not opening.is_empty() else "RECOVERY · STRIKE"
		elif state==BOSS.INTERVAL:
			hint="COMBO CONTINUES · %d STRIKES LEFT"%remaining.size()
		elif state==BOSS.WAVE:
			hint="SHOCKWAVE · JUMP AS THE RING REACHES YOU"
		elif state==BOSS.CHARGE or (state==BOSS.TELL and attack=="iron_charge"):
			hint="SHIELD CHARGE · SIDESTEP"
		elif state==BOSS.TELL and attack=="bell_wave":
			hint="BELL RISING · WATCH THE RING"
		elif state==BOSS.TELL and attack=="astral_beam":
			hint="CHANNEL EXPOSED · Q HOOK OR EVADE"
		elif state==BOSS.TELL and attack=="astral_seal":
			hint="ASTRAL SEAL · KEEP MOVING"
		elif str(active_boss.get("boss_id"))=="iron":
			hint="GUARDED · FLANK OR BREAK GUARD"
		var status: String = ("II  ·  " if phase==2 else "")+hint
		if champion_run and damage_free and int(active_boss.get("damage_taken_contacts"))==0:
			status+="  ·  FLAWLESS"
		detail_label.text=status

func _spawn() -> void:
	var id: String = pending_id
	pending_id=""
	if is_instance_valid(active_boss) or not BOSS.DATA.has(id):
		return
	var boss: CharacterBody2D = BOSS.new()
	boss.set("boss_id",id)
	boss.set("champion",champion_run)
	boss.set("player",world.player)
	boss.position=Vector2(900,405)
	add_child(boss)
	boss.connect("defeated",_on_victory)
	active_boss=boss
	start_health=float(world.player.health)
	last_health=start_health
	title_label.text=("CHAMPION · " if champion_run else "")+str(BOSS.DATA[id]["title"])
	detail_label.text="PHASE 1"
	health_bar.max_value=float(boss.get("maximum_health"))
	health_bar.value=health_bar.max_value

func _on_victory(id: String) -> void:
	var flawless: bool = champion_run and damage_free and is_instance_valid(active_boss) and int(active_boss.get("damage_taken_contacts"))==0 and float(world.player.health)>=last_health
	active_boss=null
	hud.visible=false
	world.player.clear_lock_target()
	var first: bool = not world.inventory.has_collected(victory_key(id))
	if first:
		world.inventory.collected_pickups[victory_key(id)]=true
		world.inventory.save_game()
		if champion_run:
		world.inventory.collected_pickups[champion_key(id)]=true
		if flawless:
			world.inventory.collected_pickups[flawless_key(id)]=true
		world.inventory.save_game()
		var result: String = "FLAWLESS CHAMPION" if flawless else "CHAMPION DEFEATED"
		world.ui.show_pickup("%s · %.1fs · TROPHY EARNED"%[result,duel_seconds],Color("f1d49e"))
	else:
		world.ui.show_pickup("DUEL WON · CLAIM YOUR RELIC" if first else "DUEL WON · REMATCH COMPLETE",Color("e9d4af"))
	champion_run=false
