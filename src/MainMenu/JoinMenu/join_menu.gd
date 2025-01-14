extends Control

@onready var ip_edit: LineEdit = %IpEdit
@onready var port_edit: LineEdit = %PortEdit

@onready var join_button: Button = %JoinButton
@onready var back_button: Button = %BackButton

func _ready() -> void:
	Lobby.join_failed.connect(_on_join_failed)

func _on_join_button_pressed() -> void:
	Lobby.create_client(ip_edit.text, int(port_edit.text))
	join_button.disabled = true
	back_button.disabled = true

func _on_join_failed() -> void:
	join_button.disabled = false
	back_button.disabled = false

	Lobby.clear_peer()

	var popup: MessagePopup = Messenger.create_popup("Join Timeout", "Connection was terminated, because the game didn't respond.")
	add_child(popup)
