extends RefCounted
## Original engraved iron / velvet theme, no external art or fonts.
static func plate(bg: Color,edge: Color,border: int=1,pad: int=7) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color=bg
	style.border_color=edge
	style.set_border_width_all(border)
	style.set_corner_radius_all(2)
	style.content_margin_left=pad
	style.content_margin_right=pad
	style.content_margin_top=pad
	style.content_margin_bottom=pad
	return style

const MATERIAL = preload("res://scripts/gothic_material_v274.gd")

static func apply(target: Control) -> void:
	var t: Theme = Theme.new()
	if target is PanelContainer:
		target.add_theme_stylebox_override("panel",MATERIAL.plate(Color("17111b"),Color("947650"),18,true))
	t.default_font_size=14
	for kind in ["Button","OptionButton","CheckButton"]:
		t.set_stylebox("normal",kind,MATERIAL.plate(Color("251b26"),Color("8b6a48"),7))
		t.set_stylebox("hover",kind,MATERIAL.plate(Color("3a2634"),Color("c7a477"),7))
		t.set_stylebox("pressed",kind,MATERIAL.plate(Color("34202c"),Color("d4ae79"),7))
		t.set_stylebox("disabled",kind,MATERIAL.plate(Color("19151c"),Color("50443e"),7))
		t.set_stylebox("focus",kind,plate(Color(0,0,0,0),Color("bc9776")))
		t.set_color("font_color",kind,Color("d9c7bc"))
		t.set_color("font_hover_color",kind,Color("fff0d3"))
		t.set_color("font_disabled_color",kind,Color("786d78"))
	t.set_stylebox("normal","LineEdit",MATERIAL.plate(Color("100d14"),Color("806446"),8,true))
	t.set_stylebox("focus","LineEdit",plate(Color("17111b"),Color("c0a078")))
	t.set_color("font_color","LineEdit",Color("ead8cd"))
	t.set_stylebox("panel","ItemList",MATERIAL.plate(Color("100d14"),Color("806446"),9,true))
	t.set_stylebox("selected","ItemList",MATERIAL.plate(Color("3b2836"),Color("a8865f"),5))
	t.set_stylebox("selected_focus","ItemList",MATERIAL.plate(Color("49303d"),Color("dfbd88"),5))
	t.set_constant("v_separation","ItemList",7)
	t.set_constant("h_separation","ItemList",12)
	t.set_color("font_selected_color","ItemList",Color("f4d8ac"))
	target.theme=t

static func frame(target: Control) -> void:
	var trim: Control = preload("res://scripts/gothic_frame_v241.gd").new()
	trim.mouse_filter=Control.MOUSE_FILTER_IGNORE
	target.add_child(trim)
	trim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
