extends RefCounted
## Removes neutral checkerboard connected to a crop border; preserves enclosed whites.
static func remove_white_fringe(pixels: PackedByteArray, original: PackedByteArray, width: int, pose: Array) -> void:
	var left := int(pose[0])
	var top := int(pose[1])
	var right := left + int(pose[2])
	var bottom := top + int(pose[3])
	for y in range(top + 1, bottom - 1):
		for x in range(left + 1, right - 1):
			var offset := (y * width + x) * 4
			if original[offset + 3] == 0: continue
			var low := mini(original[offset], mini(original[offset + 1], original[offset + 2]))
			var high := maxi(original[offset], maxi(original[offset + 1], original[offset + 2]))
			if low < 130 or high - low > 60 or not _touches_clear(original, width, x, y): continue
			# Infer the edge's foreground from the closest solid interior pixels.
			# A pale beard references its own pale interior, so it is preserved.
			var reference := Vector3.ZERO
			var count := 0
			var closest := 100
			for dy in range(-3, 4):
				for dx in range(-3, 4):
					var distance := dx * dx + dy * dy
					var px := x + dx
					var py := y + dy
					if distance < 4 or distance > closest or px <= left or px >= right - 1 or py <= top or py >= bottom - 1: continue
					var sample := (py * width + px) * 4
					if original[sample + 3] == 0 or _touches_clear(original, width, px, py): continue
					if distance < closest:
						closest = distance
						reference = Vector3.ZERO
						count = 0
					reference += Vector3(original[sample], original[sample + 1], original[sample + 2])
					count += 1
			if count == 0: continue
			reference /= float(count)
			var matte := Vector3.ONE * 255.0
			var observed := Vector3(original[offset], original[offset + 1], original[offset + 2])
			var axis := reference - matte
			if axis.length_squared() < 100: continue
			var alpha := clampf((observed - matte).dot(axis) / axis.length_squared(), 0, 1)
			if alpha >= 0.98: continue
			if alpha < 0.12:
				pixels[offset + 3] = 0
				continue
			var foreground := (observed - matte * (1.0 - alpha)) / alpha
			pixels[offset] = clampi(roundi(foreground.x), 0, 255)
			pixels[offset + 1] = clampi(roundi(foreground.y), 0, 255)
			pixels[offset + 2] = clampi(roundi(foreground.z), 0, 255)
			pixels[offset + 3] = roundi(alpha * original[offset + 3])

static func _touches_clear(pixels: PackedByteArray, width: int, x: int, y: int) -> bool:
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if pixels[((y + dy) * width + x + dx) * 4 + 3] == 0: return true
	return false

static func clear_pale_checker(pixels: PackedByteArray, width: int, pose: Array) -> void:
	# The green/purple character charts have warm-colored beard/skin and a very
	# pale neutral checker. Clear enclosed background holes inside bows and limbs.
	# Do not apply this to white armor or white fur in the boss sheets.
	for y in range(int(pose[1]), int(pose[1]) + int(pose[3])):
		for x in range(int(pose[0]), int(pose[0]) + int(pose[2])):
			var offset := (y * width + x) * 4
			if pixels[offset + 3] == 0: continue
			var low := mini(pixels[offset], mini(pixels[offset + 1], pixels[offset + 2]))
			var high := maxi(pixels[offset], maxi(pixels[offset + 1], pixels[offset + 2]))
			if low >= 210 and high - low <= 18: pixels[offset + 3] = 0

static func clear_connected(pixels: PackedByteArray, width: int, pose: Array) -> void:
	var w := int(pose[2])
	var h := int(pose[3])
	var visited := PackedByteArray()
	visited.resize(w * h)
	var queue := PackedInt32Array()
	for x in w:
		queue.append(x)
		queue.append((h - 1) * w + x)
	for y in range(1, h - 1):
		queue.append(y * w)
		queue.append(y * w + w - 1)
	var cursor := 0
	while cursor < queue.size():
		var index := queue[cursor]
		cursor += 1
		if visited[index] != 0: continue
		visited[index] = 1
		var x := index % w
		var y := index / w
		var offset := ((int(pose[1]) + y) * width + int(pose[0]) + x) * 4
		var low := mini(pixels[offset], mini(pixels[offset + 1], pixels[offset + 2]))
		var high := maxi(pixels[offset], maxi(pixels[offset + 1], pixels[offset + 2]))
		if low < 155 or high - low > 26: continue
		pixels[offset + 3] = 0
		if x > 0: queue.append(index - 1)
		if x + 1 < w: queue.append(index + 1)
		if y > 0: queue.append(index - w)
		if y + 1 < h: queue.append(index + w)

