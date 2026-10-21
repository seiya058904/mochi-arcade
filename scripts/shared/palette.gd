class_name MochiPalette
extends RefCounted

const INK := Color("634b40")
const MUTED := Color("6e564a")
const CREAM := Color("fcf7ee")
const PAPER := Color("fffdf8")
const LINE := Color("eadfce")
const PEACH := Color("f6d4c5")
const MINT := Color("dbe8cb")
const LILAC := Color("e5dcf0")
const SKY := Color("d7e9ef")
const YELLOW := Color("f8e5b3")
const ROSE := Color("f0cbd0")
const ACCENTS := [PEACH, SKY, ROSE, YELLOW, MINT, LILAC, MINT, PEACH]

static func box(color: Color, radius: int = 24, border: Color = Color.TRANSPARENT, shadow: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.border_color = border
	style.set_border_width_all(2 if border.a > 0 else 0)
	style.shadow_color = Color(0.38, 0.27, 0.2, 0.08)
	style.shadow_size = shadow
	style.shadow_offset = Vector2(0, 5)
	style.anti_aliasing = true
	return style
