extends PanelContainer
signal item_hovered(item: Variant, equipped: Variant)
signal item_hover_cleared
signal cursor_pick_requested(index: int)
signal inspect_requested(item: GhostItemInstance)
signal cursor_place_requested(page: int, col: int, row: int)
signal cursor_cancel_requested
signal cursor_drop_requested(index: int)
const ITEM_MARKUP = preload("res://scripts/item_rich_text.gd")
## Spatial 10x4 D2-style backpack, 8 pages; all item indices stay save-compatible.
## Right-click to equip; drag to move; socketing and destruction use explicit actions.
var inventory
var selected_index: int = -1
var selected_alt_down: bool = false
var pending_gear_index: int = -1
var active_page: int = 0
var pending_delete_item: Variant = null
var test_looks: OptionButton
@onready var inspect_button: Button = $Layout/Actions/InspectSelected
@onready var slots: Control = $Layout/SlotsWell/Slots
@onready var description: RichTextLabel = $Layout/DetailsWell/DetailsVBox/ItemDescription
@onready var seed_row: HBoxContainer = $Layout/DetailsWell/DetailsVBox/SeedRow
@onready var seed_display: TextureRect = $Layout/DetailsWell/DetailsVBox/SeedRow/SeedDisplay
@onready var saved_seeds: OptionButton = $Layout/DetailsWell/DetailsVBox/SeedRow/SavedSeeds
@onready var test_mythic: Button = $Layout/DetailsHeader/TestMythic
@onready var equip_button: Button = $Layout/Actions/EquipSelected
@onready var socket_button: Button = $Layout/Actions/SocketSelected
@onready var destroy_button: Button = $Layout/Actions/DestroySelected
@onready var confirmation: ConfirmationDialog = $DestroyConfirm
@onready var notice: Label = $Layout/InventoryNotice
@onready var page_number: Label = $Layout/Header/PageNumber

func _ready() -> void:
	visible = false
	slots.connect("item_pick_requested", Callable(self, "_on_pick_request"))
	slots.connect("item_place_requested", Callable(self, "_on_place_request"))
	slots.connect("item_cancel_requested", Callable(self, "_on_cancel_cursor"))
	slots.connect("item_activated", Callable(self, "_on_activate_item"))
	slots.connect("item_hovered", Callable(self, "_on_slot_hovered"))
	$Layout/Header/PreviousPage.pressed.connect(_change_page.bind(-1))
	$Layout/Header/NextPage.pressed.connect(_change_page.bind(1))
	$Layout/Header/SortBackpack.pressed.connect(_sort_backpack)
	equip_button.pressed.connect(_equip)
	inspect_button.pressed.connect(_inspect_selected)
	socket_button.pressed.connect(_select_socket)
	destroy_button.pressed.connect(_request_delete)
	$Layout/DetailsWell/DetailsVBox/SeedRow/RerollSeed.pressed.connect(_reroll_selected_seed)
	$Layout/DetailsWell/DetailsVBox/SeedRow/SaveSeed.pressed.connect(_save_selected_seed)
	saved_seeds.item_selected.connect(_restore_selected_seed)
	# Never surface the tester in release exports.
	test_mythic.visible = false
	if OS.is_debug_build():
		test_mythic.pressed.connect(_toggle_mythic_preview)
		test_looks = OptionButton.new()
		test_looks.add_theme_font_size_override("font_size", 12)
		$Layout/DetailsHeader.add_child(test_looks)
		for label in ["TEST LOOKS", "Clear previews", "Anomaly", "Standard", "Unusual", "Enchanted", "Animated", "Celestial", "Ethereal", "Next color mode", "Next glow motif"]:
			test_looks.add_item(label)
		test_looks.item_selected.connect(_preview_look)
		test_looks.hide()
	$Layout/Actions/DropSelected.pressed.connect(_drop_selected)
	description.bbcode_enabled = true
	confirmation.confirmed.connect(_confirm_delete)
	confirmation.canceled.connect(_cancel_delete)
	_clear()

func _process(_delta: float) -> void:
	if not visible or inventory == null or selected_index < 0:
		return
	var new_alt: bool = Input.is_key_pressed(KEY_ALT)
	if selected_alt_down != new_alt:
		_show_details(selected_index)

func bind_inventory(value: Node) -> void:
	inventory = value
	slots.call("setup", value)
	if not inventory.contents_changed.is_connected(refresh):
		inventory.contents_changed.connect(refresh)
	refresh()

