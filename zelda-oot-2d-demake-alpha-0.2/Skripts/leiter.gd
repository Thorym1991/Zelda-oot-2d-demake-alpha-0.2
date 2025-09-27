extends Area2D

# LadderArea.gd — Script für Kletterzone-Erkennung.
# Dieses Skript muss direkt an den Area2D-Nodes (Einstiegoben, Einstigunten) hängen.
# Kein Collider-Handling mehr hier: Collider-Deaktivierung erfolgt im Player beim Klettern.

func _ready() -> void:
	monitoring = true
	monitorable = true
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited",   Callable(self, "_on_body_exited"))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		# ruft Player._on_area_entered(area) auf, dort wird climb_zone_count erhöht
		if body.has_method("_on_area_entered"):
			body._on_area_entered(self)

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		# ruft Player._on_area_exited(area) auf, dort wird climb_zone_count verringert
		if body.has_method("_on_area_exited"):
			body._on_area_exited(self)
