extends Resource
class_name UpgradeData

@export var id: String = ""             # z. B. "bomben_tasche_1"
@export var name: String = ""           # Anzeigename
@export var icon: Texture2D             # Icon für Menü
@export var kind: String = ""           # z. B. "bomben", "munition", "rubine", "schuppen"
@export var tier: int = 1               # Stufe (1 = Basis, 2 = Upgrade usw.)
@export var capacity: int = 0           # Max. Anzahl, die diese Stufe erlaubt
@export var description: String = ""    # Text im Menü
@export var Kind: bool
@export var Erwachsen: bool
@export var Beide:bool
