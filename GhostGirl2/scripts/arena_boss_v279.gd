extends CharacterBody2D
## Single-opponent arena boss. All attacks resolve once after a visible tell.
signal defeated(boss_id: String)
const FX = preload("res://scripts/impact_spawner_v149.gd")
const AUDIO = preload("res://scripts/combat_juice_v194.gd")
const SHADOW = preload("res://scripts/atmosphere_textures_v278.gd")
const ART: Dictionary = {
	"iron":preload("res://assets/world/arena_v279/iron_penitent.svg"),
	"bell":preload("res://assets/world/arena_v279/bell_widow.svg"),
	"astral":preload("res://assets/world/arena_v279/astral_inquisitor.svg")
}
const DATA: Dictionary = {
	"iron":{"title":"THE IRON PENITENT","hp":320.0,"speed":112.0,"color":Color("d6af91"),"reward":"res://items/hollowbell_maul_v277.tres","hint":"Circle behind the shield or break its guard with heavy blows."},
	"bell":{"title":"THE BELL WIDOW","hp":390.0,"speed":102.0,"color":Color("dab1cf"),"reward":"res://items/frostveil_bow_v277.tres","hint":"Jump the ground pulses. Punish the recovery."},
	"astral":{"title":"THE ASTRAL INQUISITOR","hp":440.0,"speed":142.0,"color":Color("aebff4"),"reward":"res://items/mourning_star_crossbow_v277.tres","hint":"Hook the exposed channel; evade the locked beam."}
}
const FLOOR: Rect2 = Rect2(155,205,1490,860)
const SEEK: int = 0
const TELL: int = 1
const RECOVER: int = 2
const STAGGER: int = 3
var boss_id: String = "iron"
var health: float = 320.0
var maximum_health: float = 320.0
var player: CharacterBody2D
var mode: int = SEEK
var phase: int = 1
var timer: float = 0.6
var total: float = 1.0
var attack: String = ""
var direction: Vector2 = Vector2.DOWN
var target_point: Vector2 = Vector2.ZERO
var attack_index: int = 0
var poise: float = 0.0
var hook_cooldown: float = 0.0
var frost_left: float = 0.0
var frost_factor: float = 1.0
var flash: float = 0.0
var release_left: float = 0.0
var age: float = 0.0
var dead: bool = false

func _ready() -> void:
	maximum_health=float(DATA[boss_id]["hp"])
	health=maximum_health
	collision_layer=16
	collision_mask=2
	add_to_group("enemies")
	set_meta("arrow_impact_material","metal" if boss_id=="iron" else "magic")
	var feet: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius=36.0
	feet.shape=shape
	feet.position=Vector2(0,-29)
	add_child(feet)
	var area: Area2D = Area2D.new()
	area.name="SpellHurtbox"
	area.collision_layer=32
	area.collision_mask=0
	area.monitoring=false
	add_child(area)
	var body: CollisionShape2D = CollisionShape2D.new()
	var capsule: CapsuleShape2D = CapsuleShape2D.new()
	capsule.radius=41.0
	capsule.height=132.0
	body.shape=capsule
	body.position=Vector2(0,-66)
	area.add_child(body)

static func hit_region(kind: String, origin: Vector2, axis: Vector2, mark: Vector2, point: Vector2, airborne: bool) -> bool:
	var offset: Vector2 = point-origin
	var d: float = offset.length()
	match kind:
		"shield_sweep": return d<=160.0 and (d<1.0 or axis.dot(offset.normalized())>=0.25)
		"shield_lance": return d<=285.0 and axis.dot(offset)>=0.0 and absf(offset.cross(axis))<=39.0
		"bell_pulse": return not airborne and d<=245.0
		"bell_sweep": return d<=170.0 and (d<1.0 or axis.dot(offset.normalized())>=-0.18)
		"astral_beam": return d<=1050.0 and axis.dot(offset)>=0.0 and absf(offset.cross(axis))<=43.0
		"astral_seal": return point.distance_to(mark)<=118.0
	return false

static func guard_factor(id: String, state: int, facing: Vector2, attacker_offset: Vector2) -> float:
	if id!="iron" or state==RECOVER or state==STAGGER or attacker_offset.is_zero_approx():
		return 1.0
	return 0.22 if facing.dot(attacker_offset.normalized())>0.42 else 1.0

