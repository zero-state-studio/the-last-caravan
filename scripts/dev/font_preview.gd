extends SceneTree
## Tries pixel fonts (125) at 1280x800: for each font a dialogue line, a hint
## and the chapter title, as the game would show them, crisp (no
## antialiasing, no hinting, whole-pixel positions).
## Usage: godot --path . --resolution 1280x800 --script res://scripts/dev/font_preview.gd -- \
##     <out.png> <font_file>:<body_size>:<title_size>[,...]
## Font files can be outside the project (source-assets), by absolute path.

const SPEAKER: String = "Ottavia"
const LINE: String = "Da quarant'anni, la Serrafila sono io. Perché è così? Più in là c'è già la Notte: «Chi si ferma, la Notte lo raggiunge.»"
const ACCENTS: String = "àèéìòù ÀÈÉÌÒÙ «» … 0123456789"
const HINT: String = "E  Interagisci"
const TITLE: String = "Ne restano dieci."

var _out_path: String = ""
var _frames: int = 0


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	_out_path = args[0]
	var specs: PackedStringArray = args[1].split(",", false)
	var canvas: Control = Control.new()
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_root().add_child(canvas)
	var background: ColorRect = ColorRect.new()
	background.color = Color(0.36, 0.27, 0.24)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(background)
	var row_height: float = 800.0 / specs.size()
	for index: int in specs.size():
		var parts: PackedStringArray = specs[index].split(":")
		var font: FontFile = FontFile.new()
		font.load_dynamic_font(parts[0])
		font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		font.hinting = TextServer.HINTING_NONE
		font.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
		var body: int = parts[1].to_int()
		var title_size: int = parts[2].to_int()
		var top: float = index * row_height
		var box: PanelContainer = PanelContainer.new()
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(0.06, 0.05, 0.07, 0.85)
		style.set_content_margin_all(12.0)
		box.add_theme_stylebox_override(&"panel", style)
		box.position = Vector2(16.0, top + 8.0)
		box.custom_minimum_size = Vector2(860.0, row_height - 16.0)
		canvas.add_child(box)
		var lines: VBoxContainer = VBoxContainer.new()
		box.add_child(lines)
		lines.add_child(_label(font, body, "%s   [%s, %d px]" % [SPEAKER, parts[0].get_file().get_basename(), body], Color(1.0, 0.77, 0.42)))
		var line: Label = _label(font, body, LINE, Color.WHITE)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.custom_minimum_size = Vector2(830.0, 0.0)
		lines.add_child(line)
		lines.add_child(_label(font, body, ACCENTS + "    " + HINT, Color(0.85, 0.85, 0.85)))
		var title_back: ColorRect = ColorRect.new()
		title_back.color = Color.BLACK
		title_back.position = Vector2(892.0, top + 8.0)
		title_back.size = Vector2(372.0, row_height - 16.0)
		canvas.add_child(title_back)
		var title: Label = _label(font, title_size, TITLE, Color.WHITE)
		title.position = title_back.position
		title.size = title_back.size
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		canvas.add_child(title)


func _label(font: Font, size: int, text: String, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_override(&"font", font)
	label.add_theme_font_size_override(&"font_size", size)
	label.add_theme_color_override(&"font_color", color)
	return label


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames == 8:
		get_root().get_texture().get_image().save_png(_out_path)
		print("font_preview: saved " + _out_path)
		return true
	return false
