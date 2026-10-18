## Shared arcade UI look: chunky panels, thick borders, uppercase labels.
class_name UiKit
extends RefCounted

const INK := Color("#f7f4ea")
const MUTED := Color("#a9b0c3")
const BG := Color("#0d0e17")
const PANEL := Color("#161a2b")
const PANEL_LIGHT := Color("#1f253c")
const GOLD := Color("#ffcf5c")
const CYAN := Color("#7fe7ff")
const PINK := Color("#ff9ad5")
const RED := Color("#ff5a4f")
const GREEN := Color("#7cf29c")

const FONT_SMALL := 22
const FONT_BODY := 26
const FONT_BUTTON := 30
const FONT_HEADING := 48
const FONT_TITLE := 104


static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = FONT_BODY
	theme.set_color("font_color", "Label", INK)
	theme.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.6))
	theme.set_constant("shadow_offset_x", "Label", 2)
	theme.set_constant("shadow_offset_y", "Label", 3)

	theme.set_stylebox("normal", "Button", button_style(PANEL, Color(1, 1, 1, 0.18)))
	theme.set_stylebox("hover", "Button", button_style(PANEL_LIGHT, GOLD))
	theme.set_stylebox("pressed", "Button", button_style(Color("#2b3350"), GOLD))
	theme.set_stylebox("focus", "Button", button_style(Color(0, 0, 0, 0), GOLD, 2))
	theme.set_stylebox("disabled", "Button", button_style(Color("#12141f"), Color(1, 1, 1, 0.08)))
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_hover_color", "Button", GOLD)
	theme.set_color("font_pressed_color", "Button", GOLD)
	theme.set_color("font_focus_color", "Button", GOLD)
	theme.set_color("font_disabled_color", "Button", MUTED)
	theme.set_font_size("font_size", "Button", FONT_BUTTON)
	theme.set_constant("outline_size", "Button", 0)

	theme.set_stylebox("panel", "PanelContainer", button_style(Color(0.05, 0.06, 0.11, 0.92), Color(1, 1, 1, 0.14)))
	theme.set_stylebox("panel", "Panel", button_style(Color(0.05, 0.06, 0.11, 0.92), Color(1, 1, 1, 0.14)))

	theme.set_color("font_color", "CheckBox", INK)
	theme.set_color("font_hover_color", "CheckBox", GOLD)
	theme.set_font_size("font_size", "CheckBox", FONT_BODY)

	theme.set_color("font_color", "HSlider", INK)
	return theme


static func button_style(bg: Color, border: Color, border_width: int = 3) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(10)
	style.content_margin_left = 26
	style.content_margin_right = 26
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


static func panel_style(bg: Color = Color(0.05, 0.06, 0.11, 0.92), border: Color = Color(1, 1, 1, 0.14), radius: int = 16) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(28)
	return style


static func label(text: String, font_size: int = FONT_BODY, color: Color = INK, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.horizontal_alignment = align
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func title(text: String, font_size: int = FONT_TITLE, color: Color = GOLD) -> Label:
	var node := label(text, font_size, color, HORIZONTAL_ALIGNMENT_CENTER)
	node.add_theme_color_override("font_shadow_color", Color(0.05, 0.03, 0.1, 0.9))
	node.add_theme_constant_override("shadow_offset_x", 5)
	node.add_theme_constant_override("shadow_offset_y", 6)
	return node


static func button(text: String, is_primary: bool = false) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size = Vector2(420, 68)
	node.focus_mode = Control.FOCUS_ALL
	if is_primary:
		node.add_theme_stylebox_override("normal", button_style(Color("#3a2f14"), GOLD))
		node.add_theme_stylebox_override("hover", button_style(Color("#54431c"), Color("#fff0b8")))
		node.add_theme_color_override("font_color", GOLD)
	return node


static func spacer(height: float) -> Control:
	var node := Control.new()
	node.custom_minimum_size = Vector2(0, height)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func panel_container(style: StyleBoxFlat = panel_style()) -> PanelContainer:
	var node := PanelContainer.new()
	node.add_theme_stylebox_override("panel", style)
	return node


static func hsep(height: float = 2.0, color: Color = Color(1, 1, 1, 0.12)) -> ColorRect:
	var node := ColorRect.new()
	node.color = color
	node.custom_minimum_size = Vector2(0, height)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node


static func attach_shadow(node: Control) -> void:
	node.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65))
	node.add_theme_constant_override("shadow_offset_x", 2)
	node.add_theme_constant_override("shadow_offset_y", 3)
