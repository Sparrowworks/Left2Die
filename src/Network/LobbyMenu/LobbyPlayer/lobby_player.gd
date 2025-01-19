class_name LobbyPlayer extends HBoxContainer

signal player_kicked(player_name: String)

@onready var player_name_text: Label = $PlayerNameText
@onready var kick_button: Button = $KickButton

@export var player_name: String = "":
	set(val):
		if player_name_text == null:
			await ready

		player_name_text.text = val
	get():
		if player_name_text == null:
			await ready

		return player_name_text.text

func hide_kick() -> void:
	kick_button.hide()

func _on_kick_button_pressed() -> void:
	player_kicked.emit(player_name)
