extends Control

var value := Vector2.ZERO
var finger_id := -1
var active_mouse := false
var base_radius := 64.0
var knob_radius := 27.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(170, 170)
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and finger_id == -1:
			finger_id = event.index
			_update_from_position(event.position)
		elif not event.pressed and event.index == finger_id:
			finger_id = -1
			value = Vector2.ZERO
			queue_redraw()
	elif event is InputEventScreenDrag and event.index == finger_id:
		_update_from_position(event.position)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		active_mouse = event.pressed
		if active_mouse:
			_update_from_position(event.position)
		else:
			value = Vector2.ZERO
			queue_redraw()
	elif event is InputEventMouseMotion and active_mouse:
		_update_from_position(event.position)

func _update_from_position(position: Vector2) -> void:
	var center := size * 0.5
	var offset := position - center
	value = (offset / base_radius).limit_length(1.0)
	queue_redraw()

func _draw() -> void:
	var center := size * 0.5
	draw_circle(center, base_radius, Color(0.025, 0.045, 0.06, 0.45))
	draw_arc(center, base_radius, 0.0, TAU, 44, Color(0.75, 0.83, 0.78, 0.37), 2.0, true)
	draw_circle(center + value * base_radius * 0.65, knob_radius, Color(0.86, 0.9, 0.83, 0.37))
	draw_arc(center + value * base_radius * 0.65, knob_radius, 0.0, TAU, 28, Color(0.9, 0.86, 0.68, 0.8), 2.0, true)
