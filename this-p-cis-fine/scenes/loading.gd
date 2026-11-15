extends Control

@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var loading_animation: AnimatedSprite2D = $CenterContainer/VBoxContainer/AnimationHolder/AnimatedSprite2D

func _ready() -> void:
	status_label.text = "LOADING..."
	loading_animation.play("default")
	
	await get_tree().create_timer(2.5).timeout
	
	status_label.text = "Everything is probably fine."
	
	await get_tree().create_timer(1.5).timeout
	
	get_tree().change_scene_to_file("res://scenes/game.tscn")
