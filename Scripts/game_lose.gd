extends CanvasLayer

@onready var reset_button: Button = $Reset

func _ready() -> void:
	get_tree().paused = false
	reset_button.pressed.connect(_on_reset_pressed)


func _on_reset_pressed() -> void:
	GameManager.reset()
	get_tree().reload_current_scene()
	queue_free()
