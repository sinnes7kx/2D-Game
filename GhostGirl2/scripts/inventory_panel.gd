extends PanelContainer
signal item_hovered(item: Variant, equipped: Variant)
signal item_hover_cleared
signal cursor_pick_requested(index: int)
signal inspect_requested(item: GhostItemInstance)
signal vault_requested(item: GhostItemInstance)
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
var cosmetic_radio_panel: ScrollContainer
var cosmetic_radio_options: Array[Dictionary] = []
var eye_editor: ScrollContainer
var eye_choices: Array[Dictionary] = []
var last_recovery_notice: String = ""
@onready var inspect_button: Button = $Layout/Actions/InspectSelected
@onready var slots: Control = $Layout/SlotsWell/Slots
@onready var description: RichTextLabel = $Layout/DetailsWell/DetailsVBox/ItemDescription
@onready var seed_row: HBoxContainer = $Layout/DetailsWell/DetailsVBox/SeedRow
@onready var seed_display: TextureRect = $Layout/DetailsWell/DetailsVBox/SeedRow/SeedDisplay
@onready var saved_seeds: OptionButton = $Layout/DetailsWell/DetailsVBox/SeedRow/SavedSeeds
var test_mythic: OptionButton
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
	$Layout/Header/VaultButton.pressed.connect(func() -> void: vault_requested.emit(selected_weapon_for_inspection()))
	socket_button.pressed.connect(_select_socket)
	destroy_button.pressed.connect(_request_delete)
	$Layout/DetailsWell/DetailsVBox/SeedRow/RerollSeed.pressed.connect(_reroll_selected_seed)
	$Layout/DetailsWell/DetailsVBox/SeedRow/SaveSeed.pressed.connect(_save_selected_seed)
	saved_seeds.item_selected.connect(_restore_selected_seed)
	# Upgrade older locally saved scenes before assigning the typed reference.
	test_mythic = _ensure_effect_dropdown()
	# Never surface the tester in release exports.
	test_mythic.hide()
	if OS.is_debug_build():
		test_looks = test_mythic
		_setup_effect_menu()
		test_looks.item_selected.connect(_preview_look)
	$Layout/Actions/DropSelected.pressed.connect(_drop_selected)
	description.bbcode_enabled = true
	# The item information belongs in the hover popup / Collector's Lens.
	# Keep legacy scene nodes for old save/test compatibility, but show a
	# categorized preview lab in the freed panel instead of duplicate stats.
	$Layout/DetailsHeader.hide()
	description.hide()
	_create_cosmetic_radio_panel()
	_create_eye_editor()
	var details_well: PanelContainer = $Layout/DetailsWell
	if OS.is_debug_build():
		details_well.custom_minimum_size = Vector2(0, 196)
	else:
		# Release inventories show only reroll / saved looks here.
		details_well.custom_minimum_size = Vector2(0, 42)
		details_well.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	confirmation.confirmed.connect(_confirm_delete)
	confirmation.canceled.connect(_cancel_delete)
	_clear()

