extends Node2D
## Persistent victory/claim flags use the existing inventory save dictionary.
## No normal monster drops or new save files; replays are for mastery.
const BOSS = preload("res://scripts/arena_boss_v279.gd")
const ORDER: Array[String] = ["iron","bell","astral"]
var world: Node
var active_boss: CharacterBody2D
var pending_id: String = ""
var countdown: float = 0.0
var hud: CanvasLayer
var title_label: Label
var health_bar: ProgressBar
var detail_label: Label

static func victory_key(id: String) -> String:
	return "v279_arena_victory_"+id

static func reward_key(id: String) -> String:
	return "v279_arena_reward_"+id

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
	return "E  REMATCH" if world.inventory.has_collected(victory_key(id)) else "E  CHALLENGE"

func interact_boss(id: String) -> String:
	if world==null or not BOSS.DATA.has(id) or busy():
		return ""
	if world.inventory.has_collected(victory_key(id)) and not world.inventory.has_collected(reward_key(id)):
		var data: GhostItemData = load(str(BOSS.DATA[id]["reward"])) as GhostItemData
		var reward: GhostItemInstance = world.inventory.add_loot(data,279100+ORDER.find(id),"unique","colosseum")
		if reward==null:
			return "RELIC RESERVED · "+world.inventory.last_add_failure
		world.inventory.collected_pickups[reward_key(id)]=true
		world.inventory.save_game()
		return "VICTORY RELIC · "+reward.display_name()
	if world.player.carrying!=null:
		return "PUT DOWN THE OBJECT BEFORE CHALLENGING"
	pending_id=id
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
		title_label.text=str(BOSS.DATA[pending_id]["title"])
		detail_label.text="DUEL BEGINS IN %.1f"%countdown
		health_bar.max_value=1
		health_bar.value=1
		if countdown<=0.0:
			_spawn()
	elif is_instance_valid(active_boss):
		health_bar.max_value=float(active_boss.get("maximum_health"))
		health_bar.value=float(active_boss.get("health"))
		var state: int = int(active_boss.get("mode"))
		var attack: String = str(active_boss.get("attack"))
		var phase: int = int(active_boss.get("phase"))
		var hint: String = "PHASE %d"%phase
		if state==BOSS.STAGGER:
			hint="STAGGERED · STRIKE"
		elif state==BOSS.RECOVER:
			hint="RECOVERY · STRIKE"
		elif state==BOSS.TELL and attack=="bell_pulse":
			hint="GROUND PULSE · JUMP"
		elif state==BOSS.TELL and attack=="astral_beam":
			hint="CHANNEL EXPOSED · Q HOOK OR EVADE"
		elif str(active_boss.get("boss_id"))=="iron":
			hint="GUARDED · FLANK OR BREAK GUARD"
		detail_label.text=hint

func _spawn() -> void:
	var id: String = pending_id
	pending_id=""
	if is_instance_valid(active_boss) or not BOSS.DATA.has(id):
		return
	var boss: CharacterBody2D = BOSS.new()
	boss.set("boss_id",id)
	boss.set("player",world.player)
	boss.position=Vector2(900,405)
	add_child(boss)
	boss.connect("defeated",_on_victory)
	active_boss=boss
	title_label.text=str(BOSS.DATA[id]["title"])
	detail_label.text="PHASE 1"
	health_bar.max_value=float(boss.get("maximum_health"))
	health_bar.value=health_bar.max_value

func _on_victory(id: String) -> void:
	active_boss=null
	hud.visible=false
	world.player.clear_lock_target()
	var first: bool = not world.inventory.has_collected(victory_key(id))
	if first:
		world.inventory.collected_pickups[victory_key(id)]=true
		world.inventory.save_game()
	world.ui.show_pickup("DUEL WON · CLAIM YOUR RELIC" if first else "DUEL WON · REMATCH COMPLETE",Color("e9d4af"))
