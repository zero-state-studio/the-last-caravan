class_name StartMenu
extends CanvasLayer
## At start, when a save exists (95): «Continue» goes back to the last
## autosave, «New game» starts the prologue. Pauses the scene below until a
## choice is made. Every visible text is a translation key.

signal new_game_chosen

var _panel: PanelContainer
var _continue: Button


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	var backdrop: ColorRect = ColorRect.new()
	backdrop.color = Color(0.0, 0.0, 0.0, 0.85)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override(&"panel", UiStyle.panel_style(24.0))
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(420.0, 0.0)
	_panel.position = Vector2(-210.0, -90.0)
	add_child(_panel)
	var box: VBoxContainer = VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 14)
	_panel.add_child(box)
	_continue = _button(box, "START_CONTINUE")
	_continue.pressed.connect(_on_continue)
	var new_game: Button = _button(box, "START_NEW_GAME")
	new_game.pressed.connect(_on_new_game)
	get_tree().paused = true
	_continue.grab_focus.call_deferred()


## Shows the menu over `parent` when there is a save; true when shown.
static func show_if_saved(parent: Node) -> StartMenu:
	if not SaveGame.has_save():
		return null
	var menu: StartMenu = StartMenu.new()
	menu.name = "StartMenu"
	parent.add_child(menu)
	return menu


func _button(box: VBoxContainer, key: String) -> Button:
	var button: Button = Button.new()
	button.text = key
	button.add_theme_font_override(&"font", UiStyle.font())
	button.add_theme_font_size_override(&"font_size", UiStyle.text_size())
	box.add_child(button)
	return button


func _on_continue() -> void:
	get_tree().paused = false
	if not SaveGame.continue_game(get_tree()):
		_on_new_game()


func _on_new_game() -> void:
	get_tree().paused = false
	new_game_chosen.emit()
	queue_free()
