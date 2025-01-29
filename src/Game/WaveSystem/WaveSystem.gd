class_name WaveSystem extends Node

signal update_info_text(text: String)

signal zombie_spawned()

signal wave_started()
signal wave_ended()

@onready var zombie_spawn_timer: Timer = $ZombieSpawnTimer
@onready var anticipation_timer: Timer = $AnticipationTimer

var game: Game
var current_wave: int = 0

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

func _start_anticipation() -> void:
	this_anticipation_time = 0
	current_wave += 1

	anticipation_timer.start()

	update_info_text.emit("Wave " + str(current_wave) + " in 10 seconds...")

func _start_wave() -> void:
	update_info_text.emit("Wave " + str(current_wave) + " in progress...")
	wave_started.emit()

	zombie_spawn_timer.start()

func _end_wave() -> void:
	await get_tree().create_timer(2).timeout

	update_info_text.emit("Wave " + str(current_wave) + " is over!")
	wave_ended.emit()
	zombie_spawn_timer.stop()

	this_wave_zombies += 5
	this_wave_wait_time = clampf(this_wave_wait_time - 0.05, 0.5, 2.0)

	await get_tree().create_timer(5).timeout

	_start_anticipation()

func _on_anticipation_timer_timeout() -> void:
	this_anticipation_time += 1

	update_info_text.emit("Wave " + str(current_wave) + " in " + str(anticipation_time - this_anticipation_time) + " seconds...")

	if this_anticipation_time == anticipation_time:
		anticipation_timer.stop()
		_start_wave()

func _on_zombie_spawn_timer_timeout() -> void:
	this_wave_spawned += 1
	this_wave_remaining += 1

	if this_wave_spawned == this_wave_zombies:
		zombie_spawn_timer.stop()

	zombie_spawned.emit()


func _on_zombie_killed() -> void:
	this_wave_remaining -= 1
	if this_wave_spawned == this_wave_zombies and this_wave_remaining == 0:
		_end_wave()
