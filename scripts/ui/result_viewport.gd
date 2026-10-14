extends Control
## Center and fit a victory/defeat panel inside the window without scrolling.
var content: Control
var preferred_width := 720.0
var fitting := false

func _ready() -> void:
	add_child(content)
	resized.connect(_queue_fit)
	content.minimum_size_changed.connect(_queue_fit)
	_queue_fit()

func _queue_fit() -> void:
	if fitting:
		return
	fitting = true
	call_deferred("_fit")

func _fit() -> void:
	fitting = false
	if size.x <= 0.0 or size.y <= 0.0:
		return
	content.size = Vector2(minf(preferred_width, maxf(180.0, size.x - 24.0)), 0)
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var available := (size - Vector2(24, 24)).max(Vector2.ONE)
	var factor := minf(1.0, minf(available.x / maxf(1.0, content.size.x), available.y / maxf(1.0, content.size.y)))
	content.scale = Vector2.ONE * factor
	content.position = (size - content.size * factor) * 0.5