func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(player) or not player.is_inside_tree():
		return
	var world: Node = get_tree().current_scene
	if world!=null and world.has_node("HUD") and world.get_node("HUD").call("is_menu_open"):
		velocity=Vector2.ZERO
		return
	age+=delta
	flash=maxf(0.0,flash-delta)
	release_left=maxf(0.0,release_left-delta)
	hook_cooldown=maxf(0.0,hook_cooldown-delta)
	frost_left=maxf(0.0,frost_left-delta)
	poise=maxf(0.0,poise-delta*8.0)
	phase=2 if health<=maximum_health*0.50 else 1
	timer=maxf(0.0,timer-delta)
	var offset: Vector2 = player.global_position-global_position
	var distance: float = offset.length()
	if mode==TELL:
		velocity=Vector2.ZERO
		if timer<=0.0:
			_resolve()
			if dead or not is_inside_tree():
				return
			mode=RECOVER
			timer=1.05 if phase==1 else 0.84
	elif mode==RECOVER or mode==STAGGER:
		velocity=Vector2.ZERO
		if timer<=0.0:
			mode=SEEK
			timer=0.16
	else:
		var aim: Vector2 = offset.normalized() if distance>1.0 else direction
		direction=aim
		var distance_gate: float = 138.0 if boss_id=="iron" else (210.0 if boss_id=="bell" else 540.0)
		var walk: Vector2 = Vector2.ZERO
		if boss_id=="astral" and distance<215.0:
			walk=-aim
		elif distance>distance_gate:
			walk=aim
		if timer<=0.0 and distance<=distance_gate and (boss_id!="astral" or distance>=180.0):
			_start_attack()
		else:
			var speed: float = float(DATA[boss_id]["speed"])*(1.10 if phase==2 else 1.0)*(frost_factor if frost_left>0.0 else 1.0)
			velocity=walk*speed
			move_and_slide()
			global_position=global_position.clamp(FLOOR.position,FLOOR.end)
			# The caster cannot indefinitely evade in a corner.
			if boss_id=="astral" and timer<=0.0 and distance<180.0 and walk!=Vector2.ZERO:
				_start_attack()
	queue_redraw()

func _start_attack() -> void:
	mode=TELL
	velocity=Vector2.ZERO
	attack_index+=1
	match boss_id:
		"iron": attack="shield_lance" if attack_index%3==0 else "shield_sweep"
		"bell": attack="bell_sweep" if attack_index%3==0 else "bell_pulse"
		"astral": attack="astral_seal" if attack_index%2==0 else "astral_beam"
	target_point=player.global_position
	total=1.08 if attack=="bell_pulse" else (1.45 if attack=="astral_beam" else (1.10 if attack=="astral_seal" else 0.78))
	if phase==2:
		total*=0.83
	timer=total
	AUDIO.play(get_parent(),global_position,"spell_heavy" if boss_id=="astral" else "heavy_swing",-18.0)

func _resolve() -> void:
	release_left=0.24
	FX.burst(get_parent(),global_position+Vector2(0,-12),"slam" if boss_id!="astral" else "stone",0.9,direction,attack_index+279)
	AUDIO.play(get_parent(),global_position,"spell_release_heavy" if boss_id=="astral" else "ground_slam",-14.0)
	FX.rumble(global_position,5.5)
	var airborne: bool = float(player.get("jump_time_left"))>0.0
	if not hit_region(attack,global_position,direction,target_point,player.global_position,airborne):
		return
	var ray: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(global_position,player.global_position,2,[get_rid()])
	if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
		return
	var damage: float = 15.0 if boss_id=="iron" else (18.0 if boss_id=="bell" else 16.0)
	if phase==2:
		damage*=1.14
	player.call("receive_damage",damage,global_position)

func hit(amount: float, poise_multiplier: float = 1.0) -> void:
	if dead or not is_instance_valid(player):
		return
	var factor: float = guard_factor(boss_id,mode,direction,player.global_position-global_position)
	health=maxf(0.0,health-maxf(0.0,amount)*factor)
	flash=0.13
	poise+=maxf(0.0,amount)*maxf(0.5,poise_multiplier)*0.45
	if factor<1.0:
		AUDIO.play(get_parent(),global_position,"arrow_metal",-20.0)
	if health<=0.0:
		dead=true
		remove_from_group("enemies")
		collision_layer=0
		velocity=Vector2.ZERO
		FX.burst(get_parent(),global_position+Vector2(0,-30),"slam",1.3,direction,27999)
		defeated.emit(boss_id)
		queue_free()
		return
	if poise>=(65.0 if boss_id=="iron" else 90.0) and mode!=STAGGER:
		_stagger(1.05 if boss_id=="iron" else 0.72)
	queue_redraw()

