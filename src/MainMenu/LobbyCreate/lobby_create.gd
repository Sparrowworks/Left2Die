extends Control

signal game_created()

@onready var port_edit: LineEdit = %PortEdit
@onready var player_amount_field: SpinBox = %PlayerAmountField

var menu: MainMenu

func _ready() -> void:
	menu = get_parent()

func _on_host_button_pressed() -> void:
	menu.button_click.play()

	var error: Error = Lobby.create_server(int(port_edit.text),player_amount_field.value)
	if error == OK:
		game_created.emit()
	elif error == ERR_CANT_CREATE:
		var popup: MessagePopup = Messenger.create_popup("Can't create", "The server couldn't be created.")
		add_child(popup)
	else:
		var popup: MessagePopup = Messenger.create_popup("Unknown error", "Unknown error has been returned with code: " + str(error))
		add_child(popup)
