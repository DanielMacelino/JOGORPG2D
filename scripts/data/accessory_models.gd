extends RefCounted
## Native atlas models for existing class-bound equipment; IDs and attributes stay intact.
const SHEET := preload("res://assets/art/equipment/assets_equipamentos.png")
const HELMETS := {"warrior": [0, 9, 10, 11], "mage": [5, 6, 7, 13], "ranger": [2, 5], "assassin": [1, 5, 6, 13], "druid": [4, 14, 15], "paladin": [3, 8, 10, 11, 12]}
const BOOTS := {"warrior": [0, 1, 5, 9, 13, 14, 17, 21, 28, 30], "mage": [10, 12, 16, 20, 22, 23, 24, 27, 29, 31, 32], "ranger": [0, 2, 3, 7, 8, 15, 17, 26], "druid": [2, 3, 7, 8, 15, 17, 26], "assassin": [0, 5, 6, 11, 12, 13, 16, 18, 22, 24, 25, 29, 32], "paladin": [1, 4, 5, 6, 11, 14, 18, 19, 21, 23, 25, 26, 28, 30, 31]}
const ARMORS := {"warrior": [1, 2, 7, 13, 16, 18, 25, 29, 30], "mage": [4, 10, 11, 12, 19, 21, 22, 23, 27, 28, 31], "ranger": [0, 3, 6, 9, 15, 17, 20, 24, 26], "druid": [3, 6, 9, 15, 20, 24, 26], "assassin": [0, 5, 11, 12, 14, 19, 22, 23, 28, 31], "paladin": [1, 2, 4, 5, 7, 8, 10, 16, 18, 21, 25, 27, 29, 30]}
static var textures: Dictionary = {}

static func populate(items: Dictionary) -> void:
	for item in items.values():
		var slot := str(item.slot)
		if not RECTS.has(slot): continue
		item.accessory_visual = model_index(item, str(item.class_id), slot)

static func model_index(item: EquipmentData, owner: String, slot: String) -> int:
	var pool: Array = []
	match slot:
		"helmet": pool = HELMETS.get(owner, [])
		"boots": pool = BOOTS.get(owner, [])
		"armor": pool = ARMORS.get(owner, [])
	var seed_text := str(item.family_id) if item != null and item.family_id != &"" else (str(item.id) if item != null else owner + slot)
	var tier := item.tier_index if item != null and item.generated else (ItemTiers.index(str(item.rarity)) if item != null else 0)
	var index := posmod(seed_text.hash() + tier, pool.size() if not pool.is_empty() else RECTS[slot].size())
	return int(pool[index]) if not pool.is_empty() else index

static func texture_for(item: EquipmentData, owner: String, slot: String) -> Texture2D:
	if not RECTS.has(slot): return null
	var index := item.accessory_visual if item != null and item.accessory_visual >= 0 else model_index(item, owner, slot)
	return atlas(slot, index)

static func atlas(slot: String, index: int) -> AtlasTexture:
	index = clampi(index, 0, RECTS[slot].size() - 1)
	var key := slot + "/" + str(index)
	if not textures.has(key):
		var texture := AtlasTexture.new()
		texture.atlas = SHEET
		texture.region = RECTS[slot][index]
		texture.filter_clip = true
		textures[key] = texture
	return textures[key]
