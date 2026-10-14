extends RefCounted
class_name ItemTiers
const ORDER := ["common", "uncommon", "rare", "epic", "legendary", "demigod", "divine"]
const NAMES := {"common": "Comum", "uncommon": "Incomum", "rare": "Raro", "epic": "Épico", "legendary": "Lendário", "demigod": "Semideus", "divine": "Deus"}
const REQUIRED_DIFFICULTIES := [0, 0, 1, 2, 3, 5, 6]
const WEIGHTS := [1.0, 0.75, 0.45, 0.20, 0.09, 0.035, 0.015]
const EQUIPMENT_SCALE := [1.0, 1.3, 1.7, 2.25, 3.0, 4.0, 5.4]
const SKILL_SCALE := [0.75, 1.0, 1.25, 1.55, 1.9, 2.3, 2.8]
static func index(id: String) -> int: return maxi(0, ORDER.find(id))
static func label(id: String) -> String: return str(NAMES.get(id, id.capitalize()))
