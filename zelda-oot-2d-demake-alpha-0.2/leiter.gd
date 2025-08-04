extends StaticBody2D

@onready var blocker := $BlockerCollider
@onready var aufstieg := $AufstiegCollider
@onready var einstig_unten: Area2D = $Einstigunten
@onready var einstieg_oben: Area2D = $Einstiegoben

func _ready():
	#einstig_unten.body_entered.connect(_on_einstieg_unten_entered)
	#einstieg_oben.body_entered.connect(_on_einstieg_oben_entered)
	#deaktiviere_klettern()
	pass

func _on_einstieg_unten_entered(body):
	if body.name == "Player":
		Signalhub.emit_on_klettern_möglich()
		print("spiler hat mich betreten")

func _on_einstieg_oben_entered(body):
	if body.name == "Player":
		Signalhub.emit_on_klettern_möglich()
		print("spiler hat mich betreten")

func aktiviere_klettern():
	blocker.disabled = true
	aufstieg.disabled = false

func deaktiviere_klettern():
	blocker.disabled = false
	aufstieg.disabled = true
