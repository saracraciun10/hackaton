extends Node

# Semnale prin care anunțăm main.gd ce a ales sau ce a reușit jucătorul
signal jucator_reinviat
signal joc_terminat_definitiv

@onready var question_label = $Label
@onready var answer_input = $LineEdit
@onready var submit_button = $Button
@onready var revive_button = $ReviveButton
@onready var game_over_button = $GameOverButton

var questions = [
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

func _ready() -> void:
	# IMPORTANT: Permite acestui meniu să funcționeze chiar și când jocul este pus pe pauză!
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	submit_button.pressed.connect(check_answer)
	answer_input.text_submitted.connect(_on_text_submitted)
	revive_button.pressed.connect(_on_revive_pressed)
	game_over_button.pressed.connect(_on_game_over_pressed)
	
	questions.shuffle()
	ascunde_tot()

func ascunde_tot() -> void:
	question_label.hide()
	answer_input.hide()
	submit_button.hide()
	revive_button.hide()
	game_over_button.hide()

# 1. Această funcție se apelează din main.gd când moare jucătorul
func arata_optiune_bounce_back() -> void:
	get_tree().paused = true # Punem inamicii pe pauză cât timp jucătorul alege
	
	question_label.text = "Scutul a fost distrus! Ce alegi?"
	question_label.show()
	revive_button.show()
	game_over_button.show()
	
	answer_input.hide()
	submit_button.hide()

# 2. Jucătorul a ales să răspundă la o întrebare
func _on_revive_pressed() -> void:
	revive_button.hide()
	game_over_button.hide()
	
	# Afișăm o singură întrebare
	question_label.text = questions[current_question]["q"]
	answer_input.text = ""
	answer_input.show()
	submit_button.show()
	answer_input.grab_focus()

# 3. Jucătorul a renunțat
func _on_game_over_pressed() -> void:
	ascunde_tot()
	get_tree().paused = false
	joc_terminat_definitiv.emit()

func _on_text_submitted(_new_text: String) -> void:
	check_answer()

func check_answer() -> void:
	if answer_input.text.strip_edges() == "":
		return
		
	var player_answer = answer_input.text.strip_edges().to_lower()
	var correct_answer = questions[current_question]["answer"].to_lower()
	
	# Pregătim următoarea întrebare pentru data viitoare când moare
	current_question += 1
	if current_question >= questions.size():
		current_question = 0
		questions.shuffle()
	
	if player_answer == correct_answer:
		# A răspuns corect -> BOUNCE BACK!
		ascunde_tot()
		get_tree().paused = false
		jucator_reinviat.emit()
	else:
		# A greșit -> Game Over definitiv
		question_label.text = "Greșit! Răspunsul era: " + correct_answer.capitalize() + "\nGAME OVER"
		answer_input.hide()
		submit_button.hide()
		
		# Așteptăm 2 secunde să vadă răspunsul corect, apoi terminăm jocul
		await get_tree().create_timer(2.0).timeout
		ascunde_tot()
		get_tree().paused = false
		joc_terminat_definitiv.emit()
