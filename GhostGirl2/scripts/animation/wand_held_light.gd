extends Node2D
## Physical wand-tip illumination. Independent from the prestige overlay's
## self-modulate so the same scale is applied in world and inspection.
const RENDER = preload("res://scripts/animation/weapon_render_contract.gd")
const FX = preload("res://scripts/fx_intensity_v1924.gd")
var points: PackedVector2Array=PackedVector2Array()
var palette: Array[Color]=[]
var look: Dictionary={}
var key: String=""
var strength: float=0.0
var phase: float=0.0

func set_pose(item: GhostItemInstance,span: PackedVector2Array,behind: bool,delta: float) -> void:
	strength=RENDER.effect_scale(item)
	if item==null or span.size()!=2 or strength<=0.0 or FX.intensity<=0.0:
		hide()
		return
	var next: String="%s:%s:%s:%s:%s:%s:%s:%s:%s:%s" % [item.get_instance_id(),item.cosmetic_uid,item.visual_seed(),item.gradient_version,item.debug_collector_tier,item.debug_color_mode,item.debug_glow_motif,item.effect_palette_channel(),item.visual_signature(),item.mythic_layer_variant()]
	if key!=next:
		key=next
		look=item.collector_appearance()
		palette=item.glow_gradient_colors()
	points=span
	phase+=delta
	self_modulate.a=item.weapon_opacity()
	show_behind_parent=behind
	z_index=-1 if behind else 7
	show()
	queue_redraw()

func _draw() -> void:
	RENDER.draw_wand_head(self,points,palette,look,phase,strength)
