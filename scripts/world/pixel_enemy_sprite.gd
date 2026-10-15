extends Sprite2D
const SPRITES := preload("res://scripts/data/pixel_enemy_sprites.gd")

func pose(kind: StringName, clock: float, moving: float, attack: float, direction: Vector2, flash: float, spawn_clock: float) -> void:
	var id := str(kind)
	var layout: Dictionary = SPRITES.LAYOUTS[id]
	var action := "attack" if attack > 0 else ("walk" if moving > 0.1 else "idle")
	var sequence: Vector2i = layout[action]
	var index := mini(sequence.y - 1, floori((1.0 - attack / 0.24) * sequence.y)) if attack > 0 else floori(clock * (9.0 if moving > 0.1 else 5.0))
	texture = SPRITES.texture_for(id)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	region_enabled = true
	region_filter_clip_enabled = true
	region_rect = SPRITES.frame_rect(id, action, maxi(0, index))
	centered = false
	flip_h = direction.x < -0.05
	var foot: Vector2 = SPRITES.foot_for(id, action, maxi(0, index))
	# Mirroring must preserve the same grounded pivot, including asymmetrical chests.
	offset = Vector2(-(region_rect.size.x - foot.x) if flip_h else -foot.x, -foot.y)
	var arrival := 0.75 + 0.25 * sin(clampf(spawn_clock / 0.35, 0, 1) * PI / 2)
	scale = Vector2.ONE * float(layout.scale) * arrival
	position = Vector2(0, sin(clock * 8) * moving * 1.5)
	self_modulate = Color(1.8, 1.8, 1.8) if flash > 0 else Color.WHITE
