extends RefCounted
const BOSSES := preload("res://scripts/data/regional_boss_art.gd")
## Original sheets remain intact. Frames use their original cell origins and foot anchors.
const SHEETS := {
	"death_lord": preload("res://assets/art/enemies/pixel/bosses/boss_ceifador.png"),
	"lava_lord": BOSSES.SHEETS.lava_lord,
	"vampire_king": BOSSES.SHEETS.vampire_king,
	"frost_guardian": BOSSES.SHEETS.frost_guardian,
	"mire_queen": BOSSES.SHEETS.mire_queen,
	"blood_monster": preload("res://assets/art/enemies/pixel/BloodMonster.png"),
	"canarinho": preload("res://assets/art/enemies/pixel/canarinho.png"),
	"spore_zombie": preload("res://assets/art/enemies/pixel/zoombi.png"),
	"azure_slime": preload("res://assets/art/enemies/pixel/slime.png"),
	"demon_a": preload("res://assets/art/enemies/pixel/Demon_A.png"),
	"loot_mimic": preload("res://assets/art/enemies/pixel/bauloot.png"),
	"red_orb": preload("res://assets/art/enemies/pixel/bolavermelha.png"),
	"barrel_beast": preload("res://assets/art/enemies/pixel/barril.png"),
	"minotaur": preload("res://assets/art/enemies/pixel/Minotaur.png")}
const LAYOUTS := {
	"death_lord": {"cell": 64, "foot": Vector2(32, 61), "scale": 2.0, "idle": Vector2i(0, 4), "walk": Vector2i(1, 6), "attack": Vector2i(6, 6)},
	"lava_lord": {"scale": 0.72, "idle": Vector2i(0, 4), "walk": Vector2i(0, 6), "attack": Vector2i(0, 6)},
	"vampire_king": {"scale": 1.0, "idle": Vector2i(0, 4), "walk": Vector2i(0, 6), "attack": Vector2i(0, 6)},
	"frost_guardian": {"scale": 0.95, "idle": Vector2i(0, 4), "walk": Vector2i(0, 6), "attack": Vector2i(0, 4)},
	"mire_queen": {"scale": 0.88, "idle": Vector2i(0, 4), "walk": Vector2i(0, 6), "attack": Vector2i(0, 5)},
	"blood_monster": {"cell": 100, "foot": Vector2(52, 58), "scale": 3.0, "idle": Vector2i(0, 6), "walk": Vector2i(1, 8), "attack": Vector2i(2, 8)},
	"canarinho": {"cell": 80, "foot": Vector2(40, 62), "scale": 1.0, "idle": Vector2i(0, 6), "walk": Vector2i(1, 8), "attack": Vector2i(5, 6)},
	"spore_zombie": {"cell": 80, "foot": Vector2(40, 64), "scale": 1.0, "idle": Vector2i(0, 6), "walk": Vector2i(1, 8), "attack": Vector2i(5, 6)},
	"azure_slime": {"cell": 96, "cell_size": Vector2i(96, 32), "foot": Vector2(52, 32), "scale": 2.0, "idle": Vector2i(0, 6), "walk": Vector2i(0, 6), "attack": Vector2i(0, 6)},
	"demon_a": {"cell": 100, "foot": Vector2(51, 59), "scale": 3.0, "idle": Vector2i(0, 6), "walk": Vector2i(1, 8), "attack": Vector2i(2, 7)},
	"loot_mimic": {"cell": 32, "foot": Vector2(12, 23), "scale": 2.0, "idle": Vector2i(0, 4), "walk": Vector2i(2, 4), "attack": Vector2i(1, 4)},
	"red_orb": {"cell": 64, "foot": Vector2(32, 52), "scale": 1.0, "idle": Vector2i(0, 6), "walk": Vector2i(0, 6), "attack": Vector2i(1, 6)},
	"barrel_beast": {"cell": 32, "foot": Vector2(16, 29), "scale": 2.0, "idle": Vector2i(0, 5), "walk": Vector2i(1, 6), "attack": Vector2i(2, 8)},
	"minotaur": {"cell": 96, "foot": Vector2(48, 64), "scale": 2.0, "idle": Vector2i(0, 5), "walk": Vector2i(1, 8), "attack": Vector2i(3, 9)}}

static func has_kind(kind: StringName) -> bool:
	return LAYOUTS.has(str(kind))

static func frame_rect(kind: String, animation: String, frame: int) -> Rect2:
	if BOSSES.POSES.has(kind):
		var frames: Array = BOSSES.POSES[kind][animation]
		var pose: Array = frames[frame % frames.size()]
		return Rect2(pose[0], pose[1], pose[2], pose[3])
	var layout: Dictionary = LAYOUTS[kind]
	var sequence: Vector2i = layout[animation]
	var cell: Vector2i = layout.get("cell_size", Vector2i(int(layout.cell), int(layout.cell)))
	var texture: Texture2D = SHEETS[kind]
	var origin := Vector2((frame % sequence.y) * cell.x, sequence.x * cell.y)
	return Rect2(origin, Vector2(minf(cell.x, texture.get_width() - origin.x), minf(cell.y, texture.get_height() - origin.y)))

static func texture_for(kind: String) -> Texture2D:
	return BOSSES.texture_for(kind) if BOSSES.SHEETS.has(kind) else SHEETS[kind]

static func foot_for(kind: String, animation: String, frame: int) -> Vector2:
	if BOSSES.POSES.has(kind):
		var frames: Array = BOSSES.POSES[kind][animation]
		var pose: Array = frames[frame % frames.size()]
		return Vector2(pose[4], pose[5])
	return LAYOUTS[kind].foot

static func portrait_for(kind: String) -> Texture2D:
	var portrait := AtlasTexture.new()
	portrait.atlas = texture_for(kind)
	portrait.region = frame_rect(kind, "idle", 0)
	return portrait
