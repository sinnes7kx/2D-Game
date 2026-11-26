@tool
extends StaticBody2D
## Ordinary scenery; no loot minting, save flags or enemy damage.
const FEEL = preload("res://scripts/impact_spawner_v149.gd")
const AUDIO = preload("res://scripts/combat_juice_v194.gd")
@export_enum("crate", "barrel") var kind: String = "crate"
@export var durability: float = 8.0
@export var prop_seed: int = 0
var health: float = 8.0
var broken: bool = false
var activated: bool = false
var age: float = 0.0
var burst_direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
    health = durability
    if Engine.is_editor_hint():
        return
    add_to_group("breakable_cover")
    add_to_group("breakable_container")
    add_to_group("hook_switch")
    set_meta("arrow_impact_material", "wood")
    set_physics_process(false)

func hook_prompt() -> String:
    return "" if broken else "F  BREAK " + kind.to_upper()

func on_hook_latched() -> void:
    receive_damage(durability)

func ignite_from_environment() -> void:
    receive_damage(durability)

func receive_damage(amount: float, source: Vector2 = Vector2.ZERO) -> void:
    if Engine.is_editor_hint() or broken or amount <= 0.0:
        return
    health -= amount
    if health <= 0.0:
        broken = true
        activated = true
        burst_direction = (global_position - source).normalized() if source != Vector2.ZERO else Vector2.RIGHT
        remove_from_group("hook_switch")
        remove_from_group("breakable_cover")
        remove_from_group("breakable_container")
        set_deferred("collision_layer", 0)
        FEEL.burst(get_parent(), global_position, "wood", 1.1, burst_direction, prop_seed)
        AUDIO.play(get_tree().current_scene, global_position, "arrow_wood", -13.0)
        set_physics_process(true)
    queue_redraw()

func _physics_process(delta: float) -> void:
    age += delta
    if age >= 0.85:
        queue_free()
    else:
        queue_redraw()

func _draw() -> void:
    if broken:
        for i in range(9):
            var a: float = float(i) * 2.4 + prop_seed * 0.13
            var p: Vector2 = (Vector2.from_angle(a) * (18.0 + i * 2.0) + burst_direction * 24.0) * age * 2.0
            draw_line(p, p + Vector2.from_angle(a + age * 4.0) * 10.0, Color(0.54, 0.40, 0.30, 1.0 - age / 0.85), 4.0, true)
        return
    draw_set_transform(Vector2(0, 7), 0.0, Vector2(1.0, 0.45))
    draw_circle(Vector2.ZERO, 32.0, Color(0.02, 0.02, 0.03, 0.33))
    draw_set_transform(Vector2.ZERO)
    if kind == "barrel":
        draw_colored_polygon(PackedVector2Array([Vector2(-20,-49),Vector2(20,-49),Vector2(27,-22),Vector2(20,5),Vector2(-20,5),Vector2(-27,-22)]), Color("62483f"))
        for x in [-15.0,-5.0,5.0,15.0]:
            draw_line(Vector2(x,-47),Vector2(x*1.25,-22),Color("8d6a53"),2.0,true)
            draw_line(Vector2(x*1.25,-22),Vector2(x,3),Color("403239"),2.0,true)
        for y in [-39.0,-9.0]:
            draw_line(Vector2(-24,y),Vector2(24,y),Color("302f36"),6.0,true)
            draw_line(Vector2(-22,y-2),Vector2(22,y-2),Color("897b71"),1.0,true)
        draw_set_transform(Vector2(0,-49),0.0,Vector2(1.0,0.35))
        draw_circle(Vector2.ZERO,21.0,Color("94735b"))
        draw_arc(Vector2.ZERO,20.0,0,TAU,32,Color("3b3033"),2.0,true)
        draw_set_transform(Vector2.ZERO)
    else:
        draw_rect(Rect2(-27,-44,54,49),Color("59433c"))
        draw_colored_polygon(PackedVector2Array([Vector2(-27,-44),Vector2(-13,-55),Vector2(38,-55),Vector2(27,-44)]),Color("89705b"))
        draw_colored_polygon(PackedVector2Array([Vector2(27,-44),Vector2(38,-55),Vector2(38,-6),Vector2(27,5)]),Color("40333a"))
        for x in [-16.0,-5.0,6.0,17.0]:
            draw_line(Vector2(x,-42),Vector2(x,3),Color("30272e"),1.5,true)
        draw_rect(Rect2(-27,-44,54,49),Color("96775f"),false,4.0)
        draw_line(Vector2(-23,0),Vector2(23,-40),Color("8b6a51"),7.0,true)
        for p in [Vector2(-21,-37),Vector2(21,-37),Vector2(-21,-2),Vector2(21,-2)]:
            draw_circle(p,1.8,Color("27252d"))
    if health < durability:
        draw_polyline(PackedVector2Array([Vector2(-8,-43),Vector2(2,-28),Vector2(-3,-22),Vector2(8,-10)]),Color("cfad87"),1.8,true)
