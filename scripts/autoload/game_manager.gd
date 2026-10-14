extends Node

var active_class := "warrior"
var active_map := "verdant_reach"
var run_active := false

func begin_run(class_id: String, map_id: String) -> void:
	active_class = class_id
	active_map = map_id
	run_active = true

func finish_run() -> void:
	run_active = false
