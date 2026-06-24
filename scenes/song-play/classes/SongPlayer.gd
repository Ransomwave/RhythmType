extends Node
class_name SongPlayer

var audio_player: AudioStreamPlayer
var lyric_container: HBoxContainer
var judge_line: ColorRect
var judge_label: Label
var lyric_letter: RichTextLabel

##################### Song-related data
var song_path: String
var lyrics: Dictionary

## Glyphs keeps track of character positions and key target status.
var glyphs: Array[ChartParser.Glyph] = []

## Key targets is an array with the time of the lyric and the corresponding glyph index in the final text that should be hit at that time.
var key_targets: Array[ChartParser.KeyTarget] = []

## Captures each word's first letter position after layout
# var word_offsets: Array[float] = []

## Chart entries is an array representing each lyric line, with its text, timing, target indices, and the starting index of the first character in the final displayed text.
var chart_entries: Array[ChartParser.ParseChartResult] = []

var judgement: Judgement
var ui_handler: UiHandler

##################### Play-related data
var score := 0
var accuracy := 0.0

var combo := 0
var perfects := 0
var greats := 0
var goods := 0
var misses := 0

var is_playing := false

func _init(
	p_song_path: String,
	p_lyrics: Dictionary,
	p_audio_player: AudioStreamPlayer,
	p_lyric_container: HBoxContainer,
	p_lyric_letter: RichTextLabel,
	p_judge_line: ColorRect,
	p_judge_label: Label
) -> void:
	song_path = p_song_path
	lyrics = p_lyrics
	audio_player = p_audio_player
	lyric_container = p_lyric_container
	lyric_letter = p_lyric_letter
	judge_line = p_judge_line
	judge_label = p_judge_label

	var chart_parser = ChartParser.new()
	chart_entries = chart_parser.parse_chart(p_lyrics)
	glyphs = chart_parser.glyphs
	key_targets = chart_parser.key_targets
	judgement = Judgement.new(glyphs)

	ui_handler = UiHandler.new(lyric_container, lyric_letter, judge_line, judge_label)
	ui_handler.create_lyric_letters(chart_entries)
	ui_handler.call_deferred("build_word_offsets", chart_entries)

func play():
	is_playing = true
	audio_player.stream = load(song_path)
	audio_player.play()


var current_word_index := 0
var next_target_index := 0
func _process(_delta: float) -> void:
	if not is_playing:
		return

	var song_time := audio_player.get_playback_position()

	####### Positioning
	if ui_handler.word_offsets.is_empty():
		return

	while current_word_index + 1 < chart_entries.size() and chart_entries[current_word_index + 1].time <= song_time:
		current_word_index += 1
		
	ui_handler.position_letters(song_time, chart_entries, current_word_index)

	####### Update next_target_index based on song time
	if next_target_index >= key_targets.size():
		return

	var current_target := key_targets[next_target_index]

	var next_target_time: float = current_target.time
	# var word_text: String = chart_entries[current_target.word_index].text

	# We consider a target missed if we have passed the end of its timing window
	var target_end_window: float = current_target.time + Constants.PRESS_MARGIN_END

	if song_time > target_end_window:
		var current_char_label: RichTextLabel = lyric_container.get_child(key_targets[next_target_index].glyph_index)
		print("Missed target for glyph '%s' at time %.2f (current song time: %.2f)" % [glyphs[key_targets[next_target_index].glyph_index].character, next_target_time, song_time])
		judge_label.text = "MISSED!"
		next_target_index += 1
		current_char_label.add_theme_color_override("default_color", Color.from_rgba8(255, 0, 0))

func _input(event: InputEvent) -> void:
	if not event.is_pressed() or event is InputEventMouse:
		return

	var song_time := audio_player.get_playback_position()

	if next_target_index >= key_targets.size():
		return

	var target := key_targets[next_target_index]
	var input_result := judgement.judge_key_press(event, target, song_time)

	var current_char_label: RichTextLabel = lyric_container.get_child(target.glyph_index)

	if input_result == Judgement.JudgeResult.PERFECT:
		print("PERFECT hit for glyph '%s' at time %.2f!" % [glyphs[target.glyph_index].character, song_time])
		judge_label.text = "PERFECT!"
		next_target_index += 1
		current_char_label.add_theme_color_override("default_color", Color.from_rgba8(0, 255, 0))
	elif input_result == Judgement.JudgeResult.TOO_EARLY:
		print("TOO_EARLY for glyph '%s' at time %.2f" % [glyphs[target.glyph_index].character, song_time])
		judge_label.text = "TOO EARLY!"
		next_target_index += 1
		current_char_label.add_theme_color_override("default_color", Color.from_rgba8(255, 255, 0))
	elif input_result == Judgement.JudgeResult.TOO_LATE:
		print("TOO_LATE for glyph '%s' at time %.2f" % [glyphs[target.glyph_index].character, song_time])
		judge_label.text = "TOO LATE!"
		next_target_index += 1
		current_char_label.add_theme_color_override("default_color", Color.from_rgba8(255, 101, 0))
	elif input_result == Judgement.JudgeResult.MISS:
		print("MISS for glyph '%s' at time %.2f" % [glyphs[target.glyph_index].character, song_time])
		judge_label.text = "MISSED!"
		next_target_index += 1
		current_char_label.add_theme_color_override("default_color", Color.from_rgba8(255, 0, 0))
	elif input_result == Judgement.JudgeResult.WRONG_KEY:
		print("WRONG_KEY for glyph '%s' at time %.2f" % [glyphs[target.glyph_index].character, song_time])
		judge_label.text = "WRONG KEY!"
		next_target_index += 1
		current_char_label.text = "%s" % OS.get_keycode_string(event.keycode).to_lower() # Show the wrong key pressed
		current_char_label.add_theme_color_override("default_color", Color.from_rgba8(255, 0, 0))
