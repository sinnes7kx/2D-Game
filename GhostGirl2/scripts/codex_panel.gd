extends PanelContainer
## Read-only Codex and reserved utility panels. No crafting or item mutation.
var inventory: Node
var heading: Label
var content: RichTextLabel

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	offset_left = -290.0
	offset_right = 290.0
	offset_top = -205.0
	offset_bottom = 205.0
	var frame: StyleBoxFlat = StyleBoxFlat.new()
	frame.bg_color = Color("201a25")
	frame.border_color = Color("96795c")
	frame.set_border_width_all(1)
	frame.set_content_margin_all(18.0)
	add_theme_stylebox_override("panel",frame)
	var stack: VBoxContainer = VBoxContainer.new()
	add_child(stack)
	var top: HBoxContainer = HBoxContainer.new()
	stack.add_child(top)
	heading = Label.new()
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_theme_color_override("font_color",Color("e0c29a"))
	heading.add_theme_font_size_override("font_size",22)
	top.add_child(heading)
	var close: Button = Button.new()
	close.text = "Close · Esc"
	close.pressed.connect(hide)
	top.add_child(close)
	var tabs: HBoxContainer = HBoxContainer.new()
	stack.add_child(tabs)
	for section in ["Discoveries","Effects","Combos"]:
		var button: Button = Button.new()
		button.text = section
		button.pressed.connect(show_section.bind(section))
		tabs.add_child(button)
	content = RichTextLabel.new()
	content.bbcode_enabled = false
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.custom_minimum_size = Vector2(0,270)
	content.add_theme_font_size_override("normal_font_size",16)
	stack.add_child(content)
	hide()

func show_section(section: String) -> void:
	heading.text = "Codex" if section in ["Discoveries","Effects","Combos"] else section
	match section:
		"Discoveries":
			var lines: Array[String] = ["RAREST ORIGINAL FINDS","Ordered by rarest cosmetic channel, then remaining channels. Not combined drop odds.",""]
			var entries: Array = inventory.get("codex_discoveries") if inventory != null else []
			if entries.is_empty():
				lines.append("New local finds will appear here. Earlier finds without a journal record are not retroactively certified.")
			for i in range(entries.size()):
				var entry: Dictionary = entries[i]
				lines.append("%d. %s · %s" % [i+1,str(entry.get("name","Unknown")),str(entry.get("origin","")).replace("_"," ").capitalize()])
				lines.append("    Original roll: "+str(entry.get("code","")))
			content.text = "\n".join(lines)
		"Effects":
			content.text = "WEAPON EFFECTS\n\nMaterial and particle rarity: independent seeded appearance channels.\nSignature: rare additional visual motif.\nGlow and palette: illumination, colors and motion.\nSurface: physical material finish.\nRegional imprint: where a find was born.\n\nCosmetic effects do not automatically increase damage. Owner-selected illumination and rerolls do not change the original discovery record. Inspect an item for its specific roll."
		"Combos":
			content.text = "COMBAT COMBINATIONS\n\nMouse1 × 3 — light attack chain.\nMouse1 × 2 → Mouse2 — heavy finisher.\nBackstep → Mouse2 — lunge during the follow-up window.\nConfirmed evade → attack — precision counter.\nJump → Mouse2 — aerial heavy attack.\nShift + Mouse2 — equipped unique skill, when available.\n\nWeapon type, stamina, timing and actual contact matter."
		"Reliquary":
			content.text = "THE ROSE RELIQUARY\n\nReserved for future item transmutation and recipes.\n\nCrafting is not enabled. No items can be inserted, consumed or rerolled here yet."
		_:
			content.text = "GAME MENU\n\nPlaceholder for settings, controls and return options."
	show()