# Older project copies can still have a Button at the same scene path.
# Replace only that control at runtime, preserving its layout. A valid
# OptionButton is reused unchanged; no scene or save is written to disk.
func _ensure_effect_dropdown() -> OptionButton:
	var header: Control = $Layout/DetailsHeader
	var old: Node = header.get_node_or_null("TestMythic")
	if old is OptionButton:
		return old as OptionButton
	var dropdown: OptionButton = OptionButton.new()
	dropdown.name = "TestMythic"
	dropdown.add_theme_font_size_override("font_size", 12)
	dropdown.tooltip_text = "Debug build only: select visual effects. Nothing is saved."
	dropdown.hide()
	var index: int = header.get_child_count()
	if old != null:
		index = old.get_index()
		if old is Control:
			var control: Control = old as Control
			dropdown.custom_minimum_size = control.custom_minimum_size
			dropdown.size_flags_horizontal = control.size_flags_horizontal
			dropdown.size_flags_vertical = control.size_flags_vertical
			dropdown.size_flags_stretch_ratio = control.size_flags_stretch_ratio
			dropdown.theme = control.theme
			dropdown.focus_mode = control.focus_mode
		header.remove_child(old)
		old.queue_free()
	header.add_child(dropdown)
	header.move_child(dropdown, index)
	return dropdown

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
	var recovery: String = inventory.recovery_notice()
	page_number.tooltip_text = recovery
	if not recovery.is_empty():
		notice.text = recovery
	elif not last_recovery_notice.is_empty() and notice.text == last_recovery_notice:
		notice.text = ""
	last_recovery_notice = recovery

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
	_refresh_cosmetic_radio_panel(item)
	_refresh_eye_editor(item)
	$Layout/DetailsWell.custom_minimum_size.y = 226.0 if _is_eye_item(item) else (196.0 if OS.is_debug_build() else 42.0)
	test_mythic.visible = OS.is_debug_build()
	if test_mythic.visible:
		_update_effect_compatibility(item)
		test_mythic.select(0)
	# Details remain compact; the side-by-side floating compare popup owns long
	# affix differences and never participates in VBox layout calculations.
	var worn: Variant = inventory.get_equipped(item.get_slot()) if item.get_slot() != "none" else null
	if worn != null and worn != item:
		description.text += "\n[font_size=12][color=#c8a98a]HOLD CTRL WHILE HOVERING TO COMPARE[/color][/font_size]"
	inspect_button.visible = true
	equip_button.visible = item.get_slot() != "none"
	if equip_button.visible:
		var equipped: bool = inventory.equipped_index(item.get_slot()) == index
		equip_button.text = "EQUIPPED" if equipped else "EQUIP"
		equip_button.disabled = equipped or item.is_broken()
		if item.is_broken():
			equip_button.text = "BROKEN"
	socket_button.visible = item.get_slot() != "none" and item.sockets > item.socketed.size()
	if socket_button.visible:
		socket_button.text = "SELECT GEM OR RUNE" if pending_gear_index < 0 else "CHOOSE A GEM / RUNE"
	destroy_button.visible = true
	$Layout/Actions/DropSelected.visible = true
	$Layout/Actions/DropSelected.disabled = not inventory.can_drop(index)
	destroy_button.disabled = not inventory.can_destroy(index)
	destroy_button.tooltip_text = "Protected item" if item.collector_locked else ("Unequip first; quest items cannot be destroyed" if destroy_button.disabled else "Permanently destroy selected item")

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
	if is_instance_valid(cosmetic_radio_panel):
		cosmetic_radio_panel.hide()
	if is_instance_valid(eye_editor):
		eye_editor.hide()
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


# Real user personalization of owned luminous eyes. These values are
# separate from the genuine UID, original rarity, loot seed and stats.
static func _is_eye_item(item: GhostItemInstance) -> bool:
	return item != null and item.definition != null and str(item.definition.item_id) == "v202_luminous_eyes"

func _create_eye_editor() -> void:
	var host: VBoxContainer = $Layout/DetailsWell/DetailsVBox
	eye_editor = ScrollContainer.new()
	eye_editor.name = "EyeStyleEditorV215"
	eye_editor.custom_minimum_size = Vector2(0, 142)
	eye_editor.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	host.add_child(eye_editor)
	host.move_child(eye_editor, 0)
	var content: VBoxContainer = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	eye_editor.add_child(content)
	var intro: Label = Label.new()
	intro.text = "EYES · YOUR STYLE (saved separately from rarity)"
	intro.add_theme_font_size_override("font_size", 12)
	content.add_child(intro)
	for section in [
		{"key": "shape", "title": "Shape", "labels": ["Original", "Moonveil", "Cathedral", "Starborn", "Hollow"]},
		{"key": "palette", "title": "Color", "labels": ["Original", "Violet", "Rose", "Moonblue", "Jade", "Gold", "Ash"]}
	]:
		var heading: Label = Label.new()
		heading.text = str(section["title"])
		heading.add_theme_font_size_override("font_size", 12)
		content.add_child(heading)
		var group: ButtonGroup = ButtonGroup.new()
		var choices_grid: GridContainer = GridContainer.new()
		choices_grid.columns = 3
		choices_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		content.add_child(choices_grid)
		var labels: Array = section["labels"]
		for n in range(labels.size()):
			var option: CheckBox = CheckBox.new()
			option.text = str(labels[n])
			option.button_group = group
			option.add_theme_font_size_override("font_size", 11)
			choices_grid.add_child(option)
			option.toggled.connect(_set_eye_choice.bind(str(section["key"]), n - 1))
			eye_choices.append({"button": option, "category": str(section["key"]), "value": n - 1})
	eye_editor.hide()

