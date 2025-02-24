extends Control

@onready var ip_edit: LineEdit = %IpEdit
@onready var port_edit: LineEdit = %PortEdit

@onready var join_button: TextureButton = %JoinButton
@onready var back_button: TextureButton = %BackButton

var menu: MainMenu

func _ready() -> void:
	menu = get_parent()
	Lobby.join_failed.connect(_on_join_failed)
	Lobby.join_success.connect(_on_join_success)

func _on_join_button_pressed() -> void:
	menu.button_click.play()

	var error: Error = Lobby.create_client(ip_edit.text, int(port_edit.text))
	if error != OK:
		var popup: MessagePopup = Messenger.create_popup("Unknown error", "Unknown error has been returned with code: " + str(error))
		add_child(popup)
		return

	join_button.disabled = true
	back_button.disabled = true

func _on_join_success() -> void:
	join_button.disabled = false
	back_button.disabled = false

func _on_join_failed(quiet: bool) -> void:
	join_button.disabled = false
	back_button.disabled = false

	Lobby.clear_peer()

	if not quiet:
		var popup: MessagePopup = Messenger.create_popup("Join Timeout", "Connection was terminated, because the game didn't respond.")
		add_child(popup)
