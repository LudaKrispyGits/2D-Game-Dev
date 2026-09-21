extends Node2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:   # Add some Sounds here later
	anim.play(["Blowup", "Blowup2", "Splash"].pick_random())
	anim.animation_finished.connect(_on_animation_finished)
	

func _on_animation_finished() -> void:
	queue_free()
