extends "res://scripts/app/main.gd"
func _quit() -> void:
	exiting = true # Observe the real successful exit path without ending the harness.
