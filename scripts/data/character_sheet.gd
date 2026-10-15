extends RefCounted
## Hand-authored crops: source charts have labels, irregular spacing and separate FX.
const SHEETS := {
	"warrior": preload("res://assets/art/characters/sheets/perso_tank.png"),
	"mage": preload("res://assets/art/characters/sheets/perso_mage.png"),
	"ranger": preload("res://assets/art/characters/sheets/perso_arqueiro.png"),
	"druid": preload("res://assets/art/characters/sheets/perso_seiva.png"),
	"assassin": preload("res://assets/art/characters/sheets/perso_loki.png")}
const HEIGHTS := {"warrior": 116.0, "mage": 112.0, "ranger": 101.0, "druid": 103.0, "assassin": 105.0}
# x, y, width, height, grounded pivot x/y. Attack effects may extend beyond the body.
const POSES := {
	"warrior": {
		"idle": [[290, 68, 87, 133, 58, 124], [377, 68, 73, 133, 45, 124], [450, 68, 87, 133, 53, 124]],
		"walk": [[552, 68, 83, 133, 54, 124], [635, 68, 79, 133, 50, 124], [714, 68, 78, 133, 50, 124], [792, 68, 78, 133, 50, 124], [870, 68, 72, 133, 45, 124], [942, 68, 82, 133, 52, 124]],
		"run": [[1051, 63, 116, 145, 77, 130], [1167, 63, 107, 145, 69, 130], [1274, 63, 104, 145, 63, 130], [1378, 63, 135, 145, 90, 136]],
		"attack": [[281, 270, 126, 131, 69, 120], [407, 270, 119, 131, 66, 120], [526, 270, 130, 131, 68, 120], [656, 270, 120, 131, 63, 121], [779, 270, 157, 132, 73, 122]],
		"special": [[938, 270, 122, 134, 66, 122], [1060, 270, 114, 134, 62, 122], [1174, 270, 109, 134, 58, 122], [1283, 270, 105, 134, 55, 121], [1388, 270, 128, 134, 64, 121]],
		"hurt": [[16, 474, 110, 137, 63, 126], [132, 474, 108, 137, 62, 126], [240, 474, 104, 137, 60, 126]],
		"death": [[16, 677, 119, 127, 68, 117], [139, 677, 109, 127, 62, 117], [253, 677, 107, 127, 61, 117], [361, 677, 105, 127, 59, 117], [470, 677, 115, 127, 58, 117], [592, 677, 137, 127, 69, 117], [733, 677, 183, 127, 91, 117]],
		"portrait": [[8, 8, 269, 351, 170, 340]], "face": [[120, 15, 112, 113, 56, 110]]},
	"mage": {
		"idle": [[285, 72, 79, 130, 48, 120], [364, 72, 69, 130, 43, 120], [433, 72, 78, 130, 47, 120]],
		"walk": [[531, 72, 91, 130, 58, 120], [622, 72, 79, 130, 48, 120], [701, 72, 79, 130, 47, 120], [780, 72, 81, 130, 49, 120], [861, 72, 71, 130, 44, 120], [932, 72, 87, 130, 53, 120]],
		"run": [[1061, 74, 110, 129, 74, 118], [1171, 74, 93, 129, 62, 118], [1264, 74, 105, 129, 68, 118], [1371, 74, 130, 129, 88, 118]],
		"attack": [[282, 267, 118, 132, 60, 120], [400, 267, 126, 132, 63, 120], [526, 260, 153, 139, 70, 128], [679, 260, 143, 139, 68, 128], [802, 277, 148, 122, 63, 113]],
		"special": [[950, 272, 132, 130, 66, 118], [1082, 272, 115, 130, 58, 118], [1197, 272, 121, 130, 57, 118], [1310, 263, 225, 146, 72, 127]],
		"hurt": [[14, 490, 112, 129, 62, 118], [128, 490, 99, 129, 55, 118], [226, 490, 103, 129, 56, 118]],
		"death": [[17, 670, 120, 123, 70, 112], [149, 670, 125, 123, 72, 112], [279, 670, 120, 123, 69, 112], [410, 670, 129, 123, 65, 112], [554, 670, 152, 123, 76, 112], [721, 670, 171, 123, 85, 112]],
		"portrait": [[18, 14, 260, 377, 155, 367]], "face": [[122, 22, 133, 135, 66, 130]]},
	"ranger": {
		"idle": [[255, 60, 77, 117, 48, 108], [332, 60, 71, 117, 43, 108], [403, 60, 72, 117, 44, 108], [475, 60, 73, 117, 44, 108]],
		"walk": [[551, 59, 85, 118, 51, 109], [636, 59, 69, 118, 43, 109], [705, 59, 72, 118, 44, 109], [777, 59, 68, 118, 43, 109], [845, 59, 71, 118, 44, 109], [916, 59, 79, 118, 48, 109]],
		"run": [[1035, 63, 115, 116, 75, 103], [1153, 63, 108, 116, 69, 105], [1260, 63, 103, 116, 66, 106], [1364, 63, 130, 116, 88, 107]],
		"attack": [[272, 243, 110, 126, 48, 117], [382, 243, 99, 126, 42, 117], [481, 243, 89, 126, 40, 117], [570, 243, 91, 126, 40, 117], [665, 243, 105, 126, 46, 117]],
		"special": [[872, 240, 102, 131, 47, 121], [974, 240, 91, 131, 44, 121], [1065, 240, 93, 131, 43, 121], [1158, 240, 91, 131, 43, 121], [1249, 240, 107, 131, 48, 121]],
		"hurt": [[17, 448, 91, 112, 52, 103], [108, 448, 78, 112, 43, 103], [186, 448, 86, 112, 47, 103]],
		"death": [[19, 635, 93, 120, 53, 109], [113, 635, 88, 120, 50, 109], [203, 635, 108, 120, 55, 109], [308, 635, 114, 120, 57, 109], [422, 635, 114, 120, 57, 109], [536, 635, 128, 120, 64, 109]],
		"portrait": [[12, 46, 264, 322, 134, 312]], "face": [[107, 47, 109, 125, 55, 120]]},
	"druid": {
		"idle": [[287, 58, 78, 114, 33, 105], [365, 56, 73, 116, 30, 107], [438, 59, 72, 113, 31, 104], [510, 59, 73, 113, 32, 104]],
		"walk": [[594, 54, 87, 118, 36, 109], [689, 54, 82, 118, 35, 109], [771, 54, 77, 118, 35, 109], [848, 54, 85, 118, 37, 109], [933, 54, 89, 118, 38, 109]],
		"run": [[1051, 55, 102, 118, 64, 108], [1153, 55, 93, 118, 59, 108], [1248, 55, 87, 118, 57, 108], [1335, 55, 91, 118, 56, 108], [1426, 55, 88, 118, 53, 108]],
		"attack": [[277, 217, 117, 122, 51, 113], [394, 217, 96, 122, 43, 113], [490, 217, 102, 122, 42, 113], [592, 217, 98, 122, 42, 113], [680, 217, 112, 122, 43, 113]],
		"special": [[908, 221, 116, 118, 47, 109], [1024, 221, 74, 118, 31, 109], [1098, 221, 69, 118, 31, 109], [1167, 221, 87, 118, 33, 109], [1262, 235, 95, 104, 52, 95]],
		"hurt": [[18, 393, 90, 118, 40, 109], [108, 393, 78, 118, 34, 109], [193, 393, 87, 118, 37, 109]],
		"death": [[17, 558, 89, 103, 40, 95], [112, 558, 81, 103, 36, 95], [198, 558, 78, 103, 34, 95], [282, 558, 95, 103, 47, 92], [386, 558, 112, 103, 56, 89], [499, 558, 95, 103, 47, 89], [597, 558, 133, 103, 66, 90]],
		"portrait": [[5, 22, 276, 315, 134, 306]], "face": [[62, 26, 158, 162, 79, 155]]},
	"assassin": {
		"idle": [[241, 58, 79, 122, 48, 112], [320, 58, 69, 122, 41, 112], [389, 58, 72, 122, 43, 112], [461, 58, 63, 122, 38, 112], [524, 58, 65, 122, 38, 112], [589, 58, 73, 122, 43, 112]],
		"walk": [[664, 57, 74, 122, 43, 113], [738, 57, 69, 122, 41, 113], [807, 57, 69, 122, 41, 113], [876, 57, 74, 122, 43, 113], [950, 57, 83, 122, 47, 113]],
		"run": [[1068, 58, 100, 121, 67, 110], [1168, 58, 85, 121, 54, 110], [1253, 58, 89, 121, 59, 110], [1342, 58, 81, 121, 53, 110], [1423, 58, 95, 121, 59, 110]],
		"attack": [[251, 241, 110, 111, 65, 100], [361, 241, 85, 111, 46, 100], [446, 241, 102, 111, 50, 101], [532, 239, 109, 113, 52, 103], [640, 241, 122, 111, 63, 101], [762, 241, 132, 111, 63, 101]],
		"special": [[898, 241, 122, 111, 70, 101], [1020, 241, 153, 111, 58, 101], [1173, 241, 109, 111, 59, 101], [1283, 241, 132, 111, 63, 101]],
		"hurt": [[9, 429, 100, 110, 59, 99], [109, 429, 96, 110, 55, 99], [205, 429, 89, 110, 51, 101]],
		"death": [[22, 602, 80, 114, 45, 104], [102, 602, 99, 114, 55, 104], [214, 602, 103, 114, 56, 104], [310, 602, 116, 114, 58, 103], [423, 602, 131, 114, 65, 103], [552, 602, 180, 114, 90, 104]],
		"portrait": [[6, 24, 240, 313, 123, 303]], "face": [[93, 30, 106, 129, 53, 124]]}}
