extends Resource
class_name EquipmentDatabase

@export var equipment: Array[EquipmentData] = []   # Alle Schwerter, Schilde usw.
@export var upgrades: Array[UpgradeData] = []      # Alle Upgrades (Taschen, Schuppen usw.)

func get_equipment(id: String) -> EquipmentData:
	for e in equipment:
		if e.id == id:
			return e
	return null

func get_upgrade(id: String) -> UpgradeData:
	for u in upgrades:
		if u.id == id:
			return u
	return null

# Praktisch: alle Upgrades eines Typs
func get_upgrades_for(kind: String) -> Array[UpgradeData]:
	var res: Array[UpgradeData] = []
	for u in upgrades:
		if u.kind == kind:
			res.append(u)
	return res
