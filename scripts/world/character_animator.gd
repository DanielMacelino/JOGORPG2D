extends RefCounted
const MODELS := preload("res://scripts/data/weapon_models.gd")
const SHEET := preload("res://scripts/data/character_sheet.gd")
## Joint animation uses the original portrait's paths, colors and proportions.
const LAYERS := {
	"warrior": {
		"cape": preload("res://assets/art/animations/warrior/cape.svg"),
		"left_leg": preload("res://assets/art/animations/warrior/left_leg.svg"),
		"right_leg": preload("res://assets/art/animations/warrior/right_leg.svg"),
		"body": preload("res://assets/art/animations/warrior/body.svg"),
		"left_arm": preload("res://assets/art/animations/warrior/left_arm.svg"),
		"right_arm": preload("res://assets/art/animations/warrior/right_arm.svg"),
		"left_weapon": preload("res://assets/art/animations/warrior/left_weapon.svg"),
		"weapon": preload("res://assets/art/animations/warrior/weapon.svg"),
		"head": preload("res://assets/art/animations/warrior/head.svg")
	},
	"mage": {
		"cape": preload("res://assets/art/animations/mage/cape.svg"),
		"left_leg": preload("res://assets/art/animations/mage/left_leg.svg"),
		"right_leg": preload("res://assets/art/animations/mage/right_leg.svg"),
		"body": preload("res://assets/art/animations/mage/body.svg"),
		"left_arm": preload("res://assets/art/animations/mage/left_arm.svg"),
		"right_arm": preload("res://assets/art/animations/mage/right_arm.svg"),
		"left_weapon": preload("res://assets/art/animations/mage/left_weapon.svg"),
		"weapon": preload("res://assets/art/animations/mage/weapon.svg"),
		"head": preload("res://assets/art/animations/mage/head.svg")
	},
	"ranger": {
		"cape": preload("res://assets/art/animations/ranger/cape.svg"),
		"left_leg": preload("res://assets/art/animations/ranger/left_leg.svg"),
		"right_leg": preload("res://assets/art/animations/ranger/right_leg.svg"),
		"body": preload("res://assets/art/animations/ranger/body.svg"),
		"left_arm": preload("res://assets/art/animations/ranger/left_arm.svg"),
		"right_arm": preload("res://assets/art/animations/ranger/right_arm.svg"),
		"left_weapon": preload("res://assets/art/animations/ranger/left_weapon.svg"),
		"weapon": preload("res://assets/art/animations/ranger/weapon.svg"),
		"head": preload("res://assets/art/animations/ranger/head.svg")
	},
	"assassin": {
		"cape": preload("res://assets/art/animations/assassin/cape.svg"),
		"left_leg": preload("res://assets/art/animations/assassin/left_leg.svg"),
		"right_leg": preload("res://assets/art/animations/assassin/right_leg.svg"),
		"body": preload("res://assets/art/animations/assassin/body.svg"),
		"left_arm": preload("res://assets/art/animations/assassin/left_arm.svg"),
		"right_arm": preload("res://assets/art/animations/assassin/right_arm.svg"),
		"left_weapon": preload("res://assets/art/animations/assassin/left_weapon.svg"),
		"weapon": preload("res://assets/art/animations/assassin/weapon.svg"),
		"head": preload("res://assets/art/animations/assassin/head.svg")
	},
	"druid": {
		"cape": preload("res://assets/art/animations/druid/cape.svg"),
		"left_leg": preload("res://assets/art/animations/druid/left_leg.svg"),
		"right_leg": preload("res://assets/art/animations/druid/right_leg.svg"),
		"body": preload("res://assets/art/animations/druid/body.svg"),
		"left_arm": preload("res://assets/art/animations/druid/left_arm.svg"),
		"right_arm": preload("res://assets/art/animations/druid/right_arm.svg"),
		"left_weapon": preload("res://assets/art/animations/druid/left_weapon.svg"),
		"weapon": preload("res://assets/art/animations/druid/weapon.svg"),
		"head": preload("res://assets/art/animations/druid/head.svg")
	},
	"paladin": {
		"cape": preload("res://assets/art/animations/paladin/cape.svg"),
		"left_leg": preload("res://assets/art/animations/paladin/left_leg.svg"),
		"right_leg": preload("res://assets/art/animations/paladin/right_leg.svg"),
		"body": preload("res://assets/art/animations/paladin/body.svg"),
		"left_arm": preload("res://assets/art/animations/paladin/left_arm.svg"),
		"right_arm": preload("res://assets/art/animations/paladin/right_arm.svg"),
		"left_weapon": preload("res://assets/art/animations/paladin/left_weapon.svg"),
		"weapon": preload("res://assets/art/animations/paladin/weapon.svg"),
		"head": preload("res://assets/art/animations/paladin/head.svg")
	}
}