func toggle() -> void:
	visible = not visible
	if visible:
		refresh()
	else:
		pending_gear_index = -1

func set_cursor_item(index: int) -> void:
	slots.call("set_cursor_item", index)

func _on_pick_request(index: int) -> void:
	if inventory == null:
		return
	var item: Variant = inventory.get_item(index)
	if item == null:
		return
	if pending_gear_index >= 0 and item.definition.item_class in ["gem", "rune"]:
		_on_slot_pressed(index)
		return
	_on_slot_pressed(index)
	cursor_pick_requested.emit(index)

func _on_place_request(page: int, col: int, row: int) -> void:
	cursor_place_requested.emit(page, col, row)

func _on_cancel_cursor() -> void:
	cursor_cancel_requested.emit()

func _drop_selected() -> void:
	if selected_index >= 0:
		cursor_drop_requested.emit(selected_index)

func _change_page(direction: int) -> void:
	active_page = clampi(active_page + direction, 0, 7)
	slots.call("set_page", active_page)
	page_number.text = "%d / 8" % (active_page + 1)
	_clear()
	refresh()

func _sort_backpack() -> void:
	if inventory == null:
		return
	cursor_cancel_requested.emit()
	if inventory.sort_backpack():
		notice.text = "Backpack organized — equipped items unchanged"
		slots.call("set_page", 0)
		active_page = 0
		page_number.text = "1 / 8"
		_clear()
		refresh()
	else:
		notice.text = "Cannot fit every item; original layout preserved"

func refresh() -> void:
	if inventory == null or not is_node_ready():
		return
	slots.call("set_selected", selected_index)
	slots.queue_redraw()
	if selected_index >= 0 and inventory.get_item(selected_index) != null:
		_show_details(selected_index)
	else:
		_clear()

func _on_slot_pressed(index: int) -> void:
	var item: Variant = inventory.get_item(index)
	if item == null:
		return
	if pending_gear_index >= 0 and item.definition.item_class in ["gem", "rune"]:
		var gear: Variant = inventory.get_item(pending_gear_index)
		var socketed_name: String = str(item.definition.display_name)
		var gear_name: String = str(gear.display_name()) if gear != null else "equipment"
		if inventory.socket_at(pending_gear_index, index):
			pending_gear_index = -1
			_clear()
			refresh()
			notice.text = "%s socketed into %s" % [socketed_name, gear_name]
		return
	selected_index = index
	slots.call("set_selected", index)
	_show_details(index)

func _on_activate_item(index: int) -> void:
	if inventory == null:
		return
	_on_slot_pressed(index)
	var item: Variant = inventory.get_item(index)
	if item != null and item.get_slot() != "none":
		inventory.equip_at(index)
		refresh()

func _on_move_item(index: int, page: int, col: int, row: int) -> void:
	if inventory.move_item_at(index, page, col, row):
		notice.text = "Item moved"
	else:
		notice.text = "Not enough free space at that position"
	slots.queue_redraw()

func _show_details(index: int) -> void:
	var item: Variant = inventory.get_item(index)
	if item == null:
		_clear()
		return
	selected_alt_down = Input.is_key_pressed(KEY_ALT)
	var is_named_jewel: bool = item.definition.unique and str(item.definition.item_class) in ["gem", "rune"]
	var title_ink: String = "#dfc38e" if is_named_jewel else ITEM_MARKUP.color_to_tag(item.quality_color())
	description.text = "[font_size=19][color=%s]%s[/color][/font_size]\n" % [title_ink, ITEM_MARKUP.escape(item.display_name())] + ITEM_MARKUP.item_info(item, selected_alt_down)
	description.scroll_to_line(0)
	_refresh_seed_controls(item)
	test_mythic.visible = OS.is_debug_build() and item.get_slot() != "none"
	if is_instance_valid(test_looks):
		test_looks.visible = item.get_slot() in ["sword", "wand"]
	if test_mythic.visible:
		test_mythic.text = "CLEAR MYTHIC TEST" if item.debug_visual_override == 4 else "PLAYTEST · MYTHIC"
	# Details remain compact; the side-by-side floating compare popup owns long
	# affix differences and never participates in VBox layout calculations.
	var worn: Variant = inventory.get_equipped(item.get_slot()) if item.get_slot() != "none" else null
	if worn != null and worn != item:
		description.text += "\n[font_size=12][color=#c8a98a]HOLD CTRL WHILE HOVERING TO COMPARE[/color][/font_size]"
	inspect_button.visible = item.get_slot() in ["sword", "wand"]
	equip_button.visible = item.get_slot() != "none"
	if equip_button.visible:
		var equipped: bool = inventory.equipped_index(item.get_slot()) == index
		equip_button.text = "EQUIPPED" if equipped else "EQUIP"
		equip_button.disabled = equipped
	socket_button.visible = item.get_slot() != "none" and item.sockets > item.socketed.size()
	if socket_button.visible:
		socket_button.text = "SELECT GEM OR RUNE" if pending_gear_index < 0 else "CHOOSE A GEM / RUNE"
	destroy_button.visible = true
	$Layout/Actions/DropSelected.visible = true
	destroy_button.disabled = not inventory.can_destroy(index)
	destroy_button.tooltip_text = "Unequip first; quest items cannot be destroyed" if destroy_button.disabled else "Permanently destroy selected item"

