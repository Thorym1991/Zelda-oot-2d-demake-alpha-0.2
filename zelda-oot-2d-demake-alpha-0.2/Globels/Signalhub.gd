extends Node

## Signale definieren ##
signal on_klettern_möglich




## Signal Übergeben ##
func emit_on_klettern_möglich()-> void:
	on_klettern_möglich.emit()
