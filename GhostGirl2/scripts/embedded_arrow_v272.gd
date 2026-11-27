extends Node2D
## Visual remnant only. Room cleanup, bounded lifetime and cap; no collider.
const ENV = preload("res://scripts/archery_environment_v272.gd")
var direction: Vector2 = Vector2.RIGHT
var bolt: bool = false
var burning: bool = false
var tint: Color = Color("e4dce5")
var age: float = 0.0
var surface: WeakRef
var local_anchor: Vector2
var local_axis: Vector2

func bind_surface(value: Object,point: Vector2,heading: Vector2) -> void:
	direction=heading.normalized()
	global_position=point-direction*(10.0 if bolt else 17.0)
	if value is Node2D:
		surface=weakref(value)
		local_anchor=value.to_local(global_position)
		local_axis=value.to_local(global_position+direction)-local_anchor

func _ready() -> void:
	z_index=12
	add_to_group("embedded_arrow_v272")
	queue_redraw()

func _process(delta: float) -> void:
	age+=delta
	if age>=ENV.EMBED_SECONDS:
		queue_free()
		return
	if surface!=null:
		var attached: Node2D = surface.get_ref() as Node2D
		if not is_instance_valid(attached) or attached.is_queued_for_deletion() or (attached.is_in_group("breakable_cover") and bool(attached.get("broken"))):
			queue_free()
			return
		global_position=attached.to_global(local_anchor)
		direction=(attached.to_global(local_anchor+local_axis)-global_position).normalized()
	if burning or age>ENV.EMBED_SECONDS-2.0:
		queue_redraw()

func _draw() -> void:
	var a: float = clampf((ENV.EMBED_SECONDS-age)/2.0,0.0,1.0)
	var length_scale: float = 0.58 if bolt else 1.0
	var n: Vector2 = direction.orthogonal()
	var shaft: Color = Color(tint.r,tint.g,tint.b,a)
	draw_line(-direction*20.0*length_scale,direction*17.0*length_scale,shaft,2.1,true)
	draw_line(direction*17.0*length_scale,direction*22.0*length_scale,shaft,2.8,true)
	for side in [-1.0,1.0]:
		draw_line(-direction*17.0*length_scale,-direction*10.0*length_scale+n*5.0*side,shaft,1.6,true)
	if burning and age<5.0:
		var f: float = (1.0-age/5.0)*a
		var point: Vector2 = direction*16.0*length_scale
		draw_circle(point,5.0+sin(age*12.0),Color(1.0,0.42,0.13,0.23*f))
		draw_line(point,point+Vector2(sin(age*9.0)*2.0,-7.0),Color(1.0,0.75,0.33,0.85*f),1.6,true)
