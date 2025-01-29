class_name Player extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var bullet_pos: Marker2D = $BulletPos

@onready var firerate_timer: Timer = $FirerateTimer
@onready var reload_timer: Timer = $ReloadTimer
@onready var attack_timer: Timer = $AttackTimer

@onready var ui: CanvasLayer = $UI
@onready var username_text: Label = %UsernameText
@onready var score_text: Label = %ScoreText
@onready var kills_text: Label = %KillsText
@onready var ammo_text: Label = %AmmoText
@onready var health_bar: ProgressBar = %HealthBar

@onready var synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer
@onready var player_camera: Camera2D = $Camera2D

const BULLET = preload("res://src/Game/Bullet/Bullet.tscn")

var speed: float = 200.0
var game: Game

var magazine: int = 30:
	set(val):
		if is_multiplayer_authority():
			magazine = val
			ammo_text.text = "Ammo: " + str(magazine)

@export var sync_pos: Vector2 = Vector2.ZERO
@export var sync_rot: float = 0

@export var health: float = 100.0:
	set(val):
		if is_multiplayer_authority():
			health = val
			health_bar.value = health
			if health <= 0:
				game.rpc("kill_player", multiplayer.get_unique_id())

var score: int = 0
var kills: int = 0

var is_dead: bool:
	get():
		return health <= 0.0

func _ready() -> void:
	game = get_parent().get_parent()

	if name.to_int() == multiplayer.get_unique_id():
		player_camera.enabled = true
		username_text.text = name
		ui.show()

func _physics_process(delta: float) -> void:
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		global_position = global_position.lerp(sync_pos, synchronizer.replication_interval)
		rotation_degrees = lerpf(rotation_degrees, sync_rot, synchronizer.replication_interval)
		return

	if Input.is_action_pressed("shoot"):
		shoot()

	if Input.is_action_just_pressed("reload"):
		reload()

	look_at(get_global_mouse_position())

	sync_pos = global_position
	sync_rot = rotation_degrees

	var movement_vector: Vector2 = Input.get_vector("left","right","up","down")
	if movement_vector:
		global_position = Vector2(
			clampf(global_position.x + movement_vector.x * speed * delta, 0, 1280),
			clampf(global_position.y + movement_vector.y * speed * delta, 0, 720)
		)


func shoot() -> void:
	if firerate_timer.time_left <= 0 and reload_timer.time_left <= 0 and magazine > 0:
		magazine -= 1
		firerate_timer.start()
		rpc("create_bullet", bullet_pos.global_position, self.rotation, name.to_int())

func reload() -> void:
	if reload_timer.time_left <= 0 and magazine < 30:
		ammo_text.text = "Reloading..."
		reload_timer.start()

@rpc("any_peer", "call_local", "reliable",1)
func create_bullet(p_pos: Vector2, p_rot: float, id: int) -> void:
	var bullet: Bullet = BULLET.instantiate()
	game.bullets.add_child(bullet, true)
	bullet.player_id = id
	bullet.global_position = p_pos
	bullet.rotation = p_rot
	bullet.set_multiplayer_authority(1)

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Zombies") && is_multiplayer_authority():
		attack_timer.start()

func _on_area_exited(area: Area2D) -> void:
	if area.is_in_group("Zombies") && is_multiplayer_authority():
		attack_timer.stop()

func _on_attack_timer_timeout() -> void:
	if is_multiplayer_authority():
		health -= 0.0

func _on_reload_timer_timeout() -> void:
	if is_multiplayer_authority():
		magazine = 30

func _on_zombie_score_updated(id: int, value: int) -> void:
	prints("Update", multiplayer.get_unique_id(), id)
	if id == multiplayer.get_unique_id():
		score += value
		score_text.text = "Score: " + str(score)

func _on_zombie_killed(id: int) -> void:
	if id == multiplayer.get_unique_id():
		kills += 1
		kills_text.text = "Kills: " + str(kills)
