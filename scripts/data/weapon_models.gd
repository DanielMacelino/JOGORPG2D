extends RefCounted
## Native AtlasTexture regions; original sheet pixels and equipment IDs remain intact.
const SHEET := preload("res://assets/art/equipment/armsmodels.png")
const COLUMNS := {"warrior": 0, "paladin": 0, "mage": 1, "druid": 2, "ranger": 3, "assassin": 6}
const KINDS := {"warrior": "sword", "paladin": "sword", "mage": "staff", "druid": "roots", "ranger": "bow", "assassin": "daggers"}
const DAGGER_ROWS := [4, 7, 8, 10, 12, 10, 12]
static var textures: Dictionary = {}

static func atlas(column: int, row: int) -> AtlasTexture:
	var key := Vector2i(column, row)
	if not textures.has(key):
		var texture := AtlasTexture.new()
		texture.atlas = SHEET
		texture.region = Rect2(column * 32, row * 32, 32, 32)
		texture.filter_clip = true
		textures[key] = texture
	return textures[key]

static func evolution_row(item: EquipmentData) -> int:
	if item == null: return 0
	var tier := item.tier_index if item.generated else ItemTiers.index(str(item.rarity))
	var variant := int(str(item.family_id).get_slice("_", str(item.family_id).get_slice_count("_") - 1)) % 2 if item.generated else 0
	return clampi(tier * 2 + variant, 0, 12)

static func cell_for(item: EquipmentData, owner: String) -> Vector2i:
	if item != null and item.visual_column >= 0: return Vector2i(item.visual_column, item.visual_row)
	if item != null and item.slot != &"weapon": return Vector2i(-1, -1)
	var row := evolution_row(item)
	if owner == "assassin": row = DAGGER_ROWS[clampi(item.tier_index if item != null and item.generated else (ItemTiers.index(str(item.rarity)) if item != null else 0), 0, 6)]
	return Vector2i(int(COLUMNS.get(owner, 0)), row)

static func texture_for(item: EquipmentData, owner: String) -> Texture2D:
	var cell := cell_for(item, owner)
	return atlas(cell.x, cell.y) if cell.x >= 0 else null

static func shield_for(item: EquipmentData) -> Texture2D:
	return atlas(item.shield_visual_column, item.shield_visual_row) if item != null and item.shield_visual_column >= 0 else atlas(4, evolution_row(item))

static func kind_for(item: EquipmentData, owner: String = "warrior") -> String:
	return str(item.weapon_kind) if item != null and item.weapon_kind != &"" else str(KINDS.get(owner, "sword"))