static var textures: Dictionary = {}
static var atlases: Dictionary = {}

static func has_class(owner: String) -> bool:
	return SHEETS.has(owner)

static func texture_for(owner: String) -> Texture2D:
	if textures.has(owner): return textures[owner]
	var source: Texture2D = SHEETS[owner]
	if owner in ["warrior", "mage"]:
		textures[owner] = source
	else:
		var image := source.get_image()
		image.convert(Image.FORMAT_RGBA8)
		var pixels := image.get_data()
		for action in POSES[owner]:
			for pose in POSES[owner][action]:
				preload("res://scripts/data/sheet_background.gd").clear_connected(pixels, image.get_width(), pose)
				preload("res://scripts/data/sheet_background.gd").clear_pale_checker(pixels, image.get_width(), pose)
		var original := pixels.duplicate()
		for action in POSES[owner]:
			for pose in POSES[owner][action]:
				preload("res://scripts/data/sheet_background.gd").remove_white_fringe(pixels, original, image.get_width(), pose)
		image.set_data(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8, pixels)
		textures[owner] = ImageTexture.create_from_image(image)
	return textures[owner]

static func atlas(owner: String, action: String = "portrait", index: int = 0) -> AtlasTexture:
	var poses: Array = POSES[owner][action]
	index = clampi(index, 0, poses.size() - 1)
	var key := "%s/%s/%d" % [owner, action, index]
	if not atlases.has(key):
		var pose: Array = poses[index]
		var result := AtlasTexture.new()
		result.atlas = texture_for(owner)
		result.region = Rect2(pose[0], pose[1], pose[2], pose[3])
		result.filter_clip = true
		atlases[key] = result
	return atlases[key]

