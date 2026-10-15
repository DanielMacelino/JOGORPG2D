extends RefCounted
## Text-free atlas: every label, shortcut and hit area remains native UI.
const SHEET := preload("res://assets/art/home-menu-plaques.png")
const REGIONS := [Rect2(0, 0, 700, 349), Rect2(701, 0, 700, 349), Rect2(1402, 0, 701, 349), Rect2(0, 352, 700, 360), Rect2(701, 352, 700, 360), Rect2(1402, 352, 701, 360)]

static func paint(canvas: CanvasItem, bounds: Rect2, index: int, tint := Color.WHITE, long_button := false) -> void:
	var source: Rect2 = REGIONS[clampi(index, 0, 5)]
	if not long_button:
		canvas.draw_texture_rect_region(SHEET, bounds, source, tint)
		return
	# Preserve the end ornaments instead of stretching them across a long action.
	var source_cap := source.size.y * 0.56
	var cap := minf(bounds.size.y * 0.56, bounds.size.x * 0.2)
	canvas.draw_texture_rect_region(SHEET, Rect2(bounds.position, Vector2(cap, bounds.size.y)), Rect2(source.position, Vector2(source_cap, source.size.y)), tint)
	canvas.draw_texture_rect_region(SHEET, Rect2(bounds.position + Vector2(cap, 0), Vector2(bounds.size.x - cap * 2, bounds.size.y)), Rect2(source.position + Vector2(source_cap, 0), Vector2(source.size.x - source_cap * 2, source.size.y)), tint)
	canvas.draw_texture_rect_region(SHEET, Rect2(bounds.position + Vector2(bounds.size.x - cap, 0), Vector2(cap, bounds.size.y)), Rect2(source.position + Vector2(source.size.x - source_cap, 0), Vector2(source_cap, source.size.y)), tint)
