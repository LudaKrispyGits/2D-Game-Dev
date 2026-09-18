extends Area2D

@export var gold_amount: int = 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") or body.is_in_group("minion"):
		return
	if body.has_method("add_gold"):
		body.add_gold(gold_amount)
	else:
		push_warning("Player has no add_gold() method yet")
	queue_free()
