class_name UiStyle
extends RefCounted
## The look of the interface (125): few, readable colours that never drift
## with the world palette (51), one pixel font, and a text size the player
## can raise for dialogues and subtitles (96).

const PANEL: Color = Color(0.06, 0.05, 0.07, 0.84)
const OUTLINE: Color = Color(0.05, 0.04, 0.08)
const WARM: Color = Color(0.93, 0.66, 0.32)
const WARM_DARK: Color = Color(0.45, 0.25, 0.12)
const LIGHT: Color = Color(0.78, 0.82, 0.95)
const LIGHT_DARK: Color = Color(0.25, 0.27, 0.38)
const SPEAKER: Color = Color(1.0, 0.77, 0.42)
const TEXT: Color = Color(0.96, 0.94, 0.9)
## The pixel font (125): Jersey 10, SIL Open Font License (license next
## to the file). Imported without antialiasing, hinting or subpixels; it is
## also the default font of the project theme (assets/ui/ui_theme.tres).
const FONT_PATH: String = "res://assets/ui/fonts/jersey10.ttf"
## Text sizes at scale 1 (1280x800). Jersey 10 draws whole, even pixels at
## multiples of 28/3 px: 28 (3 font pixels per pixel row) and 56.
const BODY_SIZE: int = 28
const SMALL_SIZE: int = 28
const TITLE_SIZE: int = 56

static var _font: Font


static func font() -> Font:
	if _font == null:
		if not FONT_PATH.is_empty() and ResourceLoader.exists(FONT_PATH):
			_font = load(FONT_PATH)
		else:
			_font = ThemeDB.fallback_font
	return _font


## A text size scaled by the player's option (dialogues, subtitles, hints).
static func text_size(base: int = BODY_SIZE) -> int:
	return roundi(base * GameOptions.text_scale)


static func panel_style(margin: float = 10.0) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = Color(0.3, 0.24, 0.2, 0.9)
	style.set_border_width_all(2)
	style.set_content_margin_all(margin)
	style.anti_aliasing = false
	return style


static func style_label(label: Label, size: int, color: Color = TEXT) -> void:
	label.add_theme_font_override(&"font", font())
	label.add_theme_font_size_override(&"font_size", size)
	label.add_theme_color_override(&"font_color", color)
