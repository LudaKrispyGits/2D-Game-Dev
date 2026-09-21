extends VBoxContainer

@export var minion_scene: PackedScene
@export var explosion_scene: PackedScene
@export var gold_cost: int = 1
@export var wood_cost: int = 1
@export var spawn_radius: float = 40.0
@export var min_spawn_radius: float = 20.0
@export var minion_spawn_offset: Vector2 = Vector2(0, 40)

@onready var gold_cost_label: Label = $CostRow/GoldCostLabel
@onready var wood_cost_label: Label = $CostRow/WoodCostLabel
@onready var buy_button: Button = $BuyButton

var player: Node = null

func _ready() -> void:
	gold_cost_label.text = str(gold_cost)
	wood_cost_label.text = str(wood_cost)
	buy_button.pressed.connect(_on_buy_pressed)

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]
		player.resources_changed.connect(_on_resources_changed)
		_update_button_state(player.gold, player.wood)
	else:
		push_warning("MinionShopCard: no player found in 'player' group")
		buy_button.disabled = true

func _on_resources_changed(gold: int, wood: int) -> void:
	_update_button_state(gold, wood)

func _update_button_state(gold: int, wood: int) -> void:
	buy_button.disabled = gold < gold_cost or wood < wood_cost

func _on_buy_pressed() -> void:
	if player == null:
		return
	if not player.spend_resources(gold_cost, wood_cost):
		return

	var spawn_position: Vector2 = _get_random_spawn_position()

	if minion_scene:
		var minion = minion_scene.instantiate()
		get_tree().current_scene.add_child(minion)
		minion.global_position = spawn_position

	if explosion_scene:
		var explosion = explosion_scene.instantiate()
		get_tree().current_scene.add_child(explosion)
		explosion.global_position = spawn_position


func _get_random_spawn_position() -> Vector2:
	var angle: float = randf_range(0.0, TAU)
	var distance: float = randf_range(min_spawn_radius, spawn_radius)
	return player.global_position + Vector2(cos(angle), sin(angle)) * distance
