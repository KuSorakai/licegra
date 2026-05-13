extends Resource
# class_name sprawia, że Godot rozpozna ten skrypt jako nowy typ pliku
class_name WeaponData

@export var weapon_name: String = "Nowa Broń"
@export var icon: Texture2D # Zmienna na ikonę broni
@export_enum("Tier 1 (Biały)", "Tier 2 (Niebieski)", "Tier 3 (Fioletowy)", "Tier 4 (Legendarny)") var tier: int = 0
@export var base_attack: float = 1.0
@export var attack_speed: float = 1.0
@export var range: float = 400.0
@export var projectile_scene: PackedScene # Wygląd pocisku/ataku
@export var piercing: int = 1 # 1 = znika po 1 wrogu. 999 = tnie wszystkich!
@export var projectiles: int = 1
@export var crit_chance: float = 0.05 # 0.05 oznacza 5%
@export var crit_multiplier: float = 1.5
@export var status_effect: String = "" # np. "Fire", "Freeze", "Shock"
@export var mana_cost: float = 0.0 # Koszt many za jeden strzał
@export var tags: Array[String] = [] # np. ["range", "projectile"]
