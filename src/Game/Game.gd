extends Node2D

const PLAYER = preload("res://src/Game/Player/Player.tscn")

@onready var player_pos: Node = $PlayerPos

var player_sprites: Array = [
	preload("res://assets/images/player1.png"),
	preload("res://assets/images/player2.png"),
	preload("res://assets/images/player3.png"),
	preload("res://assets/images/player4.png")
]

func _ready() -> void:
	spawn_players()

func spawn_players() -> void:
	for idx in range(0, Lobby.connected_peers.size()):
		var player: Player = PLAYER.instantiate()
		add_child(player)
		player.sprite.texture = player_sprites[idx]
		player.global_position = player_pos.get_child(idx).global_position
		player.set_multiplayer_authority(Lobby.connected_peers[idx])
