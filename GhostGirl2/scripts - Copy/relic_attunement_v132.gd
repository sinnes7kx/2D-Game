@tool
extends Node2D
## One-off appearance imprint; NEVER changes seed, stats, rarity or sockets.
## Uses already-saved cosmetic fields, so no new item save keys are needed.
@export var attunement_id: String = "v132_moonwake_attunement"
@export var infusion_salt: int = 132640
@export var requires_warden_defeat: bool = false
var spent: bool = false
var clock: float = 0.0

func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group("interactable")
		add_to_group("v132_relic_attunement")

func restore_from_inventory(save_data: Node) -> void:
	spent = save_data != null and save_data.has_collected(attunement_id)
	if spent:
		remove_from_group("interactable")
	else:
		add_to_group("interactable")
	queue_redraw()

func try_attune(inventory: Node) -> String:
	if inventory == null:
		return "NO RELIQUARY RESPONDS"
	if spent or inventory.has_collected(attunement_id):
		return "THIS IMPRINT HAS ALREADY BEEN SPENT"
	if requires_warden_defeat and not inventory.has_collected("v132_moor_warden_defeated"):
		return "THE WARDEN'S VEIL STILL BARS THE RELIC"
	var item: GhostItemInstance = inventory.get_equipped("sword")
	if item == null:
		item = inventory.get_equipped("wand")
	if item == null or item.quality not in ["rare", "set", "unique"]:
		return "EQUIP A RARE, SET, OR UNIQUE WEAPON FIRST"
	# Every altar attunement grants a fresh 128-bit cosmetic identity rather
	# than deriving the same look from a fixed relic/altar seed for everyone.
	# Applies only visual fields; loot damage, stats and sockets remain intact.
	item.apply_cosmetic_uid(GhostCosmeticRNGV152.fresh_uid())
	var records: Dictionary = inventory.get("collected_pickups") as Dictionary
	records[attunement_id] = true
	inventory.call("save_game")
	inventory.equipment_changed.emit()
	inventory.contents_changed.emit()
	spent = true
	remove_from_group("interactable")
	queue_redraw()
	return "RELIC ATTUNED · %s · STATS UNCHANGED" % item.display_name().to_upper()

func _process(delta: float) -> void:
	clock += delta
	if Engine.is_editor_hint() or not spent:
		queue_redraw()

func _draw() -> void:
	var alpha: float = 0.28 if spent else 0.55 + 0.12 * sin(clock * 2.0)
	draw_circle(Vector2.ZERO, 50.0, Color(0.35, 0.18, 0.47, alpha * 0.15))
	draw_colored_polygon(PackedVector2Array([Vector2(-24, 15), Vector2(-20, -14), Vector2(0, -38), Vector2(20, -14), Vector2(24, 15)]), Color("2e2735"))
	draw_line(Vector2(-24, 15), Vector2(-20, -14), Color("bb9cae"), 2.1, true)
	draw_line(Vector2(-20, -14), Vector2(0, -38), Color("c5a6b7"), 1.8, true)
	draw_line(Vector2(0, -38), Vector2(20, -14), Color("c5a6b7"), 1.8, true)
	draw_line(Vector2(20, -14), Vector2(24, 15), Color("bb9cae"), 2.1, true)
	for i in range(3):
		var a: float = clock * 0.37 + TAU * float(i) / 3.0
		var p: Vector2 = Vector2.from_angle(a) * 24.0 + Vector2(0, -13)
		draw_circle(p, 3.0, Color(0.82, 0.69, 0.96, alpha))
	if not spent:
		draw_arc(Vector2(0, -15), 36.0, clock * 0.18, clock * 0.18 + TAU * 0.8, 36, Color(0.91, 0.73, 0.97, alpha), 1.6, true)
