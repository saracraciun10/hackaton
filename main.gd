extends Node2D
# NEON SHIELD - "Bounce Back" theme
# Controls: Mouse (or Left/Right arrows) = rotate shield, R = restart

const PLAYER_R := 18.0
const SHIELD_R := 60.0
const ENEMY_RING := 300.0
const MAX_ARC := 100.0
const MIN_ARC := 30.0
const SAVE_PATH := "user://highscore.save"

const COL_PLAYER := Color(1.0, 0.85, 0.5)
const COL_PLAYER_GLOW := Color(1.0, 0.6, 0.2, 0.18)
const COL_SHIELD := Color(1.0, 0.82, 0.45)
const COL_SHIELD_GLOW := Color(1.0, 0.55, 0.15, 0.25)
const COL_BULLET := Color(0.3, 0.75, 1.0)
const COL_BULLET_OUTLINE := Color(0.02, 0.05, 0.2)
const COL_LASER := Color(1.0, 0.96, 0.75)
const COL_LASER_GLOW := Color(1.0, 0.6, 0.2, 0.4)
const COL_SHOCK := Color(1.0, 0.6, 0.25, 0.7)
const COL_UI := Color(1.0, 0.92, 0.75)
const COL_GAMEOVER := Color(1.0, 0.85, 0.3)

var center := Vector2(640, 360)
var shield_angle := 0.0
var shield_arc := deg_to_rad(MAX_ARC)

var enemies: Array = []
var bullets: Array = []
var score := 0
var high_score := 0
var game_started := false
var game_over := false
var spawn_t := 1.0
var time_alive := 0.0

var shock_active := false
var shock_r := 0.0
var flash := 0.0

var bounce_back_banner_t := 0.0
var invincible_t := 0.0
var start_layer: CanvasLayer

var player_tex: Texture2D = preload("res://assets/player.png")
var bg: Texture2D = preload("res://assets/background.png")
var enemy_tex: Texture2D = preload("res://assets/enemy.png")


func _ready() -> void:
	randomize()
	center = get_viewport_rect().size / 2.0
	load_high_score()
	creeaza_meniu_start()
	
	$QuizManager.jucator_reinviat.connect(_on_jucator_reinviat)
	$QuizManager.joc_terminat_definitiv.connect(_on_game_over_final)


func creeaza_meniu_start() -> void:
	var bold_font := FontVariation.new()
	bold_font.base_font = ThemeDB.fallback_font
	bold_font.variation_embolden = 0.8

	start_layer = CanvasLayer.new()
	start_layer.layer = 5
	add_child(start_layer)

	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.02, 0.08, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	start_layer.add_child(dim)

	var center_box := CenterContainer.new()
	center_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	start_layer.add_child(center_box)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 26)
	center_box.add_child(vbox)

	var title := Label.new()
	title.text = "NEON SHIELD"
	title.add_theme_font_override("font", bold_font)
	title.add_theme_font_size_override("font_size", 76)
	title.add_theme_color_override("font_color", COL_GAMEOVER)
	title.add_theme_color_override("font_outline_color", Color(0.05, 0.02, 0.1))
	title.add_theme_constant_override("outline_size", 10)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Move Mouse or Left/Right Arrows to rotate shield\nBounce back enemy lasers to survive!"
	subtitle.add_theme_font_override("font", bold_font)
	subtitle.add_theme_font_size_override("font_size", 26)
	subtitle.add_theme_color_override("font_color", COL_UI)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	var start_btn := Button.new()
	start_btn.text = "START GAME"
	start_btn.custom_minimum_size = Vector2(340, 85)
	start_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start_btn.add_theme_font_override("font", bold_font)
	start_btn.add_theme_font_size_override("font_size", 34)
	start_btn.pressed.connect(_on_start_pressed)
	vbox.add_child(start_btn)


func _on_start_pressed() -> void:
	start_layer.hide()
	game_started = true
	$MusicPlayer.play()  
	restart()


func restart() -> void:
	enemies.clear()
	bullets.clear()
	score = 0
	game_over = false
	spawn_t = 1.0
	time_alive = 0.0
	shield_arc = deg_to_rad(MAX_ARC)
	shock_active = false
	flash = 0.0
	bounce_back_banner_t = 0.0
	invincible_t = 0.0


func _process(delta: float) -> void:
	if not game_started:
		queue_redraw()
		return
		
	if Input.is_key_pressed(KEY_R) and game_over:
		restart()
	if not game_over:
		update_game(delta)
	queue_redraw()