const PIVOTS := {"cape": Vector2(120, 120), "left_leg": Vector2(104, 216), "right_leg": Vector2(147, 214), "body": Vector2(120, 200), "left_arm": Vector2(82, 150), "right_arm": Vector2(144, 150), "left_weapon": Vector2(82, 150), "weapon": Vector2(144, 150), "head": Vector2(120, 110)}
const ORDER := ["cape", "left_leg", "right_leg", "body", "left_arm", "right_arm", "left_weapon", "weapon", "head"]

static func pose(owner: String, motion: Dictionary) -> Dictionary:
	var time := float(motion.get("time", 0.0))
	var walking := clampf(float(motion.get("moving", 0.0)), 0.0, 1.0)
	var facing: Vector2 = motion.get("facing", Vector2.RIGHT)
	var stride := sin(time * 11.5) * walking
	var progress := clampf(float(motion.get("attack_progress", 1.0)), 0.0, 1.0)
	var attacking := bool(motion.get("attacking", false))
	var strike := sin(progress * PI) if attacking else 0.0
	var swing := (-0.65 + progress * 2.0) * strike
	var result := {"cape": sin(time * 3.0) * 0.025 + stride * 0.045, "left_leg": stride * 0.26, "right_leg": -stride * 0.26, "body": 0.0, "left_arm": -stride * 0.10, "right_arm": stride * 0.10, "left_weapon": -stride * 0.10, "weapon": stride * 0.10, "head": sin(time * 2.0) * 0.012 + facing.y * 0.025, "lean": -facing.x * walking * 0.04, "bounce": -absf(stride) * 7.5 + sin(time * 2.2) * 2.0, "side": -1.0 if facing.x < -0.15 else 1.0}
	match owner:
		"warrior", "paladin":
			result.weapon += swing * (1.0 if owner == "warrior" else 0.8)
			result.right_arm = result.weapon
			result.left_arm -= strike * 0.25
			result.lean += strike * 0.08
		"ranger":
			result.right_arm -= strike * 0.30
			result.left_arm += strike * 0.16
			result.weapon -= strike * 0.12
			result.lean -= strike * 0.05
		"assassin":
			var alternating := -1.0 if int(motion.get("attack_serial", 0)) % 2 == 0 else 1.0
			result.left_arm += swing * 0.95 * alternating
			result.right_arm -= swing * 0.95 * alternating
			result.left_weapon = result.left_arm
			result.weapon = result.right_arm
			result.lean += strike * 0.10
		_:
			result.left_arm += strike * 0.40
			result.weapon -= strike * 0.38
			result.right_arm = result.weapon
			result.head -= strike * 0.06
			result.bounce -= strike * 3.0
	return result

