extends Resource
class_name GhostItemData
const PAINTED_V287 = preload("res://scripts/painted_relic_art_v287.gd")
## Item definition. Quality, sockets and variable affixes belong to each dropped instance.
@export var item_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D:
	get:
		# Keep the original SVG as serialized fallback. Runtime inventory,
		# stash, tooltips and loot can all use the same painted icon.
		if not Engine.is_editor_hint():
			var painted: Texture2D = PAINTED_V287.texture(item_id,"icon")
			if painted!=null:
				return painted
		return icon
@export var unique: bool = false
@export_enum("none", "dress", "wings", "trinket", "charm", "wand", "sword", "helm", "companion") var equip_slot: String = "none"
@export_enum("equipment", "gem", "rune", "quest", "material") var item_class: String = "equipment"
@export var stat_id: String = ""
@export_range(0.0, 30.0, 0.1) var min_stat: float = 0.0
@export_range(0.0, 30.0, 0.1) var max_stat: float = 0.0
@export_range(0, 4, 1) var max_sockets: int = 0
@export var item_level: int = 1
@export_enum("blade", "dagger", "dual_dagger", "dual_sword", "spear", "maul", "twinblade", "scythe", "halberd", "bow", "crossbow", "rapier", "axe") var weapon_style: String = "blade"
@export_range(0.0, 100.0, 0.1) var min_weapon_damage: float = 0.0
@export_range(0.0, 100.0, 0.1) var max_weapon_damage: float = 0.0
@export var socket_bonus_id: String = ""
@export var socket_bonus_value: float = 0.0
# Zero means use the default footprint based on the equipment slot.
@export_range(0, 4, 1) var inventory_width: int = 0
@export_range(0, 4, 1) var inventory_height: int = 0