func _appearance_colors(item: GhostItemInstance, look: Dictionary) -> Array[Color]:
	# Saved full-spectrum colors are derived from THAT look's UID, not the
	# currently equipped look or an old fixed six-color palette.
	if item.get_slot() in ["sword", "wand"]:
		var uid: String = str(look.get("cosmetic_uid", ""))
		if GhostCosmeticRNGV152.is_valid_uid(uid):
			var saved_seed: int = int(look.get("cosmetic_seed", look.get("seed", item.visual_seed())))
			return GhostCosmeticRNGV152.gradient_for_channel(uid, saved_seed, "bow-limbs") if item.weapon_style() == "bow" else GhostCosmeticRNGV152.gradient_colors(uid, saved_seed)
	var main: Color = GhostPaletteLibrary.color_for_slot(item.get_slot(), int(look.get("palette_index", item.palette_index)))
	var middle: Color = main
	var accent: Color = main.lightened(0.3)
	var look_seed: int = int(look.get("seed", item.visual_seed()))
	var fx_fallback: Dictionary = GhostWeaponFXLibrary.roll(look_seed, item.quality)
	var accent_roll: int = int(look.get("weapon_fx_accent_index", item.weapon_fx_accent_index))
	if accent_roll < 0:
		accent_roll = int(fx_fallback["accent"])
	if item.get_slot() == "sword":
		var base_roll: int = int(look.get("weapon_base_index", item.weapon_base_index))
		if base_roll < 0:
			base_roll = int(look.get("palette_index", item.palette_index))
		main = GhostPaletteLibrary.color_for_slot("sword", base_roll)
		middle = GhostPaletteLibrary.weapon_gradient_color(int(look.get("weapon_gradient_index", item.weapon_gradient_index)))
		accent = GhostWeaponFXLibrary.color(accent_roll)
		if item.weapon_style() == "bow":
			var bow_roll: int = int(look.get("bow_element_index", item.bow_element_index))
			if bow_roll < 0:
				bow_roll = int(GhostBowImprintsV138.roll(look_seed, item.quality)["element"])
			main = GhostBowImprintsV138.color_for_element(bow_roll)
	elif item.get_slot() == "wand":
		var main_roll: int = int(look.get("weapon_fx_color_index", item.weapon_fx_color_index))
		if main_roll < 0:
			main_roll = int(fx_fallback["color"])
		main = GhostWeaponFXLibrary.color(main_roll)
		accent = GhostWeaponFXLibrary.color(accent_roll)
		middle = main.lerp(accent, 0.5)
	return [main, middle, accent]

func _appearance_swatch(item: GhostItemInstance, look: Dictionary) -> Texture2D:
	var colors: Array[Color] = _appearance_colors(item, look)
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, colors[0])
	gradient.set_color(1, colors[2])
	gradient.add_point(0.5, colors[1])
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.width = 54
	texture.height = 16
	texture.gradient = gradient
	return texture

func _mirrored_icon(item: GhostItemInstance, width: int = 14, height: int = 14) -> Texture2D:
	if item == null or item.definition == null or item.definition.icon == null:
		return null
	var img: Image = item.definition.icon.get_image()
	if img == null:
		return null
	img.flip_x()
	img.resize(width, height, Image.INTERPOLATE_LANCZOS)
	return ImageTexture.create_from_image(img)

func _look_signature(item: GhostItemInstance, look: Dictionary) -> int:
	if int(look.get("rare_visual_mod", -1)) >= 0:
		return int(look.get("rare_visual_mod", -1))
	return item.signature_of_saved_look(look)

