extends Area2D

var exp_value: int = 1 
var target_player: CharacterBody2D = null
var magnet_speed: float = 400.0

# Ta funkcja odpala się raz, gdy kryształ pojawia się na planszy
func _ready() -> void:
	add_to_group("gem")

func _physics_process(delta: float) -> void:
	if target_player != null:
		# Kryształ leci w stronę gracza
		var direction = global_position.direction_to(target_player.global_position)
		global_position += direction * magnet_speed * delta

# To zostaje bez zmian - podnoszenie kryształu
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.add_exp(exp_value)
		queue_free()
