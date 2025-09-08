extends CanvasLayer
# Godot 4 Pause Menu (Carousel)
# Required InputMap actions:
#  - ui_cancel (close)
#  - menu_prev_tab (previous tab)
#  - menu_next_tab (next tab)

@onready var root: Control = $Root
@onready var panels = [
	$Root/Item,
	$Root/Ausrüstung,
	$"Root/Quest-Status",
	$Root/Karte
]

var sfx_switch: AudioStreamPlayer = null
var index := 0
var switching := false

func _ready() -> void:
	# Optional SFX player (if present)
	if has_node("Root/SfxSwitch"):
		sfx_switch = $Root/SfxSwitch

	# Process input while the tree is paused
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	get_tree().paused = true

	_show_only(index, true)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Start"):  # oder "Start", wenn so benannt
		# optional, aber ok:
		get_viewport().set_input_as_handled()
		_close()
		return
	elif event.is_action_pressed("menu_next_tab"):
		_switch(1)
	elif event.is_action_pressed("menu_prev_tab"):
		_switch(-1)

func _switch(dir: int) -> void:
	if switching:
		return
	switching = true
	var old := index
	index = posmod(index + dir, panels.size())
	_animate_swap(panels[old], panels[index], dir)
	if sfx_switch:
		sfx_switch.play()

func _close() -> void:
	queue_free()
	get_tree().paused = false

func _show_only(i: int, instant: bool = false) -> void:
	for p in panels:
		p.visible = false
		p.modulate.a = 1.0
		p.position = _centered_pos(p)
		p.scale = Vector2.ONE
	panels[i].visible = true
	if instant:
		panels[i].position = _centered_pos(panels[i])

func _centered_pos(ctrl: Control) -> Vector2:
	var rect := root.get_rect()
	var size := ctrl.size
	return Vector2(rect.size.x * 0.5 - size.x * 0.5, rect.size.y * 0.5 - size.y * 0.5)

func _animate_swap(out: Control, inn: Control, dir: int) -> void:
	inn.visible = true
	inn.modulate.a = 0.0
	out.position = _centered_pos(out)
	inn.position = _centered_pos(inn) + Vector2(dir * 64, 0)

	var t := create_tween()
	t.set_parallel(true)

	# Old panel out
	t.tween_property(out, "modulate:a", 0.0, 0.12)
	t.tween_property(out, "position", _centered_pos(out) + Vector2(-dir * 64, 0), 0.12)
	t.tween_property(out, "scale", Vector2(0.98, 0.98), 0.12)

	# New panel in
	t.tween_property(inn, "modulate:a", 1.0, 0.12)
	t.tween_property(inn, "position", _centered_pos(inn), 0.12)
	t.tween_property(inn, "scale", Vector2(1.02, 1.02), 0.12)

	t.set_parallel(false)
	t.tween_callback(Callable(self, "_end_swap").bind(out, inn))

func _end_swap(out: Control, inn: Control) -> void:
	out.visible = false
	inn.scale = Vector2.ONE
	switching = false