const RECTS := {
	"helmet": [Rect2(12, 43, 89, 122), Rect2(101, 43, 97, 122), Rect2(198, 22, 98, 143), Rect2(296, 22, 101, 143), Rect2(397, 22, 104, 143), Rect2(501, 22, 89, 143), Rect2(590, 22, 91, 143), Rect2(681, 22, 98, 143), Rect2(779, 22, 93, 143), Rect2(872, 22, 98, 143), Rect2(970, 22, 95, 143), Rect2(1065, 22, 86, 143), Rect2(1151, 22, 95, 143), Rect2(1246, 22, 91, 143), Rect2(1337, 22, 101, 143), Rect2(1438, 22, 94, 143)],
	"ring": [Rect2(8, 207, 78, 66), Rect2(86, 207, 76, 66), Rect2(162, 197, 72, 76), Rect2(234, 197, 69, 76), Rect2(303, 197, 76, 76), Rect2(379, 197, 75, 76), Rect2(454, 197, 75, 76), Rect2(529, 197, 73, 76), Rect2(602, 197, 63, 76), Rect2(665, 197, 61, 76), Rect2(726, 197, 65, 76), Rect2(791, 197, 71, 76), Rect2(862, 197, 73, 76), Rect2(935, 197, 96, 76), Rect2(1031, 197, 94, 76), Rect2(1125, 197, 85, 76), Rect2(1210, 197, 70, 76), Rect2(1280, 197, 70, 76), Rect2(1350, 197, 81, 76), Rect2(1431, 197, 91, 76), Rect2(15, 275, 77, 82), Rect2(92, 275, 75, 82), Rect2(167, 275, 74, 82), Rect2(241, 275, 73, 82), Rect2(314, 275, 66, 82), Rect2(380, 275, 69, 82), Rect2(449, 275, 80, 82), Rect2(529, 275, 78, 82), Rect2(607, 275, 74, 82), Rect2(681, 275, 66, 82), Rect2(747, 275, 67, 82), Rect2(814, 275, 68, 82), Rect2(882, 275, 72, 82), Rect2(954, 275, 72, 82), Rect2(1026, 275, 76, 82), Rect2(1102, 275, 76, 82), Rect2(1178, 275, 77, 82), Rect2(1255, 275, 79, 82), Rect2(1334, 275, 84, 82), Rect2(1418, 275, 87, 82)],
	"boots": [Rect2(20, 398, 90, 101), Rect2(110, 398, 83, 101), Rect2(193, 395, 87, 104), Rect2(280, 395, 87, 104), Rect2(367, 395, 87, 104), Rect2(454, 395, 84, 104), Rect2(538, 395, 87, 104), Rect2(625, 395, 87, 104), Rect2(712, 395, 84, 104), Rect2(796, 395, 81, 104), Rect2(877, 395, 88, 104), Rect2(965, 395, 94, 104), Rect2(1059, 395, 87, 104), Rect2(1146, 395, 98, 104), Rect2(1244, 395, 86, 104), Rect2(1330, 395, 88, 104), Rect2(1418, 395, 96, 104), Rect2(25, 500, 92, 103), Rect2(117, 500, 91, 103), Rect2(208, 500, 95, 103), Rect2(303, 500, 100, 103), Rect2(403, 500, 97, 103), Rect2(500, 500, 99, 103), Rect2(599, 500, 89, 103), Rect2(688, 500, 98, 103), Rect2(786, 500, 94, 103), Rect2(880, 500, 92, 103), Rect2(972, 500, 85, 103), Rect2(1057, 500, 84, 103), Rect2(1141, 500, 102, 103), Rect2(1243, 500, 97, 103), Rect2(1340, 500, 89, 103), Rect2(1429, 500, 91, 103)],
	"armor": [Rect2(15, 646, 97, 105), Rect2(112, 646, 99, 105), Rect2(211, 636, 98, 115), Rect2(309, 636, 93, 115), Rect2(402, 636, 116, 115), Rect2(518, 636, 97, 115), Rect2(615, 636, 89, 115), Rect2(704, 636, 101, 115), Rect2(805, 636, 84, 115), Rect2(889, 636, 92, 115), Rect2(981, 636, 99, 115), Rect2(1080, 636, 79, 115), Rect2(1159, 636, 83, 115), Rect2(1242, 636, 92, 115), Rect2(1334, 636, 93, 115), Rect2(1427, 636, 94, 115), Rect2(15, 751, 104, 78), Rect2(119, 751, 98, 78), Rect2(217, 751, 99, 89), Rect2(316, 751, 99, 89), Rect2(415, 751, 106, 89), Rect2(521, 751, 81, 89), Rect2(602, 751, 106, 89), Rect2(708, 751, 89, 89), Rect2(797, 751, 96, 89), Rect2(893, 751, 84, 89), Rect2(977, 751, 93, 89), Rect2(1070, 751, 94, 89), Rect2(1164, 751, 81, 89), Rect2(1245, 751, 90, 89), Rect2(1335, 751, 90, 89), Rect2(1425, 751, 96, 89)],
	"amulet": [Rect2(8, 856, 59, 84), Rect2(67, 856, 57, 84), Rect2(124, 856, 77, 84), Rect2(201, 856, 86, 84), Rect2(287, 856, 65, 84), Rect2(352, 856, 76, 84), Rect2(428, 856, 74, 84), Rect2(502, 856, 53, 84), Rect2(555, 856, 65, 84), Rect2(620, 856, 64, 84), Rect2(684, 856, 65, 84), Rect2(749, 856, 67, 84), Rect2(816, 856, 65, 84), Rect2(881, 856, 81, 84), Rect2(962, 856, 62, 84), Rect2(1024, 856, 65, 84), Rect2(1089, 856, 51, 84), Rect2(1140, 856, 50, 84), Rect2(1190, 856, 67, 84), Rect2(1257, 856, 54, 84), Rect2(1311, 856, 57, 84), Rect2(1368, 856, 75, 84), Rect2(1443, 856, 85, 84), Rect2(10, 941, 58, 77), Rect2(68, 941, 64, 77), Rect2(132, 941, 56, 77), Rect2(188, 941, 55, 77), Rect2(243, 941, 59, 77), Rect2(302, 941, 69, 77), Rect2(371, 941, 54, 77), Rect2(425, 941, 71, 77), Rect2(496, 941, 63, 77), Rect2(559, 941, 66, 77), Rect2(625, 941, 53, 77), Rect2(678, 941, 67, 77), Rect2(745, 941, 59, 77), Rect2(804, 941, 65, 77), Rect2(869, 941, 60, 77), Rect2(929, 941, 63, 77), Rect2(992, 941, 54, 77), Rect2(1046, 941, 54, 77), Rect2(1100, 941, 55, 77), Rect2(1155, 941, 55, 77), Rect2(1210, 941, 48, 77), Rect2(1258, 941, 54, 77), Rect2(1312, 941, 59, 77), Rect2(1371, 941, 58, 77), Rect2(1429, 941, 46, 77), Rect2(1475, 941, 49, 77)],
}