func _appearance_preview(item: GhostItemInstance, look: Dictionary) -> Texture2D:
	var base_tex: Texture2D = _appearance_swatch(item, look)
	if _look_signature(item, look) not in [4, 5]:
		return base_tex
	# Build the rare swatch in memory instead of reading pixels from a
	# GradientTexture2D before Godot has uploaded that texture to the GPU.
	var colors: Array[Color] = _appearance_colors(item, look)
	var canvas: Image = Image.create(54, 16, false, Image.FORMAT_RGBA8)
	for x in range(54):
		var t: float = float(x) / 53.0
		var ink: Color = colors[0].lerp(colors[1], t * 2.0) if t <= 0.5 else colors[1].lerp(colors[2], (t - 0.5) * 2.0)
		for y in range(16):
			canvas.set_pixel(x, y, ink)
	var icon_tex: Texture2D = _mirrored_icon(item, 14, 14)
	if icon_tex != null:
		var icon_img: Image = icon_tex.get_image()
		if icon_img != null:
			canvas.blit_rect(icon_img, Rect2i(Vector2i.ZERO, icon_img.get_size()), Vector2i(39, 1))
	return ImageTexture.create_from_image(canvas)

func _refresh_seed_controls(item: Variant) -> void:
	seed_row.visible = item != null and item.get_slot() != "none"
	if not seed_row.visible:
		return
	var current_look: Dictionary = item.cosmetic_snapshot()
	if OS.is_debug_build() and item.debug_visual_override >= 0:
		current_look["rare_visual_mod"] = item.debug_visual_override
	seed_display.texture = _appearance_preview(item, current_look)
	saved_seeds.clear()
	saved_seeds.add_item("FAVORITES")
	saved_seeds.set_item_disabled(0, true)
	for look in item.saved_cosmetic_looks:
		# Icons preserve the true stored appearances, not just generic palette names.
		saved_seeds.add_item("★")
		saved_seeds.set_item_icon(saved_seeds.item_count - 1, _appearance_preview(item, look))
	saved_seeds.select(0)

func _selected_cosmetic_item() -> GhostItemInstance:
	if inventory == null or selected_index < 0:
		return null
	var item: GhostItemInstance = inventory.get_item(selected_index)
	return item if item != null and item.get_slot() != "none" else null

func _toggle_mythic_preview() -> void:
	if not OS.is_debug_build():
		return
	var item: GhostItemInstance = _selected_cosmetic_item()
	if item == null:
		return
	# No reroll, no save_game(), no mutation of rare_visual_mod, item_seed,
	# UID, item quality, affixes, stats or favorite snapshots.
	item.debug_visual_override = -1 if item.debug_visual_override == 4 else 4
	inventory.contents_changed.emit()
	inventory.equipment_changed.emit()
	_show_details(selected_index)
	notice.text = "MYTHIC PREVIEW · NOT SAVED" if item.debug_visual_override == 4 else "Mythic test cleared"

func _reroll_selected_seed() -> void:
	var item: GhostItemInstance = _selected_cosmetic_item()
	if item == null:
		return
	item.reroll_cosmetic_seed()
	inventory.save_game()
	inventory.contents_changed.emit()
	inventory.equipment_changed.emit()
	notice.text = "New colors · stats unchanged"
	_show_details(selected_index)

func _save_selected_seed() -> void:
	var item: GhostItemInstance = _selected_cosmetic_item()
	if item == null:
		return
	if item.save_cosmetic_look():
		inventory.save_game()
		notice.text = "Appearance saved ♥"
	else:
		notice.text = "16 saved looks maximum per item"
	_refresh_seed_controls(item)

func _restore_selected_seed(option_index: int) -> void:
	var item: GhostItemInstance = _selected_cosmetic_item()
	if item == null or option_index <= 0:
		return
	if item.restore_cosmetic_look(option_index - 1):
		inventory.save_game()
		inventory.contents_changed.emit()
		inventory.equipment_changed.emit()
		notice.text = "Favorite appearance restored"
		_show_details(selected_index)

func _equip() -> void:
	if selected_index >= 0 and inventory.equip_at(selected_index):
		refresh()

func _select_socket() -> void:
	pending_gear_index = selected_index
	notice.text = "Click a gem or rune on any backpack page to fill one socket"

func _request_delete() -> void:
	if inventory == null or not inventory.can_destroy(selected_index):
		notice.text = "Cannot destroy an equipped or quest item"
		return
	var item: Variant = inventory.get_item(selected_index)
	if item == null:
		return
	pending_delete_item = item
	confirmation.dialog_text = "Permanently destroy %s? This cannot be undone." % item.display_name()
	confirmation.popup_centered()