func _refresh_eye_editor(item: GhostItemInstance) -> void:
	if not is_instance_valid(eye_editor):
		return
	eye_editor.visible = _is_eye_item(item)
	if not eye_editor.visible:
		return
	for choice in eye_choices:
		var option: CheckBox = choice["button"]
		var current: int = item.eye_style_override if str(choice["category"]) == "shape" else item.eye_palette_override
		option.set_pressed_no_signal(current == int(choice["value"]))

func _set_eye_choice(pressed: bool, category: String, value: int) -> void:
	if not pressed:
		return
	var item: GhostItemInstance = _selected_cosmetic_item()
	if not _is_eye_item(item):
		return
	if category == "shape":
		item.eye_style_override = clampi(value, -1, 3)
	else:
		item.eye_palette_override = clampi(value, -1, 5)
	inventory.save_game()
	inventory.contents_changed.emit()
	inventory.equipment_changed.emit()
	notice.text = "Eye style saved · original rarity unchanged"

func focus_eye_item(item: GhostItemInstance) -> void:
	if inventory == null or not _is_eye_item(item):
		return
	var index: int = inventory.contents.find(item)
	if index < 0:
		return
	# Equipment stays equipped: this is selection only, no item transfer.
	selected_index = index
	var grid_position: Vector2i = inventory.grid_positions[index] if index < inventory.grid_positions.size() else Vector2i.ZERO
	active_page = clampi(grid_position.y / inventory.GRID_ROWS, 0, inventory.GRID_PAGES - 1)
	slots.call("set_page", active_page)
	page_number.text = "%d / 8" % (active_page + 1)
	refresh()

# Preview categories use the existing TEST ONLY IDs and debug overrides.
# Nothing in these radio controls writes a cosmetic UID or stat roll.
func _create_cosmetic_radio_panel() -> void:
	var host: VBoxContainer = $Layout/DetailsWell/DetailsVBox
	cosmetic_radio_panel = ScrollContainer.new()
	cosmetic_radio_panel.name = "CosmeticLayersV210"
	cosmetic_radio_panel.custom_minimum_size = Vector2(0, 168)
	cosmetic_radio_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cosmetic_radio_panel.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	host.add_child(cosmetic_radio_panel)
	host.move_child(cosmetic_radio_panel, 0)
	var categories: VBoxContainer = VBoxContainer.new()
	categories.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cosmetic_radio_panel.add_child(categories)
	var label: Label = Label.new()
	label.text = "COSMETIC LAYERS · PREVIEW ONLY, NOT SAVED"
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("d8bcdb"))
	categories.add_child(label)
	var sections: Array[Dictionary] = [
		{"name": "Signature", "ids": [10, 11, 12, 13, 14, 15], "labels": ["None", "Thorns", "Eclipse", "Seraph", "Mythic", "Moonfall"]},
		{"name": "Mythic detail", "ids": [20, 21, 22, 23], "labels": ["Lightning", "Cinders", "Astral", "Petals"]},
		{"name": "Material rarity", "ids": [30, 31, 32, 33, 34, 35, 36], "labels": ["Standard", "Unusual", "Enchanted", "Animated", "Celestial", "Ethereal", "Anomaly"]},
		{"name": "Color motion", "ids": [40, 41, 42, 43, 44, 45, 46], "labels": ["Still", "Pulse", "Drift", "Iridescent", "Phase", "Moonwash", "Prism"]},
		{"name": "Glow shape", "ids": [50, 51, 52, 53, 54, 55, 56, 57], "labels": ["Motes", "Bars", "Petals", "Zigzag", "Arcs", "Comets", "Stars", "Wisps"]},
		{"name": "Surface", "ids": [60, 61, 62, 63, 64, 65, 66], "labels": ["Plain", "Ripple", "Living", "Flare", "Flow", "Spark", "Anomaly"]},
		{"name": "Guard shape", "ids": [70, 71, 72, 73, 74, 75, 76, 77], "labels": ["Straight", "Back", "Forward", "Winged", "Scroll", "Diamond", "Thorn", "Beaded"]},
		{"name": "Grip style", "ids": [80, 81, 82, 83, 84, 85], "labels": ["Leather", "Metal", "Silk", "Inlaid", "Riveted", "Carved"]}
	]
	for section in sections:
		var heading: Label = Label.new()
		heading.text = str(section["name"])
		heading.add_theme_font_size_override("font_size", 12)
		heading.add_theme_color_override("font_color", Color("d9b899"))
		categories.add_child(heading)
		var group: ButtonGroup = ButtonGroup.new()
		var grid: GridContainer = GridContainer.new()
		grid.columns = 3
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		categories.add_child(grid)
		var natural: CheckBox = CheckBox.new()
		natural.text = "Natural"
		natural.button_group = group
		natural.add_theme_font_size_override("font_size", 11)
		grid.add_child(natural)
		natural.set_pressed_no_signal(true)
		natural.toggled.connect(_radio_natural.bind(str(section["name"])))
		cosmetic_radio_options.append({"button": natural, "id": -1, "category": str(section["name"])})
		var ids: Array = section["ids"]
		var labels: Array = section["labels"]
		for i in range(ids.size()):
			var radio: CheckBox = CheckBox.new()
			radio.text = str(labels[i])
			radio.button_group = group
			radio.add_theme_font_size_override("font_size", 11)
			grid.add_child(radio)
			var id: int = int(ids[i])
			radio.toggled.connect(_radio_preview.bind(id))
			cosmetic_radio_options.append({"button": radio, "id": id, "category": str(section["name"])})
	cosmetic_radio_panel.visible = OS.is_debug_build()

