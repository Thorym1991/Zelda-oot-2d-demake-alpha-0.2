extends Control

@export var db: ItemDatabase
@export var layout: InventoryLayout
@onready var grid: GridContainer = $SlotContainer

var bottle_page: int = 0
var selected_index: int = 0

# Items, die NICHT auf C gelegt werden dürfen (Beispiel)
const C_DISALLOW := {
	"schwert": true,
	"schild": true
}



func _ready() -> void:
	call_deferred("_focus_first_slot")

func _on_slot_focus_entered(slot: Control) -> void:
	# index des fokussierten Slots in der Grid-Reihenfolge
	var slots := grid.get_children()
	var i := slots.find(slot)
	if i != -1:
		selected_index = i


func _focus_first_slot() -> void:
	_init_slot_focus()
	_select_slot(0)


	InventoryState.owned = {
		"deku_stab": 10,
		"bogen": 30,
		"bombe": 10
	}
	InventoryState.variants = {
		"bogen": "Feuer"
	}
	update_inventory()
	
	#call_deferred("_focus_first_slot")
	
	_init_slot_focus()
	_select_slot(0)

func _init_slot_focus() -> void:
	for s in grid.get_children():
		if s is Control:
			s.focus_mode = Control.FOCUS_ALL
			# Focus-Änderung tracken
			if not s.focus_entered.is_connected(Callable(self, "_on_slot_focus_entered").bind(s)):
				s.focus_entered.connect(Callable(self, "_on_slot_focus_entered").bind(s))

func _select_slot(i: int) -> void:
	var slots := grid.get_children()
	if slots.is_empty(): return
	selected_index = clamp(i, 0, slots.size() - 1)
	(slots[selected_index] as Control).grab_focus()

func _move_selection(dx: int, dy: int) -> void:
	var slots := grid.get_children()
	if slots.is_empty(): return
	var cols := grid.columns
	var rows := int(ceil(float(slots.size()) / cols))

	var row := selected_index / cols
	var col := selected_index % cols

	row = clamp(row + dy, 0, rows - 1)
	col = clamp(col + dx, 0, cols - 1)

	var next := row * cols + col
	if next >= slots.size():
		next = min(row * cols + (cols - 1), slots.size() - 1)
	_select_slot(next)


func _get_item_for_slot(slot_index: int) -> String:
	if slot_index < 0 or slot_index >= layout.slots.size():
		return ""
	var spec: String = layout.slots[slot_index]

	if spec.begins_with(":"):
		match spec:
			":bottle":
				var col: int = slot_index % grid.columns
				if col > 3: return ""
				var idx: int = bottle_page * 4 + col
				if idx < 0 or idx >= InventoryState.bottles.size():
					return ""
				var b: Dictionary = InventoryState.bottles[idx]
				return String(b.get("id", ""))
			":trade":
				return InventoryState.current_trade
			":mask":
				return InventoryState.current_mask
		return ""
	return spec

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	# Navigation (dein bestehender Code)
	if event.is_action_pressed("right"):
		_move_selection(1, 0); get_viewport().set_input_as_handled()
	elif event.is_action_pressed("left"):
		_move_selection(-1, 0); get_viewport().set_input_as_handled()
	elif event.is_action_pressed("down"):
		_move_selection(0, 1); get_viewport().set_input_as_handled()
	elif event.is_action_pressed("up"):
		_move_selection(0, -1); get_viewport().set_input_as_handled()

	# ── NEU: C-Mapping ─────────────────────────────
	elif event.is_action_pressed("item1_Linkes"):
		get_viewport().set_input_as_handled()
		_map_selected_to_c("left")
	elif event.is_action_pressed("item2_Unten"):
		get_viewport().set_input_as_handled()
		_map_selected_to_c("down")
	elif event.is_action_pressed("item3_Rechts"):
		get_viewport().set_input_as_handled()
		_map_selected_to_c("right")
	# ───────────────────────────────────────────────



	# WICHTIG: kein accept_event() außerhalb der ifs!



	#InventoryState.changed.connect(update_inventory)
	#update_inventory()

