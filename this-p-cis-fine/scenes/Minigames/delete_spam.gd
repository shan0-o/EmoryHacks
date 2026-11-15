
extends Control

# ==========================================
# GAME VARIABLES
# ==========================================

var score = 0
var time_left = 25
var current_email = 0

var waiting_for_next_email = false
var round_active = false
var loading_emails = false


# ==========================================
# OFFLINE SAMPLE EMAILS
# ==========================================

var emails = [
	{
		"sender": "teacher@example.org",
		"subject": "Homework Reminder",
		"message": "Remember to submit your assignment on Friday.",
		"is_phishing": false,
		"explanation": "This is an ordinary school reminder."
	},
	{
		"sender": "prize@winner.example",
		"subject": "YOU WON A PRIZE!",
		"message": "Send your password to claim your reward!",
		"is_phishing": true,
		"explanation": "Never share passwords to claim prizes."
	},
	{
		"sender": "library@example.org",
		"subject": "Your Book Is Ready",
		"message": "The book you reserved is ready for collection.",
		"is_phishing": false,
		"explanation": "This is an expected library notification."
	},
	{
		"sender": "support@account-alert.example",
		"subject": "URGENT: Account Locked",
		"message": "Reply with your login details immediately!",
		"is_phishing": true,
		"explanation": "Unexpected requests for login details are suspicious."
	},
	{
		"sender": "club@example.org",
		"subject": "Meeting Reminder",
		"message": "Our club meeting starts at 3 PM tomorrow.",
		"is_phishing": false,
		"explanation": "This is a routine meeting reminder."
	},
	{
		"sender": "delivery@parcel-alert.example",
		"subject": "Delivery Failed!",
		"message": "Pay a surprise redelivery fee to receive a package you did not order.",
		"is_phishing": true,
		"explanation": "Unexpected payment requests are a warning sign."
	},
	{
		"sender": "friend@example.org",
		"subject": "Movie Night",
		"message": "Are you free to watch a movie this weekend?",
		"is_phishing": false,
		"explanation": "This is an ordinary personal message."
	},
	{
		"sender": "security@verify-account.example",
		"subject": "Verify Your Password NOW",
		"message": "Your account will be deleted unless you send your password immediately.",
		"is_phishing": true,
		"explanation": "Legitimate services do not ask you to email your password."
	},
	{
		"sender": "school@example.org",
		"subject": "School Event",
		"message": "The school fair will take place next Saturday.",
		"is_phishing": false,
		"explanation": "This is a routine event announcement."
	},
	{
		"sender": "winner@free-gifts.example",
		"subject": "Claim Your Free Gift!",
		"message": "Enter your credit card details to receive a prize you never entered to win.",
		"is_phishing": true,
		"explanation": "Unexpected prizes requesting payment details are suspicious."
	}
]

var fallback_emails = []


# ==========================================
# SCENE NODE REFERENCES
# ==========================================

@onready var score_label = $ScoreLabel
@onready var timer_label = $TimerLabel

@onready var sender_label = $EmailPanel/SenderLabel
@onready var subject_label = $EmailPanel/SubjectLabel
@onready var message_label = $EmailPanel/MessageLabel

@onready var feedback_label = $FeedbackLabel

@onready var keep_button = $KeepButton
@onready var delete_button = $DeleteButton
@onready var replay_button = $ReplayButton

@onready var game_timer = $GameTimer
@onready var feedback_timer = $FeedbackTimer
@onready var email_request = $EmailRequest


# ==========================================
# INITIALIZE GAME
# ==========================================

func _ready():
	fallback_emails = emails.duplicate(true)

	email_request.timeout = 15.0

	prepare_new_round()


# ==========================================
# PREPARE NEW ROUND
# ==========================================

func prepare_new_round():
	round_active = false
	loading_emails = true
	waiting_for_next_email = false

	game_timer.stop()
	feedback_timer.stop()

	keep_button.disabled = true
	delete_button.disabled = true
	replay_button.hide()

	score_label.text = "SCORE: 0"
	timer_label.text = "TIME: 25"

	sender_label.text = "LOADING EMAILS..."
	subject_label.text = ""
	message_label.text = "Contacting Gemini..."
	feedback_label.text = "Please wait..."

	request_gemini_emails()


# ==========================================
# REQUEST GEMINI EMAILS
# ==========================================

func request_gemini_emails():
	print("Requesting emails from Gemini...")

	var error = email_request.request(
        "http://127.0.0.1:5000/generate-emails"
	)

	if error != OK:
		print("Could not start email request: ", error)
		start_fallback_round()


# ==========================================
# HANDLE GEMINI RESPONSE
# ==========================================