static func sample(owner: String, motion: Dictionary) -> Dictionary:
	var action := "idle"
	var progress := -1.0
	if bool(motion.get("dead", false)):
		action = "death"
		progress = clampf(float(motion.get("death_elapsed", 1.0)) / 0.65, 0, 1)
	elif bool(motion.get("attacking", false)):
		action = "special" if bool(motion.get("special", false)) else "attack"
		progress = clampf(float(motion.get("attack_progress", 0.0)), 0, 1)
	elif float(motion.get("hurt", 0.0)) > 0.0:
		action = "hurt"
		progress = clampf(1.0 - float(motion.hurt) / 0.22, 0, 1)
	elif float(motion.get("moving", 0.0)) > 0.1:
		action = "run" if bool(motion.get("running", false)) else "walk"
	var poses: Array = POSES[owner][action]
	var index := mini(poses.size() - 1, floori(progress * poses.size())) if progress >= 0 else posmod(floori(float(motion.get("time", 0.0)) * (4.0 if action == "idle" else 10.0)), poses.size())
	var pose: Array = poses[index]
	return {"action": action, "index": index, "texture": atlas(owner, action, index), "pivot": Vector2(pose[4], pose[5])}

static func equipment_pose(owner: String, motion: Dictionary) -> Array[Dictionary]:
	# These two charts have empty hands. Keep their equipped sword/shield/staff
	# models visible; the other charts already paint their class weapon in each pose.
	if owner not in ["warrior", "mage"] or bool(motion.get("dead", false)): return []
	var root := (Engine.get_main_loop() as SceneTree).root
	var id := str(motion.get("weapon_id", ""))
	if id.is_empty(): id = str(root.get_node("SaveManager").loadout_for(owner).get("weapon", ""))
	var item: EquipmentData = root.get_node("ContentCatalog").equipment.get(id)
	if item == null or item.class_id not in [&"", StringName(owner)] or item.slot != &"weapon": return []
	var models := preload("res://scripts/data/weapon_models.gd")
	var strike := sin(clampf(float(motion.get("attack_progress", 1)), 0, 1) * PI) if bool(motion.get("attacking", false)) else 0.0
	var result: Array[Dictionary] = [{"texture": models.texture_for(item, owner), "hand": Vector2(17, -49), "grip": Vector2(7, 25), "length": 68.0, "angle": -PI / 7 + strike * (0.8 if owner == "warrior" else -0.2)}]
	if owner == "warrior": result.append({"texture": models.shield_for(item), "hand": Vector2(-22, -49), "grip": Vector2(16, 16), "length": 46.0, "angle": -strike * 0.12})
	return result

static func warm_cache() -> void:
	for owner in SHEETS: texture_for(owner)
