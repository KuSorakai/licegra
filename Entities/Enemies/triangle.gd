# UWAGA: Rozszerzamy nasz bazowy skrypt wroga! Musisz podać poprawną ścieżkę do pliku enemy.gd
extends "res://Entities/Enemies/enemy.gd"

var is_charging: bool = false
# 4 jednostki w grze 2D to około 250-300 pikseli. 
var charge_distance: float = 300.0 

func _physics_process(delta: float) -> void:
	# Szukamy gracza
	var player = get_tree().get_first_node_in_group("player")
	
	if player != null:
		# Mierzymy dystans do gracza w pikselach
		var dist = global_position.distance_to(player.global_position)
		
		# Jeśli gracz jest bliżej niż 300 pikseli i jeszcze nie szarżujemy...
		if dist <= charge_distance and not is_charging:
			is_charging = true
			speed = 400.0 # x2 prędkość gracza!
			
			# Opcjonalnie: Barwimy go mocniej na czerwono/pomarańczowo, by gracz wiedział, że zaczyna się szarża!
			if sprite != null:
				original_color = Color(1.0, 0.4, 0.4) 
				sprite.modulate = original_color

	# Magia dziedziczenia: super(delta) wywołuje oryginalny kod ruchu z enemy.gd, 
	# ale używając już naszej nowej, morderczej prędkości!
	super(delta)
