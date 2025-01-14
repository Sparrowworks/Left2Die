class_name Player extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer

var speed: float = 200.0

@export var sync_pos: Vector2 = Vector2.ZERO
@export var sync_rot: float = 0

func _physics_process(delta: float) -> void:
	if get_multiplayer_authority() != multiplayer.get_unique_id():
		global_position = global_position.lerp(sync_pos, synchronizer.replication_interval)
		rotation_degrees = lerpf(rotation_degrees, sync_rot, synchronizer.replication_interval)
		return

	look_at(get_global_mouse_position())

	sync_pos = global_position
	sync_rot = rotation_degrees

	var movement_vector: Vector2 = Input.get_vector("left","right","up","down")
	if movement_vector:
		global_position = Vector2(
			global_position.x + movement_vector.x * speed * delta,
			global_position.y + movement_vector.y * speed * delta
		)
