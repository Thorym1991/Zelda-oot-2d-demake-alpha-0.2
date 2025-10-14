extends CanvasLayer
# Godot 4 Pause Menu (Carousel)
# Required InputMap actions:
#  - ui_cancel (close)
#  - menu_prev_tab (previous tab)
#  - menu_next_tab (next tab)
@onready var root: Control = $Root
@onready var panels: Array[Control] = [
	$Root/Item as Control,
	$Root/Ausrüstung as Control,
	$"Root/Quest-Status" as Control,
	$Root/Karte as Control
]

var sfx_switch: AudioStreamPlayer = null
var index := 0
var switching := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	get_tree().paused = true

	ui_bus.menu_open = true
	ui_bus.menu_opened.emit()

	_show_only(index, true)

	# >>> NEU: Erst-Boost, falls Item-Tab zuerst sichtbar ist
	await get_tree().process_frame
	_bootstrap_focus_for(panels[index])

func _close() -> void:
	# >>> NEU: UIBus flag + Signal zurücksetzen <<<
	ui_bus.menu_open = false
	ui_bus.menu_closed.emit()

	get_tree().paused = false
	queue_free()



func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("Start") or event.is_action_pressed("ui_cancel"):
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
	# >>> NEU: Sobald der neue Tab sichtbar ist, Fokus setzen
	_bootstrap_focus_for(inn)

func _use_item(id: String) -> void:
	if id == "":
		return

	match id:
		"bogen":
			if Inventar.arrows <= 0:
				return
			# TODO: Pfeil instanzieren & schießen
			Inventar.set_arrows(Inventar.arrows - 1)
			Inventar.emit_signal("changed")  # HUD updaten

		"bombe":
			var n: int = Inventar.get_amount("bombe")
			if n <= 0:
				return
			# TODO: Bombe instanzieren & werfen
			Inventar.set_amount("bombe", n - 1)
			Inventar.emit_signal("changed")

		"deku_nuss":
			var m: int = Inventar.get_amount("deku_nuss")
			if m <= 0:
				return
			# TODO: Effekt auslösen
			Inventar.set_amount("deku_nuss", m - 1)
			Inventar.emit_signal("changed")

		_:
			print("Benutze Item:", id)


func _first_focusable_in(local_root: Node) -> TextureButton:
	if local_root is TextureButton:
		var b: TextureButton = local_root as TextureButton
		if b.visible and b.focus_mode != Control.FOCUS_NONE and not b.disabled:
			return b
	if local_root is Control and (local_root as Control).visible:
		for c in (local_root as Control).get_children():
			var found: TextureButton = _first_focusable_in(c as Node)
			if found != null:
				return found
	return null


func _call_force_focus_in(panel: Node) -> bool:
	# 1) direkt am Panel?
	if panel != null and panel.has_method("_force_focus_bootstrap"):
		panel._force_focus_bootstrap()
		return true

	# 2) Tiefensuche: erstes Kind mit der Methode
	var queue: Array[Node] = []
	queue.append(panel)

	while not queue.is_empty():
		var n: Node = queue.pop_front() as Node
		if n != null and n.has_method("_force_focus_bootstrap"):
			n._force_focus_bootstrap()
			return true
		for c in n.get_children():
			queue.append(c as Node)
	return false



func _bootstrap_focus_for(panel: Control) -> void:
	if panel == null or not panel.visible:
		return
	# Warte etwas, bis Kinder aufgebaut/animiert sind
	await get_tree().process_frame
	await get_tree().process_frame

	# Spezifische Methode im Panel-Baum suchen und aufrufen
	if _call_force_focus_in(panel):
		return

	# Fallback: erstes fokussierbares Button-Kind
	var btn := _first_focusable_in(panel)
	if btn != null:
		btn.grab_focus()
