class_name LobbyPlayer extends TextureRect

signal player_kicked(player_name: String)

@onready var player_name_text: Label = $HBoxContainer/PlayerNameText
@onready var kick_button: Button = $HBoxContainer/Control/KickButton

@export var player_name: String = "":
	set(val):
		if player_name_text == null:
			await ready

		player_name_text.text = val
	get():
		if player_name_text == null:
			await ready

		return player_name_text.text

func remove_kick() -> void:
	kick_button.get_parent().hide()

func _on_kick_button_pressed() -> void:
	$ButtonClick.play()
	player_kicked.emit(player_name)
