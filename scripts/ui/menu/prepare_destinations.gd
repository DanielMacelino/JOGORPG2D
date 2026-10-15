extends RefCounted
## Six independent illustrations; crop boundaries never include a neighboring card.
const IMAGE := preload("res://assets/art/prepare-destinations.png")
const CELLS := {"characters": Vector2i(0, 0), "inventory": Vector2i(1, 0), "talents": Vector2i(2, 0), "upgrades": Vector2i(0, 1), "forge": Vector2i(1, 1), "relics": Vector2i(2, 1)}
const FOCAL := {"characters": Vector2(0.5, 0.58), "inventory": Vector2(0.5, 0.43), "talents": Vector2(0.5, 0.43), "upgrades": Vector2(0.5, 0.52), "forge": Vector2(0.52, 0.61), "relics": Vector2(0.5, 0.49)}
static var textures: Dictionary = {}

static func texture_for(page: String) -> AtlasTexture:
	if not textures.has(page):
		var cell: Vector2i = CELLS.get(page, Vector2i.ZERO)
		var left := floori(cell.x * IMAGE.get_width() / 3.0) + 2
		var right := floori((cell.x + 1) * IMAGE.get_width() / 3.0) - 2
		var top := floori(cell.y * IMAGE.get_height() / 2.0) + 2
		var bottom := floori((cell.y + 1) * IMAGE.get_height() / 2.0) - 2
		var texture := AtlasTexture.new()
		texture.atlas = IMAGE
		texture.region = Rect2(left, top, right - left, bottom - top)
		texture.filter_clip = true
		textures[page] = texture
	return textures[page]
