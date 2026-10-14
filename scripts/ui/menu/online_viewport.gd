extends Control
## Fits the online page inside the actual available area, without a scroll container.
var content: VBoxContainer
var fitting := false
func _ready() -> void:
	name = "OnlineViewport"
	size_flags_horizontal = SIZE_EXPAND_FILL
	size_flags_vertical = SIZE_EXPAND_FILL
	add_child(content)
	resized.connect(_queue_fit)
	content.minimum_size_changed.connect(_queue_fit)
	_queue_fit()
func _queue_fit() -> void:
	if fitting: return
	fitting = true
	call_deferred("_fit")
func _fit() -> void:
	fitting = false
	if size.x <= 0 or size.y <= 0: return
	content.size = Vector2(size.x, 0)
	await get_tree().process_frame
	if not is_inside_tree(): return
	var extent := content.get_combined_minimum_size()
	var factor := minf(1.0, minf(size.x / maxf(1, extent.x), size.y / maxf(1, extent.y)))
	content.scale = Vector2.ONE * factor
	content.position = Vector2((size.x - content.size.x * factor) * 0.5, 0)
