extends SceneTree

func _init() -> void:
	var img := Image.load_from_file("res://assets/art/image.png")
	if img == null:
		print("Failed to load image")
		quit()
		return
		
	var w := img.get_width()
	var h := img.get_height()
	print("Loaded image: ", w, "x", h)
	
	var bg = img.get_pixel(0, 0)
	print("Top-left pixel: ", bg)
	
	# Scan for non-white, non-transparent pixels in top right to find buttons
	for y in range(0, 150):
		for x in range(600, w):
			var c = img.get_pixel(x, y)
			if c.a > 0.1 and not (c.r > 0.9 and c.g > 0.9 and c.b > 0.9) and not (c.r < 0.1 and c.g < 0.1 and c.b < 0.1): # not white, not black, not transparent
				print("Found colored pixel at: ", x, ", ", y, " Color: ", c)
				quit()
				return
	quit()
