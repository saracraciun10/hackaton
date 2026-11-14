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
	stilizeaza_ui()  
	submit_button.pressed.connect(check_answer)
	answer_input.text_submitted.connect(_on_text_submitted)
	revive_button.pressed.connect(_on_revive_pressed)
	game_over_button.pressed.connect(_on_game_over_pressed)
	
	questions.shuffle()
	ascunde_tot()

func ascunde_tot() -> void:
	if dim:
		dim.hide()
	question_label.hide()
	answer_input.hide()
	submit_button.hide()
	revive_button.hide()
	game_over_button.hide()

# 1. Această funcție se apelează din main.gd când moare jucătorul
func arata_optiune_bounce_back() -> void:
	get_tree().paused = true # Punem inamicii pe pauză cât timp jucătorul alege
	dim.show()
	question_label.text = "The shield was destroyed. What do you choose?"
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
	var hbox := HBoxContainer.new()
var dim: ColorRect   # fundalul întunecat din spatele meniului

func stilizeaza_ui() -> void:
	var bold_font := FontVariation.new()
	bold_font.base_font = ThemeDB.fallback_font
	bold_font.variation_embolden = 0.8

	# strat separat, deasupra jocului
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)

	# fundal întunecat, ca textul să se citească bine
	dim = ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.08, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(dim)

	# containerul care centrează tot ce e în el
	var center_box := CenterContainer.new()
	center_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(center_box)

	var vbox := VBoxContainer.new()
	vbox.custom_minimum_size = Vector2(900, 0)
	vbox.add_theme_constant_override("separation", 28)
	center_box.add_child(vbox)

	# --- întrebarea ---
	question_label.reparent(vbox)
	question_label.add_theme_font_override("font", bold_font)
	question_label.add_theme_font_size_override("font_size", 44)
	question_label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.75))
	question_label.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.1))
	question_label.add_theme_constant_override("outline_size", 8)
	question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	# --- câmpul de răspuns ---
	answer_input.reparent(vbox)
	answer_input.add_theme_font_override("font", bold_font)
	answer_input.add_theme_font_size_override("font_size", 34)
	answer_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	answer_input.placeholder_text = "Type your answer..."
	answer_input.custom_minimum_size = Vector2(600, 70)
	answer_input.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	# --- butonul Send ---
	submit_button.reparent(vbox)
	submit_button.text = "Send"
	submit_button.custom_minimum_size = Vector2(300, 80)
	submit_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	# --- cele două butoane de alegere, unul lângă altul ---
	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 40)
	vbox.add_child(hbox)

	revive_button.reparent(hbox)
	revive_button.text = "Answer a question\nfor another life"
	game_over_button.reparent(hbox)
	game_over_button.text = "Give up"

	revive_button.custom_minimum_size = Vector2(380, 100)
	game_over_button.custom_minimum_size = Vector2(380, 100)

	for b in [submit_button, revive_button, game_over_button]:
		b.add_theme_font_override("font", bold_font)
		b.add_theme_font_size_override("font_size", 32)