static func draw_character(canvas: CanvasItem, owner: String, motion: Dictionary, tint: Color, extent := Vector2(36, 45), origin := Vector2(-18, -33)) -> void:
	if SHEET.has_class(owner):
		var frame := SHEET.sample(owner, motion)
		var texture: Texture2D = frame.texture
		var factor := minf(extent.y * 0.90 / float(SHEET.HEIGHTS[owner]), extent.x / maxf(1, texture.get_width()))
		var pivot: Vector2 = frame.pivot
		var direction: Vector2 = motion.get("facing", Vector2.RIGHT)
		var flip := direction.x < -0.05
		var position := origin + extent * Vector2(0.5, 0.95) - Vector2(texture.get_width() - pivot.x if flip else pivot.x, pivot.y) * factor
		var rect := Rect2(position, texture.get_size() * factor)
		if flip: rect.size.x = -rect.size.x
		canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		canvas.draw_texture_rect(texture, rect, false, tint)
		var ground := origin + extent * Vector2(0.5, 0.95)
		for model in SHEET.equipment_pose(owner, motion):
			var side := -1.0 if flip else 1.0
			canvas.draw_set_transform(ground + Vector2(model.hand) * factor * Vector2(side, 1), float(model.angle) * side, Vector2(side, 1))
			canvas.draw_texture_rect(model.texture, Rect2(-Vector2(model.grip) * float(model.length) / 32.0 * factor, Vector2.ONE * float(model.length) * factor), false, tint)
		canvas.draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
		return
	var catalog: Node = (Engine.get_main_loop() as SceneTree).root.get_node("ContentCatalog")
	var requested := str(motion.get("weapon_id", ""))
	if requested.is_empty():
		var save: Node = (Engine.get_main_loop() as SceneTree).root.get_node("SaveManager")
		requested = str(save.loadout_for(owner).get("weapon", ""))
	var equipped: EquipmentData = catalog.equipment.get(requested)
	if equipped != null and (equipped.slot != &"weapon" or equipped.class_id not in [&"", StringName(owner)]): equipped = null
	canvas.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var transforms := pose(owner, motion)
	var textures: Dictionary = LAYERS.get(owner, LAYERS.warrior)
	var factor := extent / Vector2(240, 300)
	var side := float(transforms.side)
	var root := Transform2D(float(transforms.lean), origin + extent * Vector2(0.5, 0.70) + Vector2(0, float(transforms.bounce) * factor.y))
	for part in ORDER:
		var pivot: Vector2 = PIVOTS[part]
		var texture: Texture2D = textures[part]
		var center := (pivot - Vector2(120, 210)) * factor * Vector2(side, 1)
		var angle := float(transforms.lean) + float(transforms[part]) * side
		canvas.draw_set_transform(root * center, angle, Vector2(side, 1))
		if part == "weapon" or (part == "left_weapon" and owner == "assassin") or (part == "left_arm" and owner == "warrior"):
			var shield: bool = part == "left_arm"
			var model: Texture2D = MODELS.shield_for(equipped) if shield else MODELS.texture_for(equipped, owner)
			var hand := Vector2(-8, 34) if shield else (Vector2(-20, 45) if part == "left_weapon" else Vector2(36, 42))
			if owner == "ranger": hand = Vector2(30, 35)
			var grip := Vector2(16, 16) if shield or owner == "ranger" else Vector2(7, 25)
			var length := 78.0 if shield else (90.0 if owner == "assassin" else 128.0)
			if owner == "ranger": length = 104.0
			var tilt := 0.0 if shield else (-PI / 4 if owner == "ranger" else (-PI / 5 if owner in ["mage", "druid"] else -PI / 8))
			if part == "left_weapon": tilt += PI
			var parent_transform := Transform2D(angle, root * center) * Transform2D(Vector2(side, 0), Vector2(0, 1), Vector2.ZERO)
			canvas.draw_set_transform_matrix(parent_transform * Transform2D(tilt, hand * factor))
			canvas.draw_texture_rect(model, Rect2(-grip / 32 * length * factor, Vector2.ONE * length * factor), false, tint)
			continue
		var rect := Rect2(-pivot * factor, extent)
		if extent.x <= 100.0:
			for outline_offset in [Vector2(-0.8, 0), Vector2(0.8, 0)]:
				canvas.draw_texture_rect(texture, Rect2(rect.position + outline_offset, rect.size), false, Color("#061116", tint.a))
		canvas.draw_texture_rect(texture, rect, false, tint)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
