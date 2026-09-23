extends Node2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:   # Add some Sounds here later
	anim.play("Splash")
	anim.animation_finished.connect(_on_animation_finished)
	

func _on_animation_finished() -> void:
	queue_free()