func update_game(delta: float) -> void:
	time_alive += delta
	if bounce_back_banner_t > 0.0:
		bounce_back_banner_t -= delta
	if invincible_t > 0.0:
		invincible_t -= delta
		
	var difficulty: float = 1.0 + time_alive / 40.0

	var target: float = (get_global_mouse_position() - center).angle()
	shield_angle = lerp_angle(shield_angle, target, 1.0 - exp(-18.0 * delta))
	if Input.is_key_pressed(KEY_LEFT):
		shield_angle -= 5.0 * delta
	if Input.is_key_pressed(KEY_RIGHT):
		shield_angle += 5.0 * delta

	spawn_t -= delta
	var max_enemies: int = mini(3 + int(time_alive / 20.0), 8)
	if spawn_t <= 0.0 and enemies.size() < max_enemies:
		spawn_t = 2.0
		enemies.append({
			"angle": randf() * TAU,
			"dist": ENEMY_RING + 100.0,
			"base_dist": ENEMY_RING,
			"shoot_t": randf_range(0.5, 2.0),
			"stun": 0.0
		})

	for e in enemies:
		e["angle"] += 0.15 * delta
		e["dist"] = move_toward(e["dist"], e["base_dist"], 60.0 * delta)
		if e["stun"] > 0.0:
			e["stun"] -= delta
			continue
		e["shoot_t"] -= delta
		if e["shoot_t"] <= 0.0:
			e["shoot_t"] = randf_range(1.2, 2.5) / difficulty
			var pos: Vector2 = center + Vector2.from_angle(e["angle"]) * e["dist"]
			var dir: Vector2 = (center - pos).normalized()
			bullets.append({"pos": pos, "vel": dir * 170.0 * difficulty, "reflected": false})

	var alive_bullets: Array = []
	for b in bullets:
		b["pos"] += b["vel"] * delta
		var keep := true
		var d: Vector2 = b["pos"] - center

		if b["reflected"]:
			for i in range(enemies.size() - 1, -1, -1):
				var epos: Vector2 = center + Vector2.from_angle(enemies[i]["angle"]) * enemies[i]["dist"]
				if b["pos"].distance_to(epos) < 27.0:
					enemies.remove_at(i)
					score += 10
			if d.length() > 800.0:
				keep = false
		else:
			var dist: float = d.length()
			var n: Vector2 = d / maxf(dist, 0.001)
			if dist <= SHIELD_R + 6.0 and dist >= SHIELD_R - 14.0 and b["vel"].dot(n) < 0.0:
				var diff: float = abs(angle_difference(shield_angle, n.angle()))
				if diff <= shield_arc / 2.0:
					b["reflected"] = true
					b["vel"] = b["vel"].bounce(n) * 2.0
					b["pos"] = center + n * (SHIELD_R + 8.0)
					score += 1
					play_sfx("ParrySound")
			if not b["reflected"] and dist < PLAYER_R + 4.0:
				keep = false
				if invincible_t <= 0.0:
					player_hit()
			if dist > 900.0:
				keep = false
		if keep:
			alive_bullets.append(b)
	bullets = alive_bullets

	if shock_active:
		shock_r += 700.0 * delta
		bullets = bullets.filter(func(bb): return bb["reflected"] or (bb["pos"] - center).length() > shock_r)
		if shock_r > 700.0:
			shock_active = false
	flash = maxf(flash - delta * 2.0, 0.0)


func player_hit() -> void:
	play_sfx("HitSound")
	shield_arc -= deg_to_rad(18.0)
	flash = 1.0
	shock_active = true
	shock_r = PLAYER_R
	for e in enemies:
		e["dist"] += 140.0
		e["stun"] = 1.5
	if shield_arc < deg_to_rad(MIN_ARC):
		$QuizManager.arata_optiune_bounce_back()


