extends Area2D

# LadderArea.gd — Script für Kletterzone-Erkennung.
# An dieses Skript gehören deine beiden Area2D-Nodes (Einstiegoben, Einstigunten).
# Stelle sicher, dass jede Area2D ein Kind namens 'BlockerCollider' (CollisionShape2D) besitzt.
# Deaktiviert beim Klettern auch die Leiter-Hauptkollision.

@onready var blocker_collider: CollisionShape2D = get_node_or_null("../BlockerCollider")
# Haupt-CollisionShape der Leiter
@onready var ladder_collider: CollisionShape2D = get_parent().get_node_or_null("CollisionShape2D")

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
		body.klettern_möglich = true
		# BlockerCollider an Spitze/Ende deaktivieren
		if blocker_collider:
			blocker_collider.disabled = true
		# Haupt-Collider deaktivieren, damit Leiter nicht blockt
		if ladder_collider:
			ladder_collider.disabled = true
		if body.action_button:
			body.action_button.set_action_text("Klettern")

func _on_body_exited(body: Node) -> void:
	print("[LadderArea] body_exited: ", body.name)
	if body.is_in_group("player"):
		# Solange gerade geklettert wird, kein Exit forcieren
		if body.ist_am_klettern:
			return
		print("[LadderArea] Player exited, klettern_möglich = false")
		body.klettern_möglich = false
		# Reaktiviere alle Collider
		if blocker_collider:
			blocker_collider.disabled = false
		if ladder_collider:
			ladder_collider.disabled = false
		if body.action_button:
			body.action_button.set_action_text("Nichts")
