extends Control

var action: Callable
var allowed: Callable

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	mouse_filter = MOUSE_FILTER_IGNORE

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_echo() and event.is_action_pressed("pause") and allowed.call():
		action.call()
		get_viewport().set_input_as_handled()
