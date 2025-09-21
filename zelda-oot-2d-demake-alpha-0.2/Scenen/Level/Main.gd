# res://PauseOpener.gd
extends Node

const PAUSE_MENU_SCENE := preload("res://Scenen/pause_menu.tscn")  # Pfad anpassen, falls anders

func _unhandled_input(event: InputEvent) -> void:
	# Nutzt 'pause' falls vorhanden, sonst 'Start' (falls du die Action so benannt hast)
	var pressed_pause := (InputMap.has_action("pause") and event.is_action_pressed("pause")) \
		or (InputMap.has_action("Start") and event.is_action_pressed("Start"))

	if pressed_pause:
		if get_tree().paused:
			var menu := get_tree().current_scene.get_node_or_null("PauseMenu")
			if menu and menu.has_method("_close"):
				get_viewport().set_input_as_handled()
				menu._close()
				return
			# Falls pausiert aber kein Menü gefunden → entpausen
			get_tree().paused = false
			get_viewport().set_input_as_handled()
		else:
			var m := PAUSE_MENU_SCENE.instantiate()
			m.name = "PauseMenu"  # leichter zu finden zum Schließen
			get_tree().current_scene.add_child(m)
			get_viewport().set_input_as_handled()
