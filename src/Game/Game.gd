class_name Game extends Node2D

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
@onready var game_end_panel: TextureRect = %GameEndPanel
@onready var pause_panel: TextureRect = %PausePanel
@onready var player_score_container: VBoxContainer = %PlayerScoreContainer

@onready var zombie_spawn_point: PathFollow2D = %ZombieSpawnPoint
@onready var wave_system: WaveSystem = $WaveSystem

@onready var game_manager: GameManager = $GameManager

var player_sprites: Array = [
	preload("res://assets/images/player1.png"),
	preload("res://assets/images/player2.png"),
	preload("res://assets/images/player3.png"),
	preload("res://assets/images/player4.png")
]

var player_scores: Dictionary = {}

var is_player_dead: Dictionary = {}

var is_dead: bool = false


func _ready() -> void:
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	loading_screen.show()
	loading_animation.play("Load")

	set_process(false)

	# Wait till the game is ready for everyone
	if not game_manager.is_game_ready:
		await game_manager.game_ready

	spawn_players()

	# Wait till the players have spawned for everyone
	if not game_manager.are_players_ready:
		await game_manager.players_ready

	start_game()


func _process(delta: float) -> void:
	if Input.is_action_just_pressed("exit"):
		pause_panel.visible = not pause_panel.visible


func spawn_players() -> void:
	# Spawn players for each client and assign authorities
	for idx in range(0, Lobby.connected_peers.keys().size()):
		var p_id: int = Lobby.connected_peers.keys()[idx]
		var player: Player = PLAYER.instantiate()
		player.name = str(p_id)
		player.global_position = player_pos.get_child(idx).global_position
		player.sync_pos = player_pos.get_child(idx).global_position
		players.add_child(player)

		player.sprite.texture = player_sprites[idx]
		# Allow the client with this ID to control the player
		player.set_multiplayer_authority(p_id)

		if not is_instance_valid(player):
			await player.ready

		# Track game data as host
		if multiplayer.get_unique_id() == 1:
			is_player_dead[p_id] = false
			player_scores[p_id] = {"score": 0, "kills": 0, "wave": 0}

	if multiplayer.get_unique_id() != 1:
		game_manager.rpc_id(1, "add_players_spawned", multiplayer.get_unique_id())
	else:
		game_manager.add_players_spawned(1)


@rpc("call_remote", "authority", "reliable", 1)
func spawn_zombie(z_pos: Vector2, health: float, speed: float) -> void:
	# Spawn zombie for each client
	var zombie: Zombie = ZOMBIE.instantiate()

	zombie.global_position = z_pos
	zombie.sync_pos = z_pos

	zombie.health = health
	zombie.sync_health = health

	zombie.speed = speed

	zombie.set_multiplayer_authority(1)
	zombies.add_child(zombie, true)

	zombie.score_updated.connect(_on_zombie_score_updated)
	zombie.zombie_killed.connect(_on_zombie_killed)
	zombie.zombie_killed.connect(wave_system._on_zombie_killed)

	var player: Player = players.get_node_or_null(str(multiplayer.get_unique_id()))
	if player:
		zombie.score_updated.connect(player._on_zombie_score_updated)
		zombie.zombie_killed.connect(player._on_zombie_killed)


func start_game() -> void:
	# When the game starts, synchronize all players.
	for plr: Player in players.get_children():
		plr.synchronizer.public_visibility = true

	loading_animation.stop()
	loading_screen.hide()

	set_process(true)

	wave_system.start()


@rpc("authority", "call_local", "reliable", 1)
func end_game(scores: Dictionary) -> void:
	# Show the game over panel and the scores sent by the host for each client
	$UI/GameHUD/GameEndPanel/VBoxContainer/Title.text = (
		"Game Over!\nYou survived for "
		+ str(scores[multiplayer.get_unique_id()]["wave"])
		+ " waves.\nPlayers' stats:"
	)

	wave_system.stop()
	$GameOver.play()

	for idx in range(0, player_score_container.get_child_count()):
		var child: HBoxContainer = player_score_container.get_child(idx)
		if child.name == "HBoxContainer":
			continue

		var actual_index: int = idx - 1
		if Lobby.connected_peers.keys().size() <= actual_index:
			break

		child.show()
		var p_nick: Label = child.get_child(0)
		var p_id: int = Lobby.connected_peers.keys()[actual_index]
		p_nick.text = str(Lobby.connected_peers[p_id]) + ":"
		if p_id == multiplayer.get_unique_id():
			p_nick.modulate = Color.GREEN

		var p_score: Label = child.get_child(1)
		p_score.text = str(scores[p_id]["score"])

		var p_kills: Label = child.get_child(2)
		p_kills.text = str(scores[p_id]["kills"])

	game_end_panel.show()

	set_process(false)


@rpc("any_peer", "call_local", "reliable", 1)
func kill_player(id: int) -> void:
	# Kill the player for every client
	for player in players.get_children():
		if player.name == str(id):
			player.queue_free()
			break

	# Show the dead UI for the dead client
	if multiplayer.get_unique_id() == id:
		info_text.text = "You're dead!"
		is_dead = true
		%InfoAnimation.play("RESET")

	# Update the server info as host and check for game over
	if multiplayer.get_unique_id() == 1:
		is_player_dead[id] = true
		if not is_player_dead.values().has(false):
			rpc("end_game", player_scores)


func _on_zombie_spawned(health: float, speed: float) -> void:
	# Randomize the zombie spawn location
	zombie_spawn_point.progress_ratio = randf()

	if multiplayer.get_unique_id() == 1:
		spawn_zombie(zombie_spawn_point.global_position, health, speed)


func _on_zombie_score_updated(id: int, value: int) -> void:
	if multiplayer.get_unique_id() == 1:
		player_scores[id]["score"] += value


func _on_zombie_killed(id: int) -> void:
	if multiplayer.get_unique_id() == 1:
		player_scores[id]["kills"] += 1


func _on_player_disconnected(id: int) -> void:
	kill_player(id)
	game_manager.clear_peer(id)


func _on_server_disconnected() -> void:
	# Kick everyone once the host has left or disconnected
	process_mode = PROCESS_MODE_DISABLED
	var popup: MessagePopup = Messenger.create_popup("Host Left", "Host has left the game.")
	popup.ok_pressed.connect(
		func() -> void:
			$ButtonClick.play()
			Lobby.clear_peer()
			Composer.load_scene("res://src/MainMenu/MainMenu.tscn")
	)
	ui.add_child(popup)


func _on_menu_button_pressed() -> void:
	$ButtonClick.play()
	process_mode = PROCESS_MODE_DISABLED
	Composer.load_scene("res://src/MainMenu/MainMenu.tscn")
	Lobby.clear_peer()


func _on_resume_button_pressed() -> void:
	$ButtonClick.play()
	pause_panel.hide()


func _on_wave_system_update_info_text(text: String) -> void:
	if not is_dead:
		info_text.text = text


func _on_wave_system_wave_started() -> void:
	%InfoAnimation.play("WaveStart")


func _on_wave_system_wave_ended(wave: int) -> void:
	%InfoAnimation.play("RESET")

	if multiplayer.get_unique_id() == 1:
		for id: int in player_scores.keys():
			if not is_player_dead[id]:
				player_scores[id]["wave"] = wave

	# After each wave, Heal players back to 100
	var player: Player = players.get_node_or_null(str(multiplayer.get_unique_id()))
	if player:
		player.health = 100
