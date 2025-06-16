class_name MainMenu extends CanvasLayer

@onready var main_menu: Control = $Menu
@onready var username_enter: UsernameEnter = $UsernameEnter
@onready var game_select: Control = $GameSelect
@onready var lobby_create: Control = $LobbyCreate
@onready var join_menu: Control = $JoinMenu
@onready var lobby_menu: Control = $LobbyMenu
@onready var settings: Control = $Settings
@onready var credits: Control = $Credits

@onready var button_click: AudioStreamPlayer = $ButtonClick
@onready var username_text: Label = $VBoxContainer/UsernameText
@onready var version_text: Label = $VBoxContainer/VersionText


func _ready() -> void:
	print(int("ab1"))
	$MenuTheme.play()

	# Connect the signals from the Lobby singleton
	Lobby.join_success.connect(_on_game_created)
	Lobby.player_kicked.connect(_on_player_kicked)

	version_text.text = "v" + ProjectSettings.get_setting("application/config/version")


func _on_multi_button_pressed() -> void:
	button_click.play()
	main_menu.hide()

	# If the player hasn't entered a username yet, force the input
	if Lobby.player_username == "":
		# Reset the username enter window to its base status
		username_enter.show()
		username_enter.nick_edit.grab_focus()
		username_enter.desc.text = "To play multiplayer you need a username. enter it in the field below. The username cannot have more than 20 characters."
	else:
		game_select.show()


func _on_nick_edit_text_submitted(new_text: String) -> void:
	# Allow submitting the username with 'Enter'
	_on_confirm_button_pressed()


func _on_confirm_button_pressed() -> void:
	button_click.play()
	username_enter.reset()

	# Verify if the username is correct
	if username_enter.is_username_correct():
		Lobby.player_username = username_enter.nick_edit.text
		username_text.text = "Username: " + str(Lobby.player_username)

		username_enter.hide()
		game_select.show()  # Allow to join the game after entering the username
	else:
		username_enter.nick_edit.grab_focus()


func _on_host_game_button_pressed() -> void:
	button_click.play()
	game_select.hide()
	lobby_create.show()


func _on_menu_button_pressed() -> void:
	button_click.play()
	game_select.hide()
	main_menu.show()


func _on_back_button_pressed() -> void:
	button_click.play()
	Lobby.clear_peer()

	lobby_create.hide()
	join_menu.hide()
	game_select.show()


func _on_join_game_button_pressed() -> void:
	button_click.play()
	game_select.hide()
	join_menu.show()


func _on_leave_button_pressed() -> void:
	button_click.play()
	Lobby.clear_peer()

	main_menu.show()
	lobby_menu.hide()


func _on_player_kicked(error_title: String, error_content: String) -> void:
	var popup: MessagePopup = Messenger.create_popup(error_title, error_content)
	add_child(popup)

	Lobby.clear_peer()

	lobby_menu.hide()
	main_menu.show()


func _on_game_created() -> void:
	button_click.play()
	lobby_create.hide()
	join_menu.hide()

	lobby_menu.show()
	lobby_menu.draw_lobby(Lobby.connected_peers, Lobby.lobby_max)


func _on_settings_pressed() -> void:
	button_click.play()
	main_menu.hide()
	settings.show()


func _on_credits_pressed() -> void:
	button_click.play()
	main_menu.hide()
	credits.show()


func _on_settings_menu_button_pressed() -> void:
	button_click.play()
	username_text.text = "Username: " + Lobby.player_username

	main_menu.show()
	settings.hide()
	credits.hide()
	username_enter.hide()
