class_name WaveSystem extends Node

signal update_info_text(text: String)

signal zombie_spawned(health: float, speed: float)

signal wave_started
signal wave_ended(wave: int)

@onready var zombie_spawn_timer: Timer = $ZombieSpawnTimer
@onready var anticipation_timer: Timer = $AnticipationTimer
@onready var game_theme: AudioStreamPlayer = $GameTheme

var game_themes: Array = [
	preload("res://assets/audio/game1.mp3"),
	preload("res://assets/audio/game2.mp3"),
	preload("res://assets/audio/game3.mp3")
]

var game: Game
var current_wave: int = 0

var this_wave_health: float = 20.0
var this_wave_speed: float = 100.0

var this_wave_spawned: int = 0
var this_wave_zombies: int = 20
var this_wave_remaining: int = 0

var this_wave_wait_time: float = 2.0

var anticipation_time: int = 10
var this_anticipation_time: int = 0


func _ready() -> void:
	game = get_parent()


func start() -> void:
	current_wave = 0
	this_wave_zombies = 20
	this_wave_remaining = 0
	this_wave_spawned = 0
	this_wave_wait_time = 2.0

	_start_anticipation()


func stop() -> void:
	anticipation_timer.stop()
	zombie_spawn_timer.stop()
	game_theme.stop()


func _start_anticipation() -> void:
	# Start the countdown before the next wave
	this_anticipation_time = 0
	current_wave += 1

	$Ambience.play()
	anticipation_timer.start()
	update_info_text.emit("Wave " + str(current_wave) + " in 10 seconds...")


func _start_wave() -> void:
	update_info_text.emit("Wave " + str(current_wave) + " in progress...")
	wave_started.emit()

	zombie_spawn_timer.start()

	$Ambience.stop()
	game_theme.stream = game_themes.pick_random()
	game_theme.play()


func _end_wave() -> void:
	# End the wave and update the difficulty variables
	await get_tree().create_timer(2).timeout

	game_theme.stop()
	$WaveSurvived.play()

	update_info_text.emit("Wave " + str(current_wave) + " is over!")
	wave_ended.emit(current_wave)
	zombie_spawn_timer.stop()

	this_wave_spawned = 0
	this_wave_remaining = 0

	this_wave_zombies += 5
	this_wave_wait_time = clampf(this_wave_wait_time - 0.05, 0.5, 2.0)

	this_wave_health += 5.0
	this_wave_speed = clampf(this_wave_speed + 10.0, 100.0, 250.0)


func _on_anticipation_timer_timeout() -> void:
	this_anticipation_time += 1

	update_info_text.emit(
		(
			"Wave "
			+ str(current_wave)
			+ " in "
			+ str(anticipation_time - this_anticipation_time)
			+ " seconds..."
		)
	)

	# End the anticipation phase and start the wave
	if this_anticipation_time == anticipation_time:
		anticipation_timer.stop()
		_start_wave()


func _on_zombie_spawn_timer_timeout() -> void:
	this_wave_spawned += 1
	this_wave_remaining += 1

	# Limit the number of zombies that can spawn this wave.
	if this_wave_spawned == this_wave_zombies:
		zombie_spawn_timer.stop()

	zombie_spawned.emit(this_wave_health, this_wave_speed)


func _on_zombie_killed(_id: int) -> void:
	rpc("_update_zombie_remaining")


@rpc("any_peer", "call_local", "reliable", 2)
func _update_zombie_remaining() -> void:
	this_wave_remaining -= 1

	# End the wave once all zombies are gone
	if this_wave_spawned == this_wave_zombies and this_wave_remaining <= 0:
		_end_wave()


func _on_wave_survived_finished() -> void:
	$Ambience.play()

	_start_anticipation()
