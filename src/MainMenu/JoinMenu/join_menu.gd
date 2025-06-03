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

	# Check for valid IP and port number
	if ip_edit.text == "":
		var popup: MessagePopup = Messenger.create_popup("Invalid IP", "The IP address cannot be empty.")
		add_child(popup)
		return

	if port_edit.text == "":
		var popup: MessagePopup = Messenger.create_popup("Invalid Port", "The port number cannot be empty.")
		add_child(popup)
		return

	# Attempt to join a server
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
