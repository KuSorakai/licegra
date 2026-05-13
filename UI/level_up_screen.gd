extends CanvasLayer

# Referencje do naszych przycisków
@onready var card_1 = $Background/CardsContainer/Card1
@onready var card_2 = $Background/CardsContainer/Card2
@onready var card_3 = $Background/CardsContainer/Card3
@onready var stats_label = $Background/StatsLabel

# Pula wszystkich przedmiotów w grze (wypełnimy to w Inspektorze)
@export var item_pool: Array[ItemData] = []

var offered_items: Array[ItemData] = []
var player: CharacterBody2D

func _ready() -> void:
	hide() # Na starcie gry ekran awansu jest niewidoczny
	# Szukamy gracza za pomocą grupy
	player = get_tree().get_first_node_in_group("player")
	if player != null:
		var st = "--- TWOJE STATYSTYKI ---\n"
		st += "Zdrowie: " + str(player.hp) + " / " + str(5 + player.total_bonus_max_hp) + "\n"
		st += "Mana: " + str(int(player.mana)) + " / " + str(int(player.base_max_mana + player.total_bonus_max_mana)) + "\n"
		st += "Dodatkowe DMG: +" + str(player.total_bonus_damage_percent * 100) + "%\n"
		st += "Prędkość Ruchu: " + str(player.speed + player.total_bonus_speed)
		stats_label.text = st

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
		card_1.icon = offered_items[0].icon
		card_1.expand_icon = true
		card_1.tooltip_text = build_item_tooltip(offered_items[0])
		
		card_2.text = offered_items[1].item_name
		card_2.icon = offered_items[1].icon
		card_2.expand_icon = true
		card_1.tooltip_text = build_item_tooltip(offered_items[1])
		
		card_3.text = offered_items[2].item_name
		card_3.icon = offered_items[2].icon
		card_3.expand_icon = true
		card_1.tooltip_text = build_item_tooltip(offered_items[2])

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
	
func build_item_tooltip(i: ItemData) -> String:
	var t = "== " + i.item_name.to_upper() + " ==\n"
	# Sprawdzamy co daje przedmiot i dopisujemy do tekstu
	if i.bonus_max_hp > 0: 
		t += "Max Zdrowie: +" + str(i.bonus_max_hp) + "\n"
	if i.bonus_speed > 0: 
		t += "Prędkość: +" + str(i.bonus_speed) + "\n"
	if i.bonus_damage_percent > 0: 
		t += "Obrażenia: +" + str(i.bonus_damage_percent * 100) + "%\n"
	return t
