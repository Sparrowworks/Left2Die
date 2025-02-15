class_name LobbyMenu extends Control

@onready var lobby_title: Label = %LobbyTitle
@onready var player_list: VBoxContainer = %PlayerList
@onready var start_button_control: Control = $PanelContainer/VBoxContainer/Control
@onready var start_button: TextureButton = %StartButton

var menu: MainMenu

var has_player_joined: Dictionary = {

}

func _ready() -> void:
	menu = get_parent()
	Lobby.lobby_menu = self
	lobby_title.text = "Please wait, joining..."

@rpc("authority", "call_local", "reliable")
func draw_lobby(players: Dictionary, max_players: int) -> void:
	if multiplayer.get_unique_id() == 1:
		start_button_control.show()

	if players.size() > 0:
		lobby_title.text = "Players in Lobby (" + str(players.size()) + "/" + str(max_players) + "):"

	for idx in range(0, player_list.get_child_count()):
		var lobby_player: LobbyPlayer = player_list.get_child(idx)

		if players.size() <= idx:
			lobby_player.hide()
			continue

		var peer_id: int = players.keys()[idx]
		var peer_nick: String = players[peer_id]

		lobby_player.player_name = peer_nick
		if peer_id == 1 or not multiplayer.is_server():
			lobby_player.remove_kick()

		if peer_id == multiplayer.get_unique_id():
			lobby_player.player_name_text.modulate = Color.GREEN

		lobby_player.show()

func check_if_game_can_start() -> void:
	if multiplayer.is_server():
		start_button.disabled = has_player_joined.values().has(false)

func _on_start_button_pressed() -> void:
	menu.button_click.play()
	if multiplayer.is_server():
		Lobby.game_started()

func _on_lobby_player_player_kicked(player_name: String) -> void:
	if multiplayer.is_server():
		Lobby.rpc_id(player_name.to_int(),"kick_peer", "Kicked", "You have been kicked from the lobby.")

func _exit_tree() -> void:
	Lobby.lobby_menu = null
