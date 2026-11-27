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

static func apply(target: Control) -> void:
	var t: Theme = Theme.new()
	t.default_font_size=14
	for kind in ["Button","OptionButton","CheckButton"]:
		t.set_stylebox("normal",kind,plate(Color("231b26"),Color("665043")))
		t.set_stylebox("hover",kind,plate(Color("392638"),Color("c7a477")))
		t.set_stylebox("pressed",kind,plate(Color("422b39"),Color("e0bd88")))
		t.set_stylebox("disabled",kind,plate(Color("1a171e"),Color("3b3038")))
		t.set_stylebox("focus",kind,plate(Color(0,0,0,0),Color("bc9776")))
		t.set_color("font_color",kind,Color("d9c7bc"))
		t.set_color("font_hover_color",kind,Color("fff0d3"))
		t.set_color("font_disabled_color",kind,Color("786d78"))
	t.set_stylebox("normal","LineEdit",plate(Color("100e15"),Color("65503f")))
	t.set_stylebox("focus","LineEdit",plate(Color("17111b"),Color("c0a078")))
	t.set_color("font_color","LineEdit",Color("ead8cd"))
	t.set_stylebox("panel","ItemList",plate(Color("100d14"),Color("665043"),1,5))
	t.set_stylebox("selected","ItemList",plate(Color("44303e"),Color("ae875f"),1,4))
	t.set_stylebox("selected_focus","ItemList",plate(Color("44303e"),Color("dfbd88"),1,4))
	t.set_constant("v_separation","ItemList",7)
	t.set_constant("h_separation","ItemList",12)
	t.set_color("font_selected_color","ItemList",Color("f4d8ac"))
	target.theme=t

static func frame(target: Control) -> void:
	var trim: Control = preload("res://scripts/gothic_frame_v241.gd").new()
	trim.mouse_filter=Control.MOUSE_FILTER_IGNORE
	target.add_child(trim)
	trim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
