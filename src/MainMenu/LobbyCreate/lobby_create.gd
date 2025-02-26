extends Control

signal game_created()

@onready var port_edit: LineEdit = %PortEdit
@onready var player_amount_field: SpinBox = %PlayerAmountField

var menu: MainMenu

func _ready() -> void:
	menu = get_parent()

func _on_host_button_pressed() -> void:
	menu.button_click.play()

	if port_edit.text == "":
		var popup: MessagePopup = Messenger.create_popup("Invalid Port", "The port number cannot be empty.")
		add_child(popup)
		return

	var error: Error = Lobby.create_server(int(port_edit.text),player_amount_field.value)
	print(error)
	if error == OK:
		game_created.emit()
	else:
		var popup: MessagePopup = Messenger.create_popup(Lobby.get_error_title(error), Lobby.get_error_text(error))
		add_child(popup)