func _refresh_cosmetic_radio_panel(item: GhostItemInstance) -> void:
	if not is_instance_valid(cosmetic_radio_panel):
		return
	cosmetic_radio_panel.visible = OS.is_debug_build() and item != null and not _is_eye_item(item)
	if not cosmetic_radio_panel.visible:
		return
	var active: Dictionary = {
		"Signature": 10 + item.debug_visual_override if item.debug_visual_override >= 0 else -1,
		"Mythic detail": 20 + item.debug_mythic_variant if item.debug_mythic_variant >= 0 else -1,
		"Material rarity": 30 + item.debug_collector_tier if item.debug_collector_tier >= 0 else -1,
		"Color motion": 40 + item.debug_color_mode if item.debug_color_mode >= 0 else -1,
		"Glow shape": 50 + item.debug_glow_motif if item.debug_glow_motif >= 0 else -1,
		"Surface": 60 + item.debug_surface_mode if item.debug_surface_mode >= 0 else -1,
		"Guard shape": 70 + item.debug_forge_guard if item.debug_forge_guard >= 0 else -1,
		"Grip style": 80 + item.debug_forge_grip if item.debug_forge_grip >= 0 else -1
	}
	for choice in cosmetic_radio_options:
		var button: CheckBox = choice["button"]
		var id: int = int(choice["id"])
		var category: String = str(choice["category"])
		if id >= 0:
			var support: Dictionary = _effect_support(item, id)
			button.disabled = not bool(support["enabled"])
			button.tooltip_text = "Test effect only · not saved" if not button.disabled else "Not supported on this item"
		else:
			button.disabled = false
		button.set_pressed_no_signal(id == int(active.get(category, -1)))

func _radio_preview(pressed: bool, id: int) -> void:
	if not pressed or not OS.is_debug_build() or not is_instance_valid(test_looks):
		return
	var index: int = test_looks.get_item_index(id)
	if index >= 0:
		_preview_look(index)

func _radio_natural(pressed: bool, category: String) -> void:
	if not pressed or not OS.is_debug_build():
		return
	var item: GhostItemInstance = _selected_cosmetic_item()
	if item == null:
		return
	match category:
		"Signature": item.debug_visual_override = -1
		"Mythic detail": item.debug_mythic_variant = -1
		"Material rarity": item.debug_collector_tier = -1
		"Color motion": item.debug_color_mode = -1
		"Glow shape": item.debug_glow_motif = -1
		"Surface": item.debug_surface_mode = -1
		"Guard shape": item.debug_forge_guard = -1
		"Grip style": item.debug_forge_grip = -1
	inventory.contents_changed.emit()
	inventory.equipment_changed.emit()
	notice.text = "Natural " + category.to_lower() + " · preview only"