func _stagger(duration: float) -> void:
	poise=0.0
	mode=STAGGER
	timer=duration
	attack=""
	velocity=Vector2.ZERO
	flash=0.28
	AUDIO.play(get_parent(),global_position,"parry",-14.0)

func on_hook_yank(_destination: Vector2,_strength: float) -> void:
	if not dead and boss_id=="astral" and mode==TELL and attack=="astral_beam" and hook_cooldown<=0.0:
		hook_cooldown=3.0
		_stagger(1.35)

func apply_frost_slow(seconds: float,factor: float) -> void:
	frost_left=maxf(frost_left,seconds*0.65)
	frost_factor=clampf(factor,0.70,1.0)

func offers_backstep_counter(point: Vector2) -> bool:
	return not dead and mode==TELL and timer<0.30 and point.distance_to(global_position)<195.0

func spell_aim_point() -> Vector2:
	return global_position+Vector2(0,-65)

func _draw() -> void:
	if dead:
		return
	var ink: Color = DATA[boss_id]["color"]
	if mode==TELL or release_left>0.0:
		var a: float = 0.55 if release_left>0.0 else 0.20+0.22*(1.0-timer/maxf(0.01,total))
		_draw_tell(ink,a)
	draw_texture_rect(SHADOW.shadow(),Rect2(-68,-19,136,38),false,Color(0.03,0.02,0.05,0.68))
	var tex: Texture2D = ART[boss_id]
	var bob: float = sin(age*3.0)*(3.0 if boss_id=="astral" else 1.2)
	var lean: float = direction.x*(4.0 if mode==TELL else 1.5)
	var tint: Color = Color.WHITE.lerp(ink,0.55) if flash>0.0 else Color.WHITE
	draw_texture_rect(tex,Rect2(-78+lean,-160+bob,156,160),false,tint)
	if boss_id=="iron" and mode in [SEEK,TELL]:
		draw_arc(Vector2.ZERO,57.0,direction.angle()-1.14,direction.angle()+1.14,24,Color(ink.r,ink.g,ink.b,0.75),3.0,true)
	if mode==STAGGER:
		draw_arc(Vector2(0,-115),35.0,age*2.0,age*2.0+PI,20,Color("f7dfb4"),2.0,true)
	if boss_id=="astral" and mode==TELL and attack=="astral_beam":
		draw_arc(Vector2(0,-88),48.0,0.0,TAU,32,Color("d8c6ff"),2.0,true)
		draw_circle(Vector2(0,-88),6.0,Color("f4e3ff"))

func _draw_tell(ink: Color,a: float) -> void:
	var fill: Color = Color(ink.r,ink.g,ink.b,a*0.36)
	var edge: Color = Color(ink.r,ink.g,ink.b,minf(1.0,a+0.34))
	var normal: Vector2 = direction.orthogonal()
	match attack:
		"bell_pulse":
			draw_circle(Vector2.ZERO,245.0,fill)
			draw_arc(Vector2.ZERO,245.0,0,TAU,72,edge,2.4,true)
			draw_arc(Vector2.ZERO,245.0*(1.0-clampf(timer/maxf(0.01,total),0.0,1.0)),0,TAU,64,edge,2.0,true)
		"shield_sweep","bell_sweep":
			var radius: float = 160.0 if attack=="shield_sweep" else 170.0
			var angle: float = acos(0.25) if attack=="shield_sweep" else acos(-0.18)
			var points: PackedVector2Array = PackedVector2Array([Vector2.ZERO])
			for i in range(41):
				points.append(Vector2.from_angle(direction.angle()+lerpf(-angle,angle,float(i)/40.0))*radius)
			draw_colored_polygon(points,fill)
			draw_arc(Vector2.ZERO,radius,direction.angle()-angle,direction.angle()+angle,40,edge,2.5,true)
		"shield_lance","astral_beam":
			var length: float = 285.0 if attack=="shield_lance" else 1050.0
			var width: float = 39.0 if attack=="shield_lance" else 43.0
			draw_colored_polygon(PackedVector2Array([normal*width,direction*length+normal*width,direction*length-normal*width,-normal*width]),fill)
			draw_line(normal*width,direction*length+normal*width,edge,2.0,true)
			draw_line(-normal*width,direction*length-normal*width,edge,2.0,true)
		"astral_seal":
			var at: Vector2 = to_local(target_point)
			draw_circle(at,118.0,fill)
			draw_arc(at,118.0,0,TAU,56,edge,2.5,true)
