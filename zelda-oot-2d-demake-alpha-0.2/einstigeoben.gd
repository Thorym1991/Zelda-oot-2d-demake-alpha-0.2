extends Area2D

# LadderArea.gd — Script für Kletterzone-Erkennung.
# Dieses Skript muss direkt an den Area2D-Nodes (Einstiegoben, Einstigunten) hängen.
# Kein Collider-Handling mehr hier: Collider-Deaktivierung erfolgt im Player beim Klettern.

func _ready() -> void:
	print("[LadderArea] ready at ", get_path())
	monitoring = true
	monitorable = true
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited",   Callable(self, "_on_body_exited"))

func _on_body_entered(body: Node) -> void:
	print("[LadderArea] body_entered: ", body.name)
	if body.is_in_group("player"):
		print("[LadderArea] Player entered, klettern_möglich = true")
		body.can_climb = true
		var btn = body.action_button
		if btn:
			btn.set_action_text("Klettern")

func _on_body_exited(body: Node) -> void:
	print("[LadderArea] body_exited: ", body.name)
	if body.is_in_group("player"):
		if body.can_climb:
			return
		print("[LadderArea] Player exited, klettern_möglich = false")
		body.klettern_möglich = false
		var btn = body.action_button
		if btn:
			btn.set_action_text("Nichts")
