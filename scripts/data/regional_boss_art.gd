extends RefCounted
## Irregular pose charts need individual crops, not an assumed square grid.
const SHEETS := {
	"lava_lord": preload("res://assets/art/enemies/pixel/bosses/boss_geografo.png"),
	"vampire_king": preload("res://assets/art/enemies/pixel/bosses/boss_rei.png"),
	"frost_guardian": preload("res://assets/art/enemies/pixel/bosses/boss_lobo.png"),
	"mire_queen": preload("res://assets/art/enemies/pixel/bosses/boss_rainha.png")}
# Each pose stores source rectangle and grounded pivot within that rectangle.
const POSES := {
	"lava_lord": {
		"idle": [[360, 0, 150, 195, 80, 180], [510, 0, 145, 195, 75, 180], [655, 0, 145, 195, 75, 180], [800, 0, 145, 195, 72, 180]],
		"walk": [[355, 357, 137, 175, 71, 153], [498, 357, 136, 175, 67, 153], [645, 357, 135, 175, 67, 153], [785, 357, 140, 175, 72, 153], [940, 357, 132, 175, 66, 156], [1085, 357, 142, 175, 72, 165]],
		"attack": [[345, 535, 137, 167, 70, 142], [488, 520, 128, 182, 65, 160], [615, 535, 152, 167, 74, 151], [775, 535, 153, 167, 77, 150], [935, 535, 137, 167, 68, 150], [1083, 535, 149, 175, 74, 159]]},
	"vampire_king": {
		"idle": [[378, 8, 108, 139, 53, 126], [492, 8, 112, 139, 57, 126], [613, 8, 112, 139, 57, 126], [736, 8, 112, 139, 57, 126]],
		"walk": [[360, 304, 114, 131, 56, 115], [475, 304, 114, 131, 56, 115], [599, 304, 114, 131, 56, 115], [723, 304, 114, 131, 56, 115], [844, 304, 112, 131, 55, 115], [972, 304, 111, 131, 55, 115]],
		"attack": [[325, 437, 120, 134, 53, 118], [495, 437, 126, 134, 62, 119], [660, 437, 126, 134, 63, 121], [826, 437, 170, 134, 63, 122], [1030, 433, 135, 138, 67, 125], [1180, 437, 121, 136, 60, 123]]},
	"frost_guardian": {
		"idle": [[429, 30, 96, 144, 47, 130], [531, 30, 103, 144, 51, 130], [654, 30, 105, 144, 52, 130], [790, 30, 111, 144, 55, 130]],
		"walk": [[396, 341, 151, 136, 76, 118], [538, 341, 144, 136, 72, 120], [675, 341, 151, 136, 75, 120], [811, 341, 151, 136, 75, 119], [946, 341, 144, 136, 72, 124], [1078, 341, 147, 136, 73, 124]],
		"attack": [[8, 500, 170, 155, 86, 139], [178, 500, 185, 155, 90, 139], [370, 500, 205, 155, 95, 135], [785, 495, 182, 156, 90, 138]]},
	"mire_queen": {
		"idle": [[386, 24, 133, 160, 66, 147], [522, 24, 142, 160, 71, 147], [660, 24, 135, 160, 67, 147], [790, 24, 135, 160, 67, 145]],
		"walk": [[393, 190, 123, 150, 61, 136], [518, 190, 152, 150, 76, 135], [662, 190, 156, 150, 78, 136], [822, 190, 146, 150, 73, 135], [973, 190, 152, 150, 76, 135], [1146, 190, 151, 150, 75, 135]],
		"attack": [[5, 480, 175, 170, 85, 156], [178, 490, 175, 160, 85, 146], [350, 494, 192, 153, 92, 134], [546, 505, 224, 145, 112, 128], [763, 508, 174, 144, 87, 129]]}}
static var cache: Dictionary = {}

static func texture_for(kind: String) -> Texture2D:
	if cache.has(kind): return cache[kind]
	var source: Texture2D = SHEETS[kind]
	if kind == "lava_lord":
		cache[kind] = source
		return source
	# These three source PNGs contain an opaque checkerboard. Remove only light,
	# neutral pixels connected to each crop's border; enclosed fur/armor stay white.
	var image := source.get_image()
	image.convert(Image.FORMAT_RGBA8)
	var pixels := image.get_data()
	for action in POSES[kind]:
		for pose in POSES[kind][action]:
			preload("res://scripts/data/sheet_background.gd").clear_connected(pixels, image.get_width(), pose)
	image.set_data(image.get_width(), image.get_height(), false, Image.FORMAT_RGBA8, pixels)
	cache[kind] = ImageTexture.create_from_image(image)
	return cache[kind]

static func warm_cache() -> void:
	for kind in SHEETS: texture_for(kind)
