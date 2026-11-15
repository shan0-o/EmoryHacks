
extends Control

var score = 0
var time_left = 25
var current_email = 0

var emails = [
	{
		"sender": "teacher@example.org",
		"subject": "Homework Reminder",
		"message": "Remember to submit your assignment on Friday.",
		"is_phishing": false,
		"explanation": "This is an ordinary reminder."
	},
	{
		"sender": "prize@winner.example",
		"subject": "YOU WON A PRIZE!",
		"message": "Send us your password to claim your reward!",
		"is_phishing": true,
		"explanation": "Never share your password to claim a prize."
	},
	{
		"sender": "security@account-alert.example",
		"subject": "URGENT: Account Locked",
		"message": "Reply with your login details immediately!",
		"is_phishing": true,
		"explanation": "Unexpected requests for login details are suspicious."
	}
]

@onready var score_label = $ScoreLabel
@onready var timer_label = $TimerLabel
@onready var sender_label = $EmailPanel/SenderLabel
@onready var subject_label = $EmailPanel/SubjectLabel
@onready var message_label = $EmailPanel/MessageLabel
@onready var feedback_label = $FeedbackLabel
@onready var keep_button = $KeepButton
@onready var delete_button = $DeleteButton
@onready var game_timer = $GameTimer


func _ready():
	score_label.text = "SCORE: 0"
	timer_label.text = "TIME: 25"
	feedback_label.text = "Is this email safe?"

	show_email()
	game_timer.start()


func show_email():
	if current_email >= emails.size():
		end_game()
		return

	var email = emails[current_email]

	sender_label.text = "From: " + email["sender"]
	subject_label.text = email["subject"]
	message_label.text = email["message"]


func _on_keep_button_pressed():
	check_answer(false)


func _on_delete_button_pressed():
	check_answer(true)


func check_answer(player_says_phishing):
	if game_timer.is_stopped():
		return

	var email = emails[current_email]

	if player_says_phishing == email["is_phishing"]:
		score += 100
		feedback_label.text = "Correct! " + email["explanation"]
	else:
		feedback_label.text = "Wrong! " + email["explanation"]

	score_label.text = "SCORE: " + str(score)

	current_email += 1
	show_email()


func _on_game_timer_timeout():
	time_left -= 1
	timer_label.text = "TIME: " + str(time_left)

	if time_left <= 0:
		end_game()


func end_game():
	game_timer.stop()

	keep_button.disabled = true
	delete_button.disabled = true

	sender_label.text = "ROUND COMPLETE!"
	subject_label.text = ""
	message_label.text = ""

	feedback_label.text = "Final Score: " + str(score)
