@tool
extends EditorScript

# === ANPASSEN: Pfad deiner Equippable-ItemData .tres ===
const SOURCE_FOLDERS := [
"res://Daten/Ausrüstung/Aurüstung Anlegbar/"
]
const OUTPUT_DB := "res://Daten/gear_equippable_db.tres"
const DB_CLASS_HINT := "EquippableGearDatabase"
const DEBUG := true

func _run() -> void:
	var db := _make_db()
	if db == null:
		push_error("DB-Klasse '%s' nicht gefunden (EquippableGearDatabase.gd angelegt?)." % DB_CLASS_HINT)
		return

	# Items einsammeln
	var items: Array = []
	for folder in SOURCE_FOLDERS:
		_scan_folder_into_array(folder, items)

	# In DB schreiben
	db.set("Items", items)

	# Zielordner sicherstellen & speichern (ohne Bundling!)
	var da := DirAccess.open("res://")
	if da: da.make_dir_recursive("Daten")
	var err := ResourceSaver.save(db, OUTPUT_DB)
	if err != OK:
		push_error("Speichern fehlgeschlagen: %s (Code %d)" % [OUTPUT_DB, err])
	else:
		print("Equippable DB gespeichert:", OUTPUT_DB, " – Einträge:", items.size())
		if Engine.is_editor_hint():
			var fs := get_editor_interface().get_resource_filesystem()
			if fs: fs.scan()

# --- Helpers ---
func _make_db() -> Resource:
	var script_path := _find_script_path_by_class(DB_CLASS_HINT)
	if script_path != "":
		if DEBUG: print("DB-Script:", script_path)
		var s := load(script_path) as Script
		if s:
			var inst := s.new() as Resource
			if inst: return inst
			var r := Resource.new(); r.set_script(s); return r
	if ClassDB.class_exists(DB_CLASS_HINT):
		return ClassDB.instantiate(DB_CLASS_HINT) as Resource
	return null

func _find_script_path_by_class(cls: String) -> String:
	return _scan_for_class("res://", cls)

func _scan_for_class(base: String, cls: String) -> String:
	var da := DirAccess.open(base)
	if da == null: return ""
	da.list_dir_begin()
	while true:
		var f := da.get_next()
		if f == "": break
		if f.begins_with("."): continue
		var p := base.path_join(f)
		if da.current_is_dir():
			var sub := _scan_for_class(p, cls)
			if sub != "": da.list_dir_end(); return sub
		elif f.to_lower().ends_with(".gd"):
			if f == cls + ".gd": da.list_dir_end(); return p
			var txt := FileAccess.get_file_as_string(p)
			if ("class_name " + cls) in txt: da.list_dir_end(); return p
	da.list_dir_end()
	return ""

func _scan_folder_into_array(folder: String, out_arr: Array) -> void:
	var da := DirAccess.open(folder)
	if da == null:
		push_warning("Ordner nicht gefunden: %s" % folder); return
	if DEBUG: print("Scan:", folder)
	da.list_dir_begin()
	while true:
		var name := da.get_next()
		if name == "": break
		if name.begins_with("."): continue
		var path := folder.path_join(name)
		if da.current_is_dir():
			_scan_folder_into_array(path, out_arr)
		elif name.to_lower().ends_with(".tres"):
			var res := load(path) as Resource
			if res: out_arr.append(res)
	da.list_dir_end()