func _cancel_delete() -> void:
	pending_delete_item = null

func _confirm_delete() -> void:
	# Confirm the exact item displayed in the dialog, never whatever became
	# selected while the dialog was open.
	if inventory == null or pending_delete_item == null:
		return
	var idx: int = inventory.contents.find(pending_delete_item)
	pending_delete_item = null
	if idx < 0 or not inventory.destroy_item_at(idx):
		notice.text = "Could not destroy that item"
		return
	_clear()
	notice.text = "Item destroyed"
	refresh()

func _on_slot_hovered(index: int) -> void:
	if inventory == null or index < 0:
		item_hover_cleared.emit()
		return
	var item: Variant = inventory.get_item(index)
	if item == null:
		item_hover_cleared.emit()
		return
	var worn: Variant = inventory.get_equipped(item.get_slot()) if item.get_slot() != "none" else null
	item_hovered.emit(item, worn if worn != item else null)

func clear_selection() -> void:
	_clear()

func _clear() -> void:
	selected_index = -1
	if is_instance_valid(slots):
		slots.call("set_selected", -1)
	if is_instance_valid(seed_row):
		seed_row.visible = false
	if is_instance_valid(test_mythic):
		test_mythic.visible = false
	if is_instance_valid(test_looks):
		test_looks.hide()
	if is_instance_valid(description):
		description.text = "[font_size=15][color=#a99fae]HOVER for details  ·  ALT advanced  ·  CTRL compare  ·  CLICK to hold[/color][/font_size]"
	if is_instance_valid(inspect_button):
		inspect_button.hide()
	if is_instance_valid(equip_button):
		equip_button.visible = false
	if is_instance_valid(socket_button):
		socket_button.visible = false
	if is_instance_valid(destroy_button):
		destroy_button.visible = false
	if has_node("Layout/Actions/DropSelected"):
		$Layout/Actions/DropSelected.visible = false

func _local_stat_label(stat_id: String) -> String:
	match stat_id:
		"move_speed_pct": return "walking speed"
		"hook_range_pct": return "hook reach"
		"hook_pull_pct": return "hook pull"
		"throw_force_pct": return "throwing force"
		"spell_power_pct": return "spell power"
		"vitality_pct": return "vitality"
		"melee_power_pct": return "melee attack damage"
		"heavy_power_pct": return "heavy attack damage"
		"attack_speed_pct": return "attack speed"
		"stamina_efficiency_pct": return "reduced stamina costs"
		"poise_power_pct": return "poise breaking"
		"counter_damage_pct": return "backstep counter damage"
		"rally_power_pct": return "rally healing"
		"cast_speed_pct": return "wand casting speed"
		"charged_spell_pct": return "charged wand damage"
		"backstep_efficiency_pct": return "backstep efficiency"
		"stamina_recovery_pct": return "stamina regeneration"
		"find_bonus_pct": return "item discovery"
		_: return stat_id.replace("_", " ")

func _preview_look(index: int) -> void:
	if not OS.is_debug_build():
		return
	var item: GhostItemInstance = _selected_cosmetic_item()
	if item == null or item.get_slot() not in ["sword", "wand"]:
		return
	match index:
		1:
			item.debug_collector_tier = -1
			item.debug_color_mode = -1
			item.debug_glow_motif = -1
			item.debug_visual_override = -1
		2:
			item.debug_collector_tier = 6
			item.debug_color_mode = 6
		3, 4, 5, 6, 7, 8:
			item.debug_collector_tier = index - 3
		9:
			item.debug_color_mode = (int(item.collector_appearance().get("color_mode", 0)) + 1) % 7
		10:
			item.debug_glow_motif = (int(item.collector_appearance().get("glow_motif", 0)) + 1) % 8
		_:
			return
	test_looks.select(0)
	inventory.contents_changed.emit()
	inventory.equipment_changed.emit()
	notice.text = "TEST ONLY · %s · COLOR %d/7 · GLOW %d/8" % [item.collector_material_label(), int(item.collector_appearance().get("color_mode", 0)) + 1, int(item.collector_appearance().get("glow_motif", 0)) + 1]

func selected_weapon_for_inspection() -> GhostItemInstance:
	var item: GhostItemInstance = _selected_cosmetic_item()
	return item if item != null and item.get_slot() in ["sword", "wand"] else null

func _inspect_selected() -> void:
	var item: GhostItemInstance = selected_weapon_for_inspection()
	if item != null:
		inspect_requested.emit(item)
