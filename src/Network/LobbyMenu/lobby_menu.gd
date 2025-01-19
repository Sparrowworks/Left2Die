extends Control

@onready var lobby_title: Label = %LobbyTitle
@onready var player_list: VBoxContainer = %PlayerList
@onready var start_button: Button = %StartButton

func _ready() -> void:
	Lobby.lobby_redraw_needed.connect(
		func() -> void:
			draw_lobby(Lobby.connected_peers, Lobby.lobby_max)
	)

func draw_lobby(players: Array[int], max_players: int) -> void:
	if multiplayer.get_unique_id() != 1:
		start_button.hide()

	lobby_title.text = "Players in Lobby (" + str(players.size()) + "/" + str(max_players) + "):"

	for idx in range(0, player_list.get_child_count()):
		var lobby_player: LobbyPlayer = player_list.get_child(idx)
		if players.size() <= idx:
			lobby_player.hide()
			continue

		var peer_id: int = players[idx]

		lobby_player.player_name = str(peer_id)
		if peer_id == 1 or not multiplayer.is_server():
			lobby_player.hide_kick()

		lobby_player.show()

func _on_start_button_pressed() -> void:
	if multiplayer.is_server():
		Lobby.game_started()


func _on_lobby_player_player_kicked(player_name: String) -> void:
	pass # Replace with function body.