func _setup_effect_menu() -> void:
	test_looks.clear()
	test_looks.add_item("TEST EFFECTS", 0)
	test_looks.add_item("Clear all previews", 1)
	test_looks.add_separator("Signatures · weapons / inspect")
	for i in range(6):
		test_looks.add_item(["No signature", "Aether Thorns", "Void Eclipse", "Astral Seraph", "Mythic Radiance", "Moonfall Halo"][i], 10 + i)
	test_looks.add_separator("Mythic · forces signature")
	for i in range(4):
		test_looks.add_item(["Lightning arcs", "Cinder motes", "Astral pulses", "Spectral petals"][i], 20 + i)
	test_looks.add_separator("Appearance rarity · not stats")
	for i in range(7):
		test_looks.add_item(["Standard", "Unusual", "Enchanted", "Animated", "Celestial", "Ethereal", "Anomaly"][i], 30 + i)
	test_looks.add_separator("Color motion · glow")
	for i in range(7):
		test_looks.add_item(["Static", "Pulse", "Drift", "Iridescent", "Phase", "Moonwash", "Prism"][i], 40 + i)
	test_looks.add_separator("Glow shapes · weapons / inspect")
	for i in range(8):
		test_looks.add_item(["Motes", "Crossbars", "Petals", "Zigzag", "Arcs", "Comets", "Stars", "Wisps"][i], 50 + i)
	test_looks.add_separator("Surface · supported weapon art")
	for i in range(7):
		test_looks.add_item(preload("res://scripts/living_metal_v187.gd").LABELS[i], 60 + i)
	test_looks.add_separator("Guard · modular blades")
	for i in range(8):
		test_looks.add_item(["Straight", "Swept back", "Swept forward", "Winged", "Scroll", "Diamond", "Thorn", "Beaded"][i], 70 + i)
	test_looks.add_separator("Grip · modular weapons")
	for i in range(6):
		test_looks.add_item(["Leather wrap", "Metal collars", "Silk lacing", "Inlaid", "Riveted", "Carved"][i], 80 + i)
	test_looks.select(0)

func _preview_look(index: int) -> void:
	if not OS.is_debug_build():
		return
	var item: GhostItemInstance = selected_item_for_inspection()
	if item == null:
		return
	var id: int = test_looks.get_item_id(index)
	if test_looks.is_item_disabled(index):
		notice.text = "Not supported on this item. See TEST EFFECTS tooltips."
		test_looks.select(0)
		return
	if id == 1:
		item.debug_visual_override = -1
		item.debug_mythic_variant = -1
		item.debug_collector_tier = -1
		item.debug_color_mode = -1
		item.debug_glow_motif = -1
		item.debug_surface_mode = -1
		item.debug_forge_guard = -1
		item.debug_forge_grip = -1
	elif id >= 10 and id <= 15:
		item.debug_visual_override = id - 10
		item.debug_mythic_variant = -1
	elif id >= 20 and id <= 23:
		item.debug_visual_override = 4
		item.debug_mythic_variant = id - 20
	elif id >= 30 and id <= 36:
		item.debug_collector_tier = id - 30
	elif id >= 40 and id <= 46:
		item.debug_color_mode = id - 40
	elif id >= 50 and id <= 57:
		item.debug_glow_motif = id - 50
	elif id >= 60 and id <= 66:
		if item.get_slot() not in ["sword", "wand"]:
			notice.text = "Surface preview requires a supported weapon"
			test_looks.select(0)
			return
		item.debug_surface_mode = id - 60
	elif id >= 70 and id <= 77:
		item.debug_forge_guard = id - 70
	elif id >= 80 and id <= 85:
		item.debug_forge_grip = id - 80
	else:
		return
	var chosen: String = test_looks.get_item_text(index)
	test_looks.select(0)
	inventory.contents_changed.emit()
	inventory.equipment_changed.emit()
	var equipped: bool = inventory.get_equipped(item.get_slot()) == item if item.get_slot() != "none" else false
	notice.text = "TEST ONLY · " + chosen + (" · EQUIPPED" if equipped else " · INSPECT / EQUIP FIRST") + " · NOT SAVED"

func selected_item_for_inspection() -> GhostItemInstance:
	if inventory == null or selected_index < 0:
		return null
	return inventory.get_item(selected_index)

func selected_weapon_for_inspection() -> GhostItemInstance:
	var item: GhostItemInstance = _selected_cosmetic_item()
	return item if item != null and item.get_slot() in ["sword", "wand"] else null

func _inspect_selected() -> void:
	var item: GhostItemInstance = selected_item_for_inspection()
	if item != null:
		inspect_requested.emit(item)

