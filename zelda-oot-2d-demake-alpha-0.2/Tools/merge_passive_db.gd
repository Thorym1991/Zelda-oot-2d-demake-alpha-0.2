@tool
extends EditorScript

# === ANPASSEN ===
const SOURCE_FOLDERS := ["res://Daten/Ausrüstung/Ausrüstung Passive/"]
const OUTPUT_DB := "res://Daten/passive_gear_db.tres"
const DB_CLASS_HINT := "PassiveGearDatabase"         # <— NEU
const ITEMS_PROP_CANDIDATES := ["Items"]             # <— exakt wie oben
const DEBUG := true
# =================

func _run() -> void:
	var db: Resource = _make_db()
	if db == null:
		push_error("Konnte kein DB-Script finden (class_name '%s')." % DB_CLASS_HINT)
		return

	# Property-Namen ermitteln (Items vs items)
	var items_prop: String = _find_items_property_name(db)
	if items_prop == "":
		push_error("In der DB wurde kein Array-Property 'Items'/'items' gefunden.")
		return
	if DEBUG: print("Nutze Property:", items_prop)

	# Array aus Quellordnern aufbauen
	var items_arr: Array = []
	for folder in SOURCE_FOLDERS:
		_scan_folder_into_array(folder, items_arr)

	# in DB schreiben
	db.set(items_prop, items_arr)

	# Zielordner sicher anlegen
	var da: DirAccess = DirAccess.open("res://")
	if da != null:
		da.make_dir_recursive("Daten")

	# speichern
	var err: int = ResourceSaver.save(db, OUTPUT_DB)  # kein FLAG_BUNDLE_RESOURCES
	if err != OK:
		push_error("Speichern fehlgeschlagen: %s (Code %d)" % [OUTPUT_DB, err])
	else:
		print("Saved to:", OUTPUT_DB, " -> ", ProjectSettings.globalize_path(OUTPUT_DB))
	if Engine.is_editor_hint():
		var fs := get_editor_interface().get_resource_filesystem()
		if fs: fs.scan()


# ===== Helpers =====

func _make_db() -> Resource:
	# 1) Script-Datei via class_name/Dateiname finden
	var script_path: String = _find_script_path_by_class(DB_CLASS_HINT)
	if script_path != "":
		if DEBUG: print("DB-Script:", script_path)
		var s: Script = load(script_path) as Script
		if s != null:
			var inst: Resource = s.new() as Resource
			if inst != null:
				return inst
			var r: Resource = Resource.new()
			r.set_script(s)
			return r

	# 2) Fallback: registrierte Klasse
	if ClassDB.class_exists(DB_CLASS_HINT):
		var inst2: Resource = ClassDB.instantiate(DB_CLASS_HINT) as Resource
		if inst2 != null:
			return inst2

	return null

func _find_items_property_name(db: Resource) -> String:
	var props: Array = db.get_property_list()
	for p in props:
		if typeof(p) != TYPE_DICTIONARY:
			continue
		var name: String = String(p.get("name", ""))
		if name in ITEMS_PROP_CANDIDATES:
			return name
	return ""

func _find_script_path_by_class(cls_hint: String) -> String:
	return _scan_for_class("res://", cls_hint)

func _scan_for_class(base: String, cls_hint: String) -> String:
	var da: DirAccess = DirAccess.open(base)
	if da == null:
		return ""
	da.list_dir_begin()
	while true:
		var f: String = da.get_next()
		if f == "":
			break
		if f.begins_with("."):
			continue
		var path: String = base.path_join(f)
		if da.current_is_dir():
			var sub: String = _scan_for_class(path, cls_hint)
			if sub != "":
				da.list_dir_end()
				return sub
		elif f.to_lower().ends_with(".gd"):
			# Dateiname passt?
			if f == (cls_hint + ".gd"):
				da.list_dir_end()
				return path
			# oder class_name im Script
			var txt: String = FileAccess.get_file_as_string(path)
			if ("class_name " + cls_hint) in txt:
				da.list_dir_end()
				return path
	da.list_dir_end()
	return ""

func _scan_folder_into_array(folder: String, out_arr: Array) -> void:
	var da: DirAccess = DirAccess.open(folder)
	if da == null:
		push_warning("Ordner nicht gefunden: %s" % folder)
		return
	if DEBUG:
		print("Scan:", folder)
	da.list_dir_begin()
	while true:
		var name: String = da.get_next()
		if name == "":
			break
		if name.begins_with("."):
			continue
		var path: String = folder.path_join(name)
		if da.current_is_dir():
			if DEBUG:
				print("  <DIR> ", name)
			_scan_folder_into_array(path, out_arr)
		elif name.to_lower().ends_with(".tres"):
			if DEBUG:
				print("  .tres ", name)
			var res: Resource = load(path) as Resource
			if res != null:
				out_arr.append(res)
			else:
				push_warning("Konnte Resource nicht laden: " + path)
	da.list_dir_end()
