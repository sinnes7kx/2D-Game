extends RefCounted
## Restrained midnight-blue title with a rare, smooth silver-blue glint.
static func ink(seconds: float) -> Color:
	var drift: float = 0.5 + 0.5 * sin(seconds * 0.48)
	var crest: float = pow(0.5 + 0.5 * cos(seconds * TAU / 8.5), 14.0)
	return Color("647ca9").lerp(Color("9096cc"), drift).lerp(Color("c3d9fa"), crest * 0.72)

static func apply(label: Label, seconds: float) -> void:
	label.modulate = Color.WHITE
	label.add_theme_color_override("font_color", ink(seconds))
	label.add_theme_color_override("font_shadow_color", Color(0.16, 0.22, 0.43, 0.75))
	label.add_theme_constant_override("shadow_outline_size", 2)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
