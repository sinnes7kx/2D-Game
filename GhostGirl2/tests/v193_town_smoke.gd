extends SceneTree
const TOWN = preload("res://scenes/rooms/lanternhaven.tscn")
const CRYPT = preload("res://scenes/rooms/moonwake_crypt.tscn")
const SANCTUM = preload("res://scenes/rooms/sanctum.tscn")
const INV = preload("res://scripts/inventory.gd")
const VAULT = preload("res://scripts/collection_vault_v181.gd")
var permitted: bool = false

func _initialize() -> void:
	call_deferred("_verify")

func _verify() -> void:
	var town: Node2D = TOWN.instantiate()
	root.add_child(town)
	var bg: Sprite2D = town.get_node("PaintedRoom")
	if bg.texture.get_size() != Vector2(3600,2400) or town.get_node("Collision").get_child_count() < 10:
		_fail("Town dimensions or collision missing")
		return
	for path in ["SpawnPoints/Default","SpawnPoints/From_moonwake_crypt","SpawnPoints/From_sanctum","Gameplay/RestShrines/TownEmber","Gameplay/Stashes/TownStash","Gameplay/Portals/moonwake_crypt","Gameplay/Portals/sanctum"]:
		if not town.has_node(path):
			_fail("Missing town landmark: "+path)
			return
	if not town.get_node("Gameplay/Stashes/TownStash").is_in_group("town_stash") or not get_nodes_in_group("enemy").is_empty():
		_fail("Chest missing interaction or town contains enemy")
		return
	for packed in [CRYPT,SANCTUM]:
		var room: Node2D = packed.instantiate()
		if not room.has_node("Gameplay/Portals/lanternhaven") or not room.has_node("SpawnPoints/From_lanternhaven") or room.get_node("Gameplay/Portals/lanternhaven").get("destination") != "lanternhaven":
			_fail("Missing reciprocal town route")
			return
		room.free()
	var inv: Node = INV.new()
	var item: GhostItemInstance = GhostItemGenerator.create(load("res://items/rosemirror_twinblade_v170.tres") as GhostItemData,193001,"rare")
	item.collector_locked = true
	var identity: Dictionary = item.cosmetic_snapshot()
	var stats: Dictionary = item.all_stats()
	inv.contents.append(item)
	inv.grid_positions.append(Vector2i.ZERO)
	var modal: Control = VAULT.new()
	root.add_child(modal)
	modal.call("open_vault",inv,item,-1,func() -> bool: return permitted)
	if not modal.get("deposit").disabled or modal.get("shown").size()!=1:
		_fail("Remote deposit was not blocked or backpack view missing")
		return
	modal.call("_store")
	if inv.contents.size()!=1 or not inv.vault.is_empty():
		_fail("Remote transfer mutated inventory")
		return
	permitted = true
	modal.call("refresh")
	if modal.get("deposit").disabled:
		_fail("Town deposit disabled")
		return
	# Test backend without writing user saves; UI uses exactly these functions.
	if not inv.vault_store(0,false) or inv.vault[0]!=item or not inv.set_exhibition(item,0,false):
		_fail("Town store or exhibition reference failed")
		return
	modal.call("open_vault",inv,item,-1,func() -> bool: return permitted)
	if modal.get("shown").size()!=1 or modal.get("withdraw").disabled:
		_fail("Stored view or withdrawal missing")
		return
	permitted = false
	modal.call("_withdraw")
	if inv.vault.size()!=1 or not inv.contents.is_empty():
		_fail("Remote withdrawal mutated collection")
		return
	if not inv.vault_withdraw(0,false) or inv.contents[0]!=item or item.cosmetic_snapshot()!=identity or item.all_stats()!=stats or not item.collector_locked or item.exhibition_slot!=-1:
		_fail("Transfer changed identity, protection or display")
		return
	modal.free()
	inv.free()
	town.free()
	print("v1.93 PASS: original town scene, reciprocal routes, physical stash, transfer access and item invariants")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
