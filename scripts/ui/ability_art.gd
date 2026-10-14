extends RefCounted

static func draw_icon(canvas: CanvasItem, id: String, center: Vector2, accent: Color, hovered: bool = false) -> void:
	var glow := accent.lightened(0.18)
	var small := 3.0 if hovered else 2.0
	match id:
		"shadow_step", "razor_dance", "shadow_burst":
			for side in [-1.0, 1.0]:
				var origin := center + Vector2(side * 13, 0)
				canvas.draw_colored_polygon(PackedVector2Array([origin + Vector2(side * 5, -31), origin + Vector2(side * 7, 9), origin + Vector2(0, 17), origin + Vector2(-side * 6, 8)]), accent)
				canvas.draw_line(origin + Vector2(-10, 10), origin + Vector2(10, 10), glow, 2, true)
				canvas.draw_line(origin + Vector2(0, 15), origin + Vector2(0, 29), accent.darkened(0.15), 4, true)
		"wild_growth", "living_bark", "roots_snare", "ancient_guardian":
			canvas.draw_arc(center, 28, 0.1, TAU - 0.5, 30, Color(accent, 0.45), 2, true)
			canvas.draw_line(center + Vector2(0, 28), center + Vector2(0, -24), glow, 2, true)
			for side in [-1.0, 1.0]:
				for tier in 2:
					var p := center + Vector2(0, 12 - tier * 19)
					canvas.draw_colored_polygon(PackedVector2Array([p, p + Vector2(side * 24, -17), p + Vector2(side * 22, -2), p + Vector2(side * 10, 4)]), accent)
		"holy_oath", "sunfire":
			canvas.draw_circle(center, 16, accent)
			canvas.draw_arc(center, 22, 0, TAU, 36, glow, 1.5, true)
			for ray in 8:
				var axis := Vector2.RIGHT.rotated(ray * TAU / 8.0)
				canvas.draw_line(center + axis * 27, center + axis * 35, glow, 2, true)
		"vital_bloom", "second_wind", "bulwark", "field_medicine", "restoring_light":
			var heart := PackedVector2Array([
				center + Vector2(0, 28), center + Vector2(-27, 6), center + Vector2(-30, -9),
				center + Vector2(-23, -22), center + Vector2(-11, -23), center + Vector2(0, -12),
				center + Vector2(11, -23), center + Vector2(23, -22), center + Vector2(30, -9), center + Vector2(27, 6)
			])
			canvas.draw_colored_polygon(heart, Color("#bc443b"))
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -12), center + Vector2(-23, -22), center + Vector2(-27, 6), center + Vector2(0, 8)]), Color("#e47768"))
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -12), center + Vector2(11, -23), center + Vector2(23, -22), center + Vector2(27, 6), center + Vector2(0, 8)]), Color("#d45b48"))
			canvas.draw_line(center + Vector2(0, -12), center + Vector2(0, 28), Color("#ffc2a0", 0.6), 1, true)
			canvas.draw_polyline(PackedVector2Array([heart[0], heart[1], heart[2], heart[3], heart[4]]), Color("#f28b65"), 2.0, true)
			canvas.draw_line(center + Vector2(-36, -29), center + Vector2(-27, -22), glow, 3.0, true)
			canvas.draw_line(center + Vector2(36, -29), center + Vector2(27, -22), glow, 3.0, true)
			canvas.draw_circle(center + Vector2(-34, 30), small, glow)
			canvas.draw_circle(center + Vector2(34, 30), small, glow)
		"swift_feet", "hunters_pace", "wind_string", "wide_harvest":
			canvas.draw_colored_polygon(PackedVector2Array([
				center + Vector2(-10, -30), center + Vector2(9, -28), center + Vector2(8, -7),
				center + Vector2(20, 7), center + Vector2(29, 15), center + Vector2(27, 24),
				center + Vector2(-20, 24), center + Vector2(-28, 17), center + Vector2(-15, 5)
			]), Color("#27384a"))
			canvas.draw_polyline(PackedVector2Array([center + Vector2(-8, -25), center + Vector2(5, -21), center + Vector2(4, -7), center + Vector2(18, 11), center + Vector2(25, 16)]), Color("#46c9f1"), 3.0, true)
			for index in 3:
				var y := float(index * 11 - 10)
				canvas.draw_line(center + Vector2(-34, y), center + Vector2(-20, y - 3), Color("#54bce2", 0.78), 2.0, true)
		"thorn_aura":
			for index in 4:
				var radius := 11.0 + float(index) * 5.0
				canvas.draw_arc(center, radius, 0.6 + index * 0.55, 4.7 + index * 0.55, 34, Color(accent, 0.78 - index * 0.1), 3.0, true)
			for index in 7:
				var angle := float(index) * TAU / 7.0
				var start := center + Vector2.RIGHT.rotated(angle) * 27.0
				var tip := center + Vector2.RIGHT.rotated(angle + 0.18) * 37.0
				canvas.draw_line(start, tip, glow, 2.4, true)
		"ember_orb", "berserker", "phoenix_flame":
			canvas.draw_colored_polygon(PackedVector2Array([
				center + Vector2(0, -34), center + Vector2(8, -17), center + Vector2(21, -10),
				center + Vector2(18, 8), center + Vector2(9, 27), center + Vector2(-12, 27),
				center + Vector2(-23, 12), center + Vector2(-18, -7), center + Vector2(-7, -16)
			]), Color("#ec702d"))
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(1, 19), center + Vector2(-8, 6), center + Vector2(1, -10), center + Vector2(9, 4), center + Vector2(7, 18)]), Color("#ffcf67"))
		"storm_arc", "echo_strike":
			canvas.draw_colored_polygon(PackedVector2Array([
				center + Vector2(7, -34), center + Vector2(-19, 4), center + Vector2(-3, 4),
				center + Vector2(-12, 33), center + Vector2(20, -9), center + Vector2(4, -9)
			]), Color("#8fe6ff"))
			canvas.draw_polyline(PackedVector2Array([center + Vector2(7, -34), center + Vector2(-19, 4), center + Vector2(-3, 4), center + Vector2(-12, 33)]), Color.WHITE, 1.5, true)
		"starfall":
			canvas.draw_colored_polygon(PackedVector2Array([
				center + Vector2(0, -32), center + Vector2(7, -8), center + Vector2(31, 0),
				center + Vector2(7, 7), center + Vector2(0, 31), center + Vector2(-7, 7),
				center + Vector2(-31, 0), center + Vector2(-7, -8)
			]), Color("#e5b9ff"))
			canvas.draw_line(center + Vector2(-28, 28), center + Vector2(-8, 8), Color(accent, 0.8), 3.0, true)
		"keen_edge", "blade_storm", "oath_edge", "fletching":
			canvas.draw_colored_polygon(PackedVector2Array([
				center + Vector2(0, -34), center + Vector2(8, 11), center + Vector2(0, 23), center + Vector2(-8, 11)
			]), Color("#f5d58b"))
			canvas.draw_line(center + Vector2(-17, 8), center + Vector2(17, 8), glow, 4.0, true)
			canvas.draw_line(center + Vector2(0, 19), center + Vector2(0, 34), Color("#a67a43"), 5.0, true)
		"rapid_hands", "deadly_rhythm", "arcane_haste":
			for index in 3:
				var x := float(index - 1) * 15.0
				canvas.draw_line(center + Vector2(x - 8, 23), center + Vector2(x + 8, -23), glow, 4.0, true)
				canvas.draw_circle(center + Vector2(x + 8, -23), 3.0, Color.WHITE)
		"lucky_find":
			canvas.draw_circle(center, 27, Color("#b78a39"))
			canvas.draw_circle(center, 21, Color("#e9c568"))
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -15), center + Vector2(5, -4), center + Vector2(16, 0), center + Vector2(5, 5), center + Vector2(0, 16), center + Vector2(-5, 5), center + Vector2(-16, 0), center + Vector2(-5, -4)]), Color("#fff0aa"))
		"iron_skin", "iron_will", "hold_the_line", "solar_armor", "retribution":
			var shield := PackedVector2Array([center + Vector2(-24, -27), center + Vector2(24, -27), center + Vector2(22, 8), center + Vector2(0, 31), center + Vector2(-22, 8)])
			canvas.draw_colored_polygon(shield, Color("#668374"))
			canvas.draw_colored_polygon(PackedVector2Array([shield[0], center + Vector2(0, -27), shield[3], shield[4]]), Color("#90b5a0"))
			canvas.draw_polyline(PackedVector2Array([shield[0], shield[1], shield[2], shield[3], shield[4], shield[0]]), glow, 2, true)
			canvas.draw_line(center + Vector2(0, -18), center + Vector2(0, 19), glow, 3, true)
		"lifesteal", "night_hunger":
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -32), center + Vector2(22, 6), center + Vector2(17, 23), center + Vector2(0, 30), center + Vector2(-17, 23), center + Vector2(-22, 6)]), Color("#b66f60"))
			canvas.draw_line(center + Vector2(-11, 9), center + Vector2(-8, 18), Color("#dfb09a"), 3, true)
		"frost_nova", "glacial_ring":
			for ray in 6:
				var axis := Vector2.RIGHT.rotated(ray * TAU / 6)
				var tangent := axis.orthogonal()
				canvas.draw_line(center, center + axis * 31, Color("#abc5c0"), 2, true)
				canvas.draw_line(center + axis * 20, center + axis * 14 + tangent * 7, Color("#abc5c0"), 2, true)
				canvas.draw_line(center + axis * 20, center + axis * 14 - tangent * 7, Color("#abc5c0"), 2, true)
		"time_warp":
			canvas.draw_line(center + Vector2(-23, -29), center + Vector2(23, -29), glow, 3, true)
			canvas.draw_line(center + Vector2(-23, 29), center + Vector2(23, 29), glow, 3, true)
			canvas.draw_polyline(PackedVector2Array([center + Vector2(-19, -26), center + Vector2(-19, -13), center + Vector2(13, 16), center + Vector2(19, 26)]), glow, 2, true)
			canvas.draw_polyline(PackedVector2Array([center + Vector2(19, -26), center + Vector2(19, -13), center + Vector2(-13, 16), center + Vector2(-19, 26)]), glow, 2, true)
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(-13, 25), center + Vector2(13, 25), center + Vector2(0, 11)]), Color("#c6aa72"))
		"void_rift", "arcane_focus", "arcane_expansion", "distant_star":
			for layer in 3:
				var r := 30.0 - layer * 8
				canvas.draw_polyline(PackedVector2Array([center + Vector2(-r, 0), center + Vector2(0, -r), center + Vector2(r, 0), center + Vector2(0, r), center + Vector2(-r, 0)]), Color("#b1a0bd", 1.0 - layer * 0.2), 2, true)
		"wolf_pack":
			canvas.draw_circle(center + Vector2(0, 8), 16, accent)
			for point in [Vector2(-23, -8), Vector2(-9, -23), Vector2(10, -23), Vector2(24, -7)]:
				canvas.draw_circle(center + point, 7, glow)
		"challenge_shout":
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(-25, -8), center + Vector2(10, -20), center + Vector2(10, 20), center + Vector2(-25, 8)]), accent)
			for radius in [20.0, 29.0, 38.0]:
				canvas.draw_arc(center + Vector2(2, 0), radius, -0.7, 0.7, 16, glow, 2.2, true)
		"volley", "steady_aim", "far_sight", "critical_eye":
			canvas.draw_arc(center, 26, 0, TAU, 36, accent, 2, true)
			canvas.draw_arc(center, 12, 0, TAU, 24, glow, 2, true)
			for index in 4:
				var axis := Vector2.from_angle(index * TAU / 4.0)
				canvas.draw_line(center + axis * 19, center + axis * 35, glow, 2.0, true)
		_:
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -31), center + Vector2(8, -8), center + Vector2(31, 0), center + Vector2(8, 8), center + Vector2(0, 31), center + Vector2(-8, 8), center + Vector2(-31, 0), center + Vector2(-8, -8)]), glow)

static func color_for(id: String) -> Color:
	return {
		"vital_bloom":Color("#78cb60"), "second_wind":Color("#e76d77"), "swift_feet":Color("#45bce8"),
		"thorn_aura":Color("#ad55e2"), "ember_orb":Color("#f08a42"), "storm_arc":Color("#79d9f2"),
		"starfall":Color("#c779ed"), "keen_edge":Color("#e8c06b"), "rapid_hands":Color("#efa45a"),
		"lucky_find":Color("#69c59d"), "wolf_pack":Color("#9aefbb"), "living_bark":Color("#9aefbb"),
		"ancient_guardian":Color("#9aefbb"), "roots_snare":Color("#9aefbb"), "challenge_shout":Color("#e9be79"),
		"glacial_ring":Color("#a0eaff"), "arcane_haste":Color("#a0eaff"), "volley":Color("#d2ed9b"),
		"shadow_burst":Color("#d7a8f1"), "deadly_rhythm":Color("#d7a8f1"), "sunfire":Color("#ffe19b")
	}.get(id, Color("#d9b36a"))

