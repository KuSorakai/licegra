extends CanvasLayer

# Referencje do naszych przycisków
@onready var card_1 = $Background/CardsContainer/Card1
@onready var card_2 = $Background/CardsContainer/Card2
@onready var card_3 = $Background/CardsContainer/Card3

# Pula wszystkich przedmiotów w grze (wypełnimy to w Inspektorze)
@export var item_pool: Array[ItemData] = []

var offered_items: Array[ItemData] = []
var player: CharacterBody2D

func _ready() -> void:
	hide() # Na starcie gry ekran awansu jest niewidoczny
	# Szukamy gracza za pomocą grupy
	player = get_tree().get_first_node_in_group("player")

# Funkcja odpalana, gdy gracz zdobędzie level
func trigger_level_up() -> void:
	get_tree().paused = true # ZATRZYMUJEMY GRĘ!
	show() # Pokazujemy ekran
	
	offered_items.clear()
	
	# Losujemy 3 przedmioty z puli (na razie bez zabezpieczenia przed powtórkami)
	for i in range(3):
		if item_pool.size() > 0:
			var random_item = item_pool.pick_random()
			offered_items.append(random_item)
		
	# Aktualizujemy tekst na przyciskach (kartach)
	if offered_items.size() == 3:
		card_1.text = offered_items[0].item_name
		card_2.text = offered_items[1].item_name
		card_3.text = offered_items[2].item_name

# Gdy wybierzemy kartę, wywołujemy tę funkcję
func select_item(index: int) -> void:
	if player != null and offered_items.size() > index:
		var chosen_item = offered_items[index]
		player.add_item(chosen_item) # Dodajemy item graczowi
		
	hide() # Chowamy ekran
	get_tree().paused = false # WZNAWIAMY GRĘ!


func _on_card_1_pressed() -> void:
	select_item(0)


func _on_card_2_pressed() -> void:
	select_item(1)


func _on_card_3_pressed() -> void:
	select_item(2)