# Explain dependencies without requiring a particular natural rarity. Debug
# previews bypass natural rarity requirements but never grant actual stats.
func _effect_support(item: GhostItemInstance, id: int) -> Dictionary:
	if item == null or id <= 1:
		return {"enabled": true, "hint": "Restore the item's genuine appearance; all temporary overrides cleared."}
	var slot: String = item.get_slot()
	var weapon: bool = slot in ["sword", "wand"]
	var style: String = item.weapon_style()
	var ident: String = str(item.definition.item_id) if item.definition != null else ""
	var modular_blade: bool = style in ["twinblade", "dual_sword", "dual_dagger", "halberd"] or ident in ["nocturne_stiletto_v171", "moonwarden_spear_v169", "briarwake_trident_v171"]
	var attack_only: bool = style in ["dagger", "spear"]
	var grip: bool = modular_blade or style in ["scythe", "maul"]
	var painted: bool = style == "bow" or slot == "wand"
	var inspect_surface: bool = grip or attack_only or painted
	var equipped: bool = slot != "none" and inventory != null and inventory.get_equipped(slot) == item
	var context: String = " Equipped: compare live character and world." if equipped else " Inspect this item, or equip it to see supported held effects."
	if id >= 10 and id <= 15:
		return {"enabled": true, "hint": ("Weapon signature; no natural rarity required in debug." if weapon else ("Dress aura for Mythic/Moonfall; other signatures in Inspect." if slot == "dress" else "Inspect preview; accessories have limited in-world effects.")) + " Anomaly rarity can override the signature shape." + context}
	if id >= 20 and id <= 23:
		return {"enabled": true, "hint": ("Forces Mythic signature automatically. Anomaly takes precedence; clear previews first if needed." if weapon else "Forces Mythic for inspection; only supported accessory/dress auras appear in-world.") + context}
	if id >= 30 and id <= 36:
		return {"enabled": true, "hint": ("Changes material/particle tier only. Ethereal here is cosmetic, not the transparent durability condition. Anomaly adds fracture motion." if weapon else "Inspection-only cosmetic tier, not item quality or durability.") + context}
	if id >= 40 and id <= 46:
		return {"enabled": true, "hint": ("Changes the existing seeded glow palette motion. Anomaly always animates. FX slider must be above 0%." if weapon else "Inspection glow motion; not a fabric dye.") + context}
	if id >= 50 and id <= 57:
		return {"enabled": true, "hint": ("Changes the moving accents; use FX above 0%. Bow/wand masks use a related painted shimmer." if weapon else "Inspection motif; does not change the actual accessory art.") + context}
	if id >= 60 and id <= 66:
		return {"enabled": inspect_surface, "hint": ("Modular steel and bow/wand masks; legacy dagger/spear may be inspect or attack only. FX above 0%." + context) if inspect_surface else "Unsupported: this item has baked art without a living material surface."}
	if id >= 70 and id <= 77:
		return {"enabled": modular_blade or attack_only, "hint": ("Actual crossguard on modular blades; some dagger/spear models use modular geometry only during attacks or inspection." + context) if modular_blade or attack_only else "Unsupported: bows, wands, mauls, scythes and baked swords have no modular crossguard."}
	if id >= 80 and id <= 85:
		return {"enabled": grip or attack_only, "hint": ("Wrapped handle on modular weapons; some dagger/spear models are inspect or attack only." + context) if grip or attack_only else "Unsupported: this item does not have a modular grip."}
	return {"enabled": true, "hint": ""}

func _update_effect_compatibility(item: GhostItemInstance) -> void:
	if not is_instance_valid(test_looks):
		return
	var popup: PopupMenu = test_looks.get_popup()
	for i in range(test_looks.item_count):
		if popup.is_item_separator(i):
			continue
		var id: int = test_looks.get_item_id(i)
		var support: Dictionary = _effect_support(item, id)
		test_looks.set_item_disabled(i, not bool(support["enabled"]))
		popup.set_item_tooltip(i, str(support["hint"]))
	var slot: String = item.get_slot()
	var equipped: bool = slot != "none" and inventory.get_equipped(slot) == item
	test_looks.tooltip_text = ("Testing equipped " if equipped else "Testing selected ") + item.display_name() + ". Disabled choices are unsupported. Hover a choice for requirements. Debug only; never saved."
