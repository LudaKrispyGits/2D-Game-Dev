extends CharacterBody2D


@export var move_speed: float = 150.0

var gold: int = 0
var wood: int = 0

func _physics_process(_delta: float) -> void:
	var input_vector: Vector2 = Vector2.ZERO
	input_vector.x = Input.get_action_strength("Right") - Input.get_action_strength("Left")
	input_vector.y = Input.get_action_strength("Down") - Input.get_action_strength("Up")
	input_vector = input_vector.normalized()

	velocity = input_vector * move_speed
	move_and_slide()

func add_gold(amount: int) -> void:
	gold += amount
	print("Gold: ", gold)

func add_wood(amount: int) -> void:
	wood += amount
	print("Wood: ", wood)
