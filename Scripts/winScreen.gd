extends CanvasLayer

@export var first_scene_path: String = "res://Scenes/Base_lvl.tscn"

@onready var reset_button: Button = $Reset

func _ready() -> void:
	get_tree().paused = false
	reset_button.pressed.connect(_on_reset_pressed)


func _on_reset_pressed() -> void:
	GameManager.reset()
	get_tree().change_scene_to_file(first_scene_path)
	queue_free()
