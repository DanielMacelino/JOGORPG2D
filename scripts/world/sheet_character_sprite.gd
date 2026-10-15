extends Sprite2D
const SHEET := preload("res://scripts/data/character_sheet.gd")

func pose(owner: String, motion: Dictionary, tint: Color, body_height: float = 45.0, ground := Vector2(0, 10)) -> void:
	visible = SHEET.has_class(owner)
	if not visible: return
	var frame := SHEET.sample(owner, motion)
	texture = frame.texture
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	centered = false
	var direction: Vector2 = motion.get("attack_direction", Vector2.RIGHT) if bool(motion.get("attacking", false)) else motion.get("facing", Vector2.RIGHT)
	flip_h = direction.x < -0.05
	var pivot: Vector2 = frame.pivot
	offset = Vector2(-(texture.get_width() - pivot.x) if flip_h else -pivot.x, -pivot.y)
	scale = Vector2.ONE * body_height / float(SHEET.HEIGHTS[owner])
	position = ground
	self_modulate = tint
	set_meta("animation", frame.action)
	set_meta("frame", frame.index)
	var equipment := SHEET.equipment_pose(owner, motion)
	for index in 2:
		var child := get_node_or_null("EquippedModel" + str(index)) as Sprite2D
		if child == null:
			child = Sprite2D.new()
			child.name = "EquippedModel" + str(index)
			child.centered = false
			add_child(child)
		child.visible = index < equipment.size()
		if not child.visible: continue
		var model: Dictionary = equipment[index]
		child.texture = model.texture
		child.self_modulate = tint
		child.offset = -Vector2(model.grip)
		child.scale = Vector2.ONE * float(model.length) / 32.0
		child.scale.x *= -1 if flip_h else 1
		child.position = Vector2(model.hand) * Vector2(-1 if flip_h else 1, 1)
		child.rotation = float(model.angle) * (-1 if flip_h else 1)
