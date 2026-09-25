extends Area2D

@export var wood_amount: int = 1
@onready var pick_up: AudioStreamPlayer2D = $PickUp

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or body.is_in_group("minion"):
		return
	if body.has_method("add_wood"):
		body.add_wood(wood_amount)
		pick_up.play()
	else:
		push_warning("Player has no add_wood() method yet")
	queue_free()
