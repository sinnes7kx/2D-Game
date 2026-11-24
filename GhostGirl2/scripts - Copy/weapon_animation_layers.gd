extends Node2D
## v1.22: All scythe/halberd ART is composited into Ghost Girl's SpriteFrames.
## Separate overlay sprites are deliberately hidden to avoid invisible or double
## weapons. Item-seeded particle colors and motion remain independent FX.
const MANIFEST_PATH: String = "res://resources/weapon_layer_manifest.json"
@onready var body: AnimatedSprite2D = get_parent() as AnimatedSprite2D
@onready var back_layer: AnimatedSprite2D = $Back
@onready var front_layer: AnimatedSprite2D = $Front
var inventory: Node = null
var tips_by_animation: Dictionary = {}
var fx_enabled: bool = false
var fx_style: int = 0
var fx_tier: int = 0
var fx_color: Color = Color("d9b3db")
var fx_accent: Color = Color("e9b9de")
var fx_trail: int = 0
var aura_time: float = 0.0
var aura_tip: Vector2 = Vector2.ZERO
var current_layer_animation: String = ""

func _ready() -> void:
	back_layer.hide()
	front_layer.hide()
	# The manifest supplies tip coordinates for the cosmetic particle effects.
	# Textures themselves come from the BAKED body atlas, installed separately.
	if FileAccess.file_exists(MANIFEST_PATH):
		var payload: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
		if payload is Array:
			for entry in payload:
				if entry is Dictionary:
					tips_by_animation[str(entry.get("name", ""))] = entry.get("tip_positions", [])

func bind_inventory(value: Node) -> void:
	inventory = value
	if inventory != null and not inventory.equipment_changed.is_connected(refresh_appearance):
		inventory.equipment_changed.connect(refresh_appearance)
	refresh_appearance()

func _equipped_weapon() -> GhostItemInstance:
	return inventory.get_equipped("sword") if inventory != null else null

func refresh_appearance() -> void:
	fx_enabled = false
	if inventory == null:
		queue_redraw()
		return
	var weapon: GhostItemInstance = _equipped_weapon()
	if weapon == null or weapon.weapon_style() not in ["scythe", "halberd"]:
		queue_redraw()
		return
	var fx: Dictionary = weapon.effect_rolls()
	fx_enabled = true
	fx_style = int(fx["motif"])
	fx_tier = int(fx["tier"])
	fx_color = GhostWeaponFXLibrary.color(int(fx["color"]))
	fx_accent = GhostWeaponFXLibrary.color(int(fx["accent"]))
	fx_trail = int(fx["trail"])
	queue_redraw()

func _phase_color(offset: float) -> Color:
	var t: float = 0.5 + 0.5 * sin(aura_time * (1.25 + float(fx_trail) * 0.16) + offset)
	return fx_color.lerp(fx_accent, t)

func _process(delta: float) -> void:
	aura_time += delta
	back_layer.hide()
	front_layer.hide()
	current_layer_animation = ""
	if not fx_enabled or body == null or body.sprite_frames == null:
		queue_redraw()
		return
	var weapon: GhostItemInstance = _equipped_weapon()
	if weapon == null:
		queue_redraw()
		return
	var animation_name: String = str(body.animation)
	var style: String = weapon.weapon_style()
	if animation_name.begins_with(style + "_") or animation_name.begins_with("attack_" + style + "_"):
		current_layer_animation = animation_name
		var points: Array = tips_by_animation.get(animation_name, [])
		if not points.is_empty():
			var xy: Array = points[clampi(body.frame, 0, points.size() - 1)]
			if xy.size() >= 2:
				aura_tip = Vector2(float(xy[0]), float(xy[1]))
	queue_redraw()

# v1.41: intentionally suppress the original tip-centered circular/rotating
# ornaments. The rare-item axial VFX are now drawn by weapon_prestige_fx.gd,
# which uses a grip-to-tip segment rather than an independent round halo.
# Keeping the manifest/tip tracking above preserves existing frame integration.
func _draw() -> void:
	pass
