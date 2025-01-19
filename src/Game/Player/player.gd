class_name Player extends Area2D

signal spawn_enabled()

@onready var sprite: Sprite2D = $Sprite2D
@onready var bullet_pos: Marker2D = $BulletPos

@onready var firerate_timer: Timer = $FirerateTimer
@onready var reload_timer: Timer = $ReloadTimer

@onready var synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer

const BULLET = preload("res://src/Game/Bullet/Bullet.tscn")

var speed: float = 200.0
var game: Game

var magazine: int = 30

@export var sync_pos: Vector2 = Vector2.ZERO
@export var sync_rot: float = 0

@export var health: float = 100.0

var is_dead: bool:
	get():
		return health <= 0.0

func _ready() -> void:
	game = get_parent().get_parent()

func _physics_process(delta: float) -> void:
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		global_position = global_position.lerp(sync_pos, synchronizer.replication_interval)
		rotation_degrees = lerpf(rotation_degrees, sync_rot, synchronizer.replication_interval)
		return

	if Input.is_action_pressed("shoot"):
		shoot()

	if Input.is_action_just_pressed("spawn_enable"):
		if multiplayer.is_server():
			spawn_enabled.emit()

	look_at(get_global_mouse_position())

	sync_pos = global_position
	sync_rot = rotation_degrees

	var movement_vector: Vector2 = Input.get_vector("left","right","up","down")
	if movement_vector:
		global_position = Vector2(
			global_position.x + movement_vector.x * speed * delta,
			global_position.y + movement_vector.y * speed * delta
		)

func shoot() -> void:
	if firerate_timer.time_left <= 0:
		firerate_timer.start()
		rpc("create_bullet", bullet_pos.global_position, self.rotation)

@rpc("any_peer", "call_local", "reliable",1)
func create_bullet(p_pos: Vector2, p_rot: float) -> void:
	var bullet: Bullet = BULLET.instantiate()
	game.bullets.add_child(bullet, true)
	bullet.global_position = p_pos
	bullet.rotation = p_rot
	bullet.set_multiplayer_authority(1)