func _on_email_request_request_completed(
	result, response_code, _headers, body
):
	if not loading_emails:
		return

	if result != HTTPRequest.RESULT_SUCCESS:
		print("Gemini request failed. Using fallback.")
		start_fallback_round()
		return

	if response_code != 200:
		print("Backend error: ", response_code)
		start_fallback_round()
		return

	var json = JSON.new()

	if json.parse(body.get_string_from_utf8()) != OK:
		print("Invalid JSON. Using fallback.")
		start_fallback_round()
		return

	var data = json.data

	if not data is Dictionary:
		print("Unexpected JSON format.")
		start_fallback_round()
		return

	if not data.has("emails"):
		print("No emails in response.")
		start_fallback_round()
		return

	var generated_emails = data["emails"]

	if not generated_emails is Array:
		print("Invalid email list.")
		start_fallback_round()
		return

	if generated_emails.size() != 10:
		print("Expected exactly 10 emails.")
		start_fallback_round()
		return

	var phishing_count = 0

	for email in generated_emails:
		if not email is Dictionary:
			print("Invalid email entry.")
			start_fallback_round()
			return

		for field in [
			"sender",
			"subject",
			"message",
            "explanation"
		]:
			if not email.has(field):
				print("Missing field: ", field)
				start_fallback_round()
				return

			if not email[field] is String:
				print("Invalid text field: ", field)
				start_fallback_round()
				return

			if email[field].strip_edges().is_empty():
				print("Empty field: ", field)
				start_fallback_round()
				return

		if not email.has("is_phishing"):
			print("Missing phishing label.")
			start_fallback_round()
			return

		if not email["is_phishing"] is bool:
			print("Invalid phishing label.")
			start_fallback_round()
			return

		if email["is_phishing"]:
			phishing_count += 1

	if phishing_count != 5:
		print("Expected 5 phishing emails.")
		start_fallback_round()
		return

	emails = generated_emails.duplicate(true)

	print("Gemini emails loaded successfully!")
	start_round()


# ==========================================
# FALLBACK TO SAMPLE EMAILS
# ==========================================

func start_fallback_round():
	if not loading_emails:
		return

	print("Using offline sample emails.")

	emails = fallback_emails.duplicate(true)

	start_round()


# ==========================================
# START ROUND
# ==========================================

func start_round():
	loading_emails = false

	score = 0
	time_left = 25
	current_email = 0

	waiting_for_next_email = false
	round_active = true

	emails.shuffle()

	score_label.text = "SCORE: 0"
	timer_label.text = "TIME: 25"
	feedback_label.text = "Is this email safe?"

	keep_button.disabled = false
	delete_button.disabled = false
	replay_button.hide()

	game_timer.stop()
	feedback_timer.stop()

	show_email()
	game_timer.start()


# ==========================================
# DISPLAY EMAIL
# ==========================================

func show_email():
	if not round_active:
		return

	if current_email >= emails.size():
		emails.shuffle()
		current_email = 0

	var email = emails[current_email]

	sender_label.text = "From: " + email["sender"]
	subject_label.text = email["subject"]
	message_label.text = email["message"]


# ==========================================
# KEEP / DELETE BUTTONS
# ==========================================

func _on_keep_button_pressed():
	check_answer(false)


func _on_delete_button_pressed():
	check_answer(true)


# ==========================================
# CHECK PLAYER ANSWER
# ==========================================

func check_answer(player_says_phishing):
	if not round_active or waiting_for_next_email:
		return

	waiting_for_next_email = true

	var email = emails[current_email]

	if player_says_phishing == email["is_phishing"]:
		score += 100
		feedback_label.text = "CORRECT! " + email["explanation"]
	else:
		feedback_label.text = "WRONG! " + email["explanation"]

	score_label.text = "SCORE: " + str(score)

	keep_button.disabled = true
	delete_button.disabled = true

	feedback_timer.start()


# ==========================================
# FEEDBACK TIMER
# ==========================================

func _on_feedback_timer_timeout():
	if not round_active:
		return

	current_email += 1
	waiting_for_next_email = false

	show_email()

	keep_button.disabled = false
	delete_button.disabled = false

	feedback_label.text = "Is this email safe?"


# ==========================================
# COUNTDOWN TIMER
# ==========================================

func _on_game_timer_timeout():
	if not round_active:
		return

	time_left -= 1
	timer_label.text = "TIME: " + str(time_left)

	if time_left <= 0:
		end_game()


# ==========================================
# END ROUND
# ==========================================

func end_game():
	if not round_active:
		return

	round_active = false

	game_timer.stop()
	feedback_timer.stop()

	waiting_for_next_email = false

	keep_button.disabled = true
	delete_button.disabled = true

	sender_label.text = "ROUND COMPLETE!"
	subject_label.text = ""
	message_label.text = ""

	feedback_label.text = "FINAL SCORE: " + str(score)

	replay_button.show()


# ==========================================
# REPLAY BUTTON
# ==========================================

func _on_replay_button_pressed():
	prepare_new_round()
