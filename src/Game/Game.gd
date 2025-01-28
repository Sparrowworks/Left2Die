class_name Game extends Node2D

signal zombie_spawned()

const PLAYER = preload("res://src/Game/Player/Player.tscn")
const ZOMBIE = preload("res://src/Game/Zombie/Zombie.tscn")

@onready var player_pos: Node = $PlayerPos
@onready var players: Node = $Players
@onready var zombies: Node = $Zombies
@onready var bullets: Node = $Bullets

@onready var ui: CanvasLayer = $UI
@onready var loading_screen: Control = %LoadingScreen
@onready var loading_animation: AnimationPlayer = %AnimationPlayer

@onready var info_text: Label = %InfoText
@onready var game_end_panel: PanelContainer = %GameEndPanel
@onready var pause_panel: PanelContainer = %PausePanel

@onready var zombie_spawn_point: PathFollow2D = %ZombieSpawnPoint
@onready var zombie_spawn_timer: Timer = $ZombieSpawnTimer

@onready var game_manager: GameManager = $GameManager

var player_sprites: Array = [
	preload("res://assets/images/player1.png"),
	preload("res://assets/images/player2.png"),
	preload("res://assets/images/player3.png"),
	preload("res://assets/images/player4.png")
]

var player_scores: Dictionary = {

}

var is_player_dead: Dictionary = {

}

func _ready() -> void:
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	set_process(false)
	loading_screen.show()
	loading_animation.play("Load")

	print(game_manager.is_game_ready)
	if not game_manager.is_game_ready:
		await game_manager.game_ready

	print(multiplayer.get_unique_id()," Game is ready")

	spawn_players()

	if not game_manager.are_players_ready:
		await game_manager.players_ready

	start_game()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("exit"):
		pause_panel.visible = not pause_panel.visible

func spawn_players() -> void:
	for idx in range(0, Lobby.connected_peers.size()):
		var player: Player = PLAYER.instantiate()
		player.name = str(Lobby.connected_peers[idx])
		player.global_position = player_pos.get_child(idx).global_position
		player.sync_pos = player_pos.get_child(idx).global_position
		players.add_child(player)

		player.sprite.texture = player_sprites[idx]
		player.set_multiplayer_authority(Lobby.connected_peers[idx])

		if not is_instance_valid(player):
			await player.ready

		if multiplayer.is_server() && Lobby.connected_peers[idx] == 1:
			player.spawn_enabled.connect(_on_spawn_enabled)

		if multiplayer.get_unique_id() == 1:
			is_player_dead[Lobby.connected_peers[idx]] = false
			player_scores[Lobby.connected_peers[idx]] = {"score": 0, "kills": 0}

	if multiplayer.get_unique_id() != 1:
		game_manager.rpc_id(1,"add_players_spawned",multiplayer.get_unique_id())
	else:
		game_manager.add_players_spawned(1)

@rpc("call_remote","authority","reliable",1)
func spawn_zombie(z_pos: Vector2) -> void:
	var zombie: Zombie = ZOMBIE.instantiate()
	zombie.global_position = z_pos
	zombie.sync_pos = z_pos
	zombie.set_multiplayer_authority(1)
	zombies.add_child(zombie, true)

	if multiplayer.get_unique_id() == 1:
		zombie.score_updated.connect(_on_zombie_score_updated)
		zombie.zombie_killed.connect(_on_zombie_killed)

	var player: Player = players.get_node(str(multiplayer.get_unique_id()))
	zombie.score_updated.connect(player._on_zombie_score_updated)
	zombie.zombie_killed.connect(player._on_zombie_killed)
	print("Spawning zombie for: ", str(multiplayer.get_unique_id(), " " , str(get_multiplayer_authority())))

func start_game() -> void:
	for plr: Player in players.get_children():
		plr.synchronizer.public_visibility = true

	loading_animation.stop()
	loading_screen.hide()

	set_process(true)

@rpc("any_peer","call_local","reliable",1)
func kill_player(id: int) -> void:
	for player in players.get_children():
		if player.name == str(id):
			player.queue_free()
			break

	if multiplayer.get_unique_id() == 1:
		is_player_dead[id] = true
		if not is_player_dead.values().has(false):
			game_end_panel.show()

func _on_spawn_enabled() -> void:
	zombie_spawn_timer.start()

func _on_zombie_spawn_timer_timeout() -> void:
	zombie_spawn_point.progress_ratio = randf()

	print(multiplayer.get_unique_id())
	if multiplayer.get_unique_id() == 1:
		spawn_zombie(zombie_spawn_point.global_position)

func _on_zombie_score_updated(id: int, value: int) -> void:
	player_scores[id]["score"] += value

func _on_zombie_killed(id: int) -> void:
	player_scores[id]["kills"] += 1

func _on_player_disconnected(id: int) -> void:
	kill_player(id)
	game_manager.clear_peer(id)

	Lobby.connected_peers.erase(id)

func _on_server_disconnected() -> void:
	process_mode = PROCESS_MODE_DISABLED
	var popup: MessagePopup = Messenger.create_popup("Host Left", "Host has left the game.")
	popup.ok_pressed.connect(
		func() -> void:
			Lobby.clear_peer()
			Composer.load_scene("res://src/MainMenu/MainMenu.tscn")
	)
	ui.add_child(popup)


func _on_menu_button_pressed() -> void:
	process_mode = PROCESS_MODE_DISABLED
	Composer.load_scene("res://src/MainMenu/MainMenu.tscn")
	Lobby.clear_peer()


func _on_resume_button_pressed() -> void:
	pause_panel.hide()
