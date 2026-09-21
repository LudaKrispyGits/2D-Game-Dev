extends CharacterBody2D


@export var move_speed: float = 150.0
signal resources_changed(gold: int, wood: int)

var gold: int = 20
var wood: int = 20

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
	resources_changed.emit(gold, wood)


func add_wood(amount: int) -> void:
	wood += amount
	print("Wood: ", wood)
	resources_changed.emit(gold, wood)

func spend_resources(gold_cost: int, wood_cost: int) -> bool:  # using the gold and wood
	if gold < gold_cost or wood < wood_cost:
		print("Player Doesnt have Enough Gold or Wood")
		return false
	gold -= gold_cost
	wood -= wood_cost
	resources_changed.emit(gold, wood)
	return true