func update_inventory() -> void:
	var slot_nodes: Array[Node] = grid.get_children()
	var count: int = min(slot_nodes.size(), layout.slots.size())
	for i: int in count:
		var spec: String = layout.slots[i]
		var slot: Node = slot_nodes[i]
		if spec.begins_with(":"):
			match spec:
				":bottle":
					_fill_bottle_slot(slot, i)
				":trade":
					_fill_trade_slot(slot)
				":mask":
					_fill_mask_slot(slot)
		else:
			_fill_fixed(slot, spec)

func _fill_fixed(slot: Node, id: String) -> void:
	var item: ItemData = db.get_item(id)
	if item == null:
		slot.clear_item(); return

	# --- Variante für's MENÜ bestimmen ---
	var variant: String = "default"
	if id != "bogen":
		variant = String(InventoryState.variants.get(id, "default"))

	var tex: Texture2D = db.get_icon(id, variant)
	if tex == null:
		slot.clear_item(); return

	# --- Menge bestimmen ---
	var amount: int = 1
	if id == "bogen":
		amount = InventoryState.arrows           # << Pfeile anzeigen
	elif item.stackable:
		amount = InventoryState.get_amount(id)

	slot.set_item(id, tex, amount)

	# optisches Ausgrauen, falls nicht im Besitz
	var owned := (id == "bogen") or InventoryState.has(id)  # Bogen-Icon darf immer sichtbar sein
	slot.modulate = Color(1,1,1,1) if owned else Color(1,1,1,0.35)



func _fill_bottle_slot(slot: Node, slot_index: int) -> void:
	var list: Array = InventoryState.bottles
	if list.is_empty():
		slot.clear_item()
		return

	var col: int = slot_index % 6
	if col > 3:
		slot.clear_item()
		return

	var idx: int = bottle_page * 4 + col
	if idx >= list.size():
		slot.clear_item()
		return

	# list[idx] ist ein Dictionary { "id": String, "variant": String }
	var b: Dictionary = list[idx]
	var bid: String = String(b.get("id", ""))
	var bvar: String = String(b.get("variant", "default"))
	if bid == "":
		slot.clear_item()
		return

	var tex: Texture2D = db.get_icon(bid, bvar)
	slot.set_item(bid, tex, 1)

func _fill_trade_slot(slot: Node) -> void:
	var id: String = InventoryState.current_trade
	if id == "":
		slot.clear_item()
		return
	var tex: Texture2D = db.get_icon(id)
	slot.set_item(id, tex, 1)

func _fill_mask_slot(slot: Node) -> void:
	var id: String = InventoryState.current_mask
	if id == "":
		slot.clear_item()
		return
	var tex: Texture2D = db.get_icon(id)
	slot.set_item(id, tex, 1)

# ─────────────────────────────────────────────────────────────
# Ermittelt die Item-ID für den aktuell markierten Slot
func _get_item_for_selected_slot() -> String:
	if selected_index < 0 or selected_index >= layout.slots.size():
		return ""
	var spec: String = layout.slots[selected_index]

	# Spezial-Slots aus deinem Layout behandeln
	if spec.begins_with(":"):
		match spec:
			":bottle":
				# gleiche Logik wie in _fill_bottle_slot
				var col: int = selected_index % grid.columns
				if col > 3: return ""
				var idx: int = bottle_page * 4 + col
				if idx < 0 or idx >= InventoryState.bottles.size():
					return ""
				var b: Dictionary = InventoryState.bottles[idx]
				return String(b.get("id", ""))
			":trade":
				return InventoryState.current_trade
			":mask":
				return InventoryState.current_mask
		return ""
	
	# feste Slots
	return spec


func _is_allowed_on_c(id: String) -> bool:
	return id != "" and not C_DISALLOW.has(id)


func _map_selected_to_c(dir: String) -> void:
	var id := _get_item_for_selected_slot()
	if id == "":
		print("Kein Item in diesem Slot.")
		return
	if not _is_allowed_on_c(id):
		print(id, " darf nicht auf C-", dir, " gelegt werden.")
		return
	# Nur mappen, wenn im Besitz (Bogen-Icon darf immer, Benutzung checkt Pfeile separat)
	if id != "bogen" and not InventoryState.has(id):
		print("Nicht im Besitz: ", id)
		return

	InventoryState.set_equip_c(dir, id)  # emit_signal("changed") kommt aus dem Setter
	print("Mapped ", id, " -> C-", dir)