func _draw() -> void:
	if game_over:
		draw_texture_rect(bg, Rect2(Vector2.ZERO, get_viewport_rect().size), false, Color(0.15, 0.15, 0.22, 0.45))
	else:
		draw_texture_rect(bg, Rect2(Vector2.ZERO, get_viewport_rect().size), false, Color(1, 1, 1, 0.5))
		
	if not game_started:
		return
		
	if flash > 0.0:
		draw_rect(get_viewport_rect(), Color(1.0, 0.8, 0.3, flash * 0.25))

	if shock_active and not game_over:
		draw_arc(center, shock_r, 0, TAU, 96, COL_SHOCK, 4.0)

	if not game_over:
		var glow_col := COL_PLAYER_GLOW
		var ship_tint := Color.WHITE
		if invincible_t > 0.0:
			glow_col = Color(0.2, 1.0, 0.6, 0.35)
			ship_tint = Color(0.7, 1.0, 0.8, 0.7)
		draw_circle(center, PLAYER_R + 14.0, glow_col)
		var ship_ang: float = shield_angle + PI / 2.0
		draw_set_transform(center, ship_ang, Vector2(0.6, 0.6))
		draw_texture(player_tex, -player_tex.get_size() / 2.0, ship_tint)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		var a0: float = shield_angle - shield_arc / 2.0
		var a1: float = shield_angle + shield_arc / 2.0
		draw_arc(center, SHIELD_R, a0, a1, 32, COL_SHIELD_GLOW, 16.0)
		draw_arc(center, SHIELD_R, a0, a1, 32, COL_SHIELD, 5.0)

		for e in enemies:
			var p: Vector2 = center + Vector2.from_angle(e["angle"]) * e["dist"]
			var tint := Color(1.0, 0.8, 0.6)
			if e["stun"] > 0.0:
				tint = Color(0.5, 0.5, 0.5)
			var ang: float = (center - p).angle() - PI / 2.0
			draw_set_transform(p, ang, Vector2(1.5, 1.5))
			draw_texture(enemy_tex, -enemy_tex.get_size() / 2.0, tint)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		for b in bullets:
			if b["reflected"]:
				var tail: Vector2 = b["pos"] - b["vel"].normalized() * 60.0
				draw_line(tail, b["pos"], COL_LASER_GLOW, 12.0)
				draw_line(tail, b["pos"], COL_LASER, 5.0)
			else:
				draw_circle(b["pos"], 11.0, Color(0.3, 0.75, 1.0, 0.25))
				draw_circle(b["pos"], 9.0, COL_BULLET_OUTLINE)
				draw_circle(b["pos"], 7.0, COL_BULLET)
				draw_circle(b["pos"], 3.0, Color(0.9, 1.0, 1.0))

	var font: Font = ThemeDB.fallback_font
	var sz: Vector2 = get_viewport_rect().size
	draw_string(font, Vector2(20, 36), "Score: %d" % score, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.WHITE)
	draw_string(font, Vector2(20, 68), "High Score: %d" % high_score, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, COL_GAMEOVER)
	
	if not game_over:
		var lives: int = int((rad_to_deg(shield_arc) - MIN_ARC) / 18.0) + 1
		draw_string(font, Vector2(20, 102), "Shield: " + "■ ".repeat(maxi(lives, 0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(0.5, 1, 1))

	if bounce_back_banner_t > 0.0:
		draw_string(font, Vector2(0, sz.y / 2 - 120), "BOUNCE BACK!", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 56, Color(0.2, 1.0, 0.6))

	if game_over:
		draw_string(font, Vector2(0, sz.y / 2 - 20), "GAME OVER", HORIZONTAL_ALIGNMENT_CENTER, sz.x, 64, COL_GAMEOVER)
		draw_string(font, Vector2(0, sz.y / 2 + 30), "Final score: %d (Best: %d)  -  Press R to restart" % [score, high_score], HORIZONTAL_ALIGNMENT_CENTER, sz.x, 28, Color.WHITE)


func play_sfx(node_name: String) -> void:
	var n = get_node_or_null(node_name)
	if n == null:
		print("SFX: nu gasesc nodul ", node_name)
		return
	if n.stream == null:
		print("SFX: ", node_name, " nu are Stream setat")
		return
	print("SFX: pornesc ", node_name)
	n.play()


func save_high_score() -> void:
	if score > high_score:
		high_score = score
		var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		if file:
			file.store_32(high_score)


func load_high_score() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			high_score = file.get_32()


func _on_jucator_reinviat() -> void:
	play_sfx("ReviveSound")
	shield_arc = deg_to_rad(MIN_ARC + 18.0)
	bounce_back_banner_t = 2.0
	invincible_t = 2.5
	bullets.clear()
	shock_active = true
	shock_r = PLAYER_R
	for e in enemies:
		e["dist"] = ENEMY_RING + 100.0
		e["stun"] = 2.5


func _on_game_over_final() -> void:
	save_high_score()
	enemies.clear()
	bullets.clear()
	shock_active = false
	flash = 0.0
	game_over = true
