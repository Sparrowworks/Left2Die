extends Control

@onready var port_edit: LineEdit = %PortEdit
@onready var player_amount_field: SpinBox = %PlayerAmountField

signal game_created()

func _on_host_button_pressed() -> void:
	if Lobby.create_server(int(port_edit.text),player_amount_field.value) == OK:
		print("Server created.")
