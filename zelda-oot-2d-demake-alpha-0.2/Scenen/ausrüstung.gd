extends Control

@onready var doll: Sprite2D = $PaperdollSprite

const SHEETS := {
	# Kind
	"kid_all":        {"path":"res://Art/Spieler/paperdolls/Kind/kid_all.png",             "h":3, "v":3},
	"kid_goron":      {"path":"res://Art/Spieler/paperdolls/Kind/kid_goron_bracelet.png",  "h":2, "v":1}, # <- anpassen falls 3x1

	# Erwachsene
	"adult_green":       {"path":"res://Art/Spieler/paperdolls/Erwachsen/adult_green.png",       "h":4, "v":5},
	"adult_red":         {"path":"res://Art/Spieler/paperdolls/Erwachsen/adult_red.png",         "h":4, "v":5},
	"adult_blue":        {"path":"res://Art/Spieler/paperdolls/Erwachsen/adult_blue.png",        "h":4, "v":5},
	"adult_green_power": {"path":"res://Art/Spieler/paperdolls/Erwachsen/adult_green_power.png", "h":4, "v":5},
	"adult_red_power":   {"path":"res://Art/Spieler/paperdolls/Erwachsen/adult_red_power.png",   "h":4, "v":5},
	"adult_blue_power":  {"path":"res://Art/Spieler/paperdolls/Erwachsen/adult_blue_power.png",  "h":4, "v":5},
	"adult_green_titan": {"path":"res://Art/Spieler/paperdolls/Erwachsen/adult_green_titan.png", "h":4, "v":5},
	"adult_red_titan":   {"path":"res://Art/Spieler/paperdolls/Erwachsen/adult_red_titan.png",   "h":4, "v":5},
	"adult_blue_titan":  {"path":"res://Art/Spieler/paperdolls/Erwachsen/adult_blue_titan.png",  "h":4, "v":5},
}

func _ready() -> void:
	# Inventar-Änderungen beobachten
	if typeof(Inventar) != TYPE_NIL:
		Inventar.changed.connect(_on_inventory_changed)
	# Optional: sofort aktuelle Figur anzeigen (statt fix "kid_all")
	_on_inventory_changed()

func _on_inventory_changed() -> void:
	var key := Inventar.get_paperdoll_key()
	update_paperdoll(key, 0)

func update_paperdoll(key: String, frame: int = 0) -> void:
	if not SHEETS.has(key):
		push_warning("Unbekanntes Sheet: " + key)
		return

	var cfg := SHEETS[key] as Dictionary
	var path: String = cfg["path"]
	var tex := load(path) as Texture2D
	if tex:
		doll.texture = tex
		doll.hframes = int(cfg["h"])
		doll.vframes = int(cfg["v"])
		doll.frame = clamp(frame, 0, doll.hframes * doll.vframes - 1)
		doll.centered = true
	else:
		push_warning("Paperdoll-Texture nicht gefunden: " + path)
