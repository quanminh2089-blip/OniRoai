extends RefCounted

const INK: = Color("e6e9e9")
const GOLD: = Color("d9ac65")
const MINT: = Color("d9ac65")
const PANEL: = Color(0.035, 0.043, 0.05, 0.94)

static func box(color: Color, radius: int = 3, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var s: = StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.set_border_width_all(1)
	s.border_color = border
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s

static func theme() -> Theme:
	var t: = Theme.new()
	t.default_font_size = 19
	t.set_color("font_color", "Label", INK)
	t.set_color("font_color", "Button", INK)
	t.set_stylebox("normal", "Button", box(Color("1b2228"), 3, Color("354048")))
	t.set_stylebox("hover", "Button", box(Color("283037"), 3, MINT))
	t.set_stylebox("pressed", "Button", box(Color("493d2c"), 3, MINT))
	t.set_stylebox("focus", "Button", box(Color(0, 0, 0, 0), 3, GOLD))
	t.set_stylebox("panel", "PanelContainer", box(PANEL, 4, Color("41494d")))
	t.set_stylebox("background", "ProgressBar", box(Color("242d33"), 1))
	t.set_stylebox("fill", "ProgressBar", box(MINT, 1))
	t.set_color("font_color", "CheckButton", INK)
	t.set_stylebox("slider", "HSlider", box(Color("414a50"), 2))
	t.set_stylebox("grabber_area", "HSlider", box(GOLD, 2))
	var thumb = load("res://assets/ui/slider_thumb.svg") as Texture2D
	t.set_icon("grabber", "HSlider", thumb)
	t.set_icon("grabber_highlight", "HSlider", thumb)
	t.set_icon("grabber_disabled", "HSlider", thumb)
	return t

static func label(text: String, size: int, color: Color = INK) -> Label:
	var l: = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
