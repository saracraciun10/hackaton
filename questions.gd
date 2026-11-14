extends Node

# Leagă nodurile din scenă (verifică să aibă exact aceste nume)
@onready var question_label = $Label
@onready var answer_input = $LineEdit
@onready var submit_button = $Button

var questions = [
	{"q": "What is the capital of France?", "answer": "Paris"},
	{"q": "How many continents are there?", "answer": "7"},
	{"q": "Which planet is known as the Red Planet?", "answer": "Mars"},
	{"q": "What is the largest planet in our solar system?", "answer": "Jupiter"},
	{"q": "Which planet is closest to the Sun?", "answer": "Mercury"},
	{"q": "What is the name of our galaxy?", "answer": "Milky Way"},
	{"q": "Which planet is famous for its rings?", "answer": "Saturn"},
	{"q": "What is the hottest planet in our solar system?", "answer": "Venus"},
	{"q": "Who was the first human to walk on the Moon?", "answer": "Neil Armstrong"},
	{"q": "What is the name of Earth's natural satellite?", "answer": "Moon"},
	{"q": "Which planet is known as the Ice Giant and is blue?", "answer": "Uranus"},
	{"q": "How many planets are in our solar system?", "answer": "8"}
]

var current_question = 0
var score = 0

func _ready() -> void:
	# Conectăm butonul și tasta Enter la funcția de verificare
	submit_button.pressed.connect(check_answer)
	answer_input.text_submitted.connect(_on_text_submitted)
	
	# Amestecă întrebările aleatoriu înainte să înceapă jocul
	questions.shuffle()
	
	# Afișăm prima întrebare
	show_question()

func show_question() -> void:
	if current_question < questions.size():
		question_label.text = questions[current_question]["q"]
		answer_input.text = ""
		answer_input.grab_focus() # Pune cursorul automat în căsuța de text
	else:
		# Jocul s-a terminat
		question_label.text = "Joc terminat! Scor: " + str(score) + " / " + str(questions.size())
		answer_input.hide()
		submit_button.hide()

func _on_text_submitted(new_text: String) -> void:
	check_answer()

func check_answer() -> void:
	# Ignorăm dacă jucătorul apasă butonul fără să scrie nimic
	if answer_input.text.strip_edges() == "":
		return
		
	var player_answer = answer_input.text.strip_edges().to_lower()
	var correct_answer = questions[current_question]["answer"].to_lower()
	
	if player_answer == correct_answer:
		score += 1
		print("Corect!")
	else:
		print("Greșit! Răspunsul era: " + questions[current_question]["answer"])
	
	current_question += 1
	show_question()
