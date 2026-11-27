extends CanvasLayer
## Screen-space grading after the world, before HUD layer 20. A single
## texture sample, no blur/glow render targets, works with GL compatibility.
const GRADE = preload("res://assets/effects/gothic_grade_v277.gdshader")
const CONFIG: String = "user://ghost_girl_grade_v277.cfg"
const NAMES: Array[String] = ["OFF","SOFT","GOTHIC","DEEP GOTHIC"]
const STRENGTH: Array[float] = [0.0,0.42,0.70,0.94]
const VIGNETTE: Array[float] = [0.0,0.07,0.13,0.22]
var preset: int = 2
var screen_rect: ColorRect
var copy: BackBufferCopy
var grade_material: ShaderMaterial

func _ready() -> void:
	layer=10
	var config: ConfigFile = ConfigFile.new()
	if config.load(CONFIG)==OK:
		preset=clampi(int(config.get_value("graphics","gothic_grade",2)),0,3)
	copy=BackBufferCopy.new()
	copy.copy_mode=BackBufferCopy.COPY_MODE_VIEWPORT
	add_child(copy)
	screen_rect=ColorRect.new()
	screen_rect.name="WorldColorGrade"
	screen_rect.mouse_filter=Control.MOUSE_FILTER_IGNORE
	grade_material=ShaderMaterial.new()
	grade_material.shader=GRADE
	screen_rect.material=grade_material
	add_child(screen_rect)
	screen_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_apply()

func _apply() -> void:
	screen_rect.visible=preset>0
	copy.copy_mode=BackBufferCopy.COPY_MODE_VIEWPORT if preset>0 else BackBufferCopy.COPY_MODE_DISABLED
	grade_material.set_shader_parameter("strength",STRENGTH[preset])
	grade_material.set_shader_parameter("vignette",VIGNETTE[preset])
	grade_material.set_shader_parameter("atmosphere",0.012+float(preset)*0.009)

func cycle() -> String:
	preset=(preset+1)%NAMES.size()
	_apply()
	var config: ConfigFile = ConfigFile.new()
	config.set_value("graphics","gothic_grade",preset)
	config.save(CONFIG)
	return NAMES[preset]
