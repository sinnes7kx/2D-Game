extends Resource
class_name GhostItemData
## Item definition. Quality, sockets and variable affixes belong to each dropped instance.
@export var item_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var unique: bool = false
@export_enum("none", "dress", "wings", "trinket", "charm", "wand", "sword", "helm") var equip_slot: String = "none"
@export_enum("equipment", "gem", "rune", "quest", "material") var item_class: String = "equipment"
@export var stat_id: String = ""
@export_range(0.0, 30.0, 0.1) var min_stat: float = 0.0
@export_range(0.0, 30.0, 0.1) var max_stat: float = 0.0
@export_range(0, 4, 1) var max_sockets: int = 0
@export var item_level: int = 1
@export_enum("blade", "dagger", "dual_dagger", "dual_sword", "spear", "maul", "twinblade", "scythe", "halberd", "bow", "crossbow") var weapon_style: String = "blade"
@export_range(0.0, 100.0, 0.1) var min_weapon_damage: float = 0.0
@export_range(0.0, 100.0, 0.1) var max_weapon_damage: float = 0.0
@export var socket_bonus_id: String = ""
@export var socket_bonus_value: float = 0.0
# Zero means use the default footprint based on the equipment slot.
@export_range(0, 4, 1) var inventory_width: int = 0
@export_range(0, 4, 1) var inventory_height: int = 0
