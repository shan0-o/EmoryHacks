extends Control

@onready var title_label = $CenterContainer/VBoxContainer/TitleLabel
@onready var prompt_label = $CenterContainer/VBoxContainer/PromptLabel
@onready var entry_field = $CenterContainer/VBoxContainer/InputRow/EntryField
@onready var next_button = $CenterContainer/VBoxContainer/InputRow/NextButton

var asking_for_password = false

func _ready():
	next_button.pressed.connect(_submit)
	entry_field.text_submitted.connect(_on_enter_pressed)
	entry_field.grab_focus()

func _on_enter_pressed(_text):
	_submit()

func _submit():
	var entered_text = entry_field.text.strip_edges()
	
	if entered_text.is_empty():
		return
		
	if not asking_for_password:
		GameSession.username = entered_text
		
		asking_for_password = true
		
		title_label.text = "WELCOME, " + GameSession.username
		prompt_label.text = "Enter Password"
		
		entry_field.clear()
		entry_field.placeholder_text = "Password"
		entry_field.secret = true
		entry_field.grab_focus()
		
	else:
		entry_field.clear()
		
		get_tree().change_scene_to_file("res://scenes/game.tscn")
		
		
