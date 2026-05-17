extends Node

@onready var audio_player: AudioStreamPlayer = $AudioPlayer
@onready var lyric_container: HBoxContainer = $Gameplay/LyricsLine/LyricsHContainer
@onready var lyric_letter: RichTextLabel = $LetterTemplate
@onready var judgement_line: ColorRect = $Gameplay/JudgeLine
@onready var judge_label: Label = $Gameplay/JudgeLabel

@onready var lyric_font = lyric_letter.get_theme_font("font")

@onready var judge_x = judgement_line.position.x

var music_to_load := load("res://maps/reddit_recap/song.mp3")
# var music_to_load := load("res://maps/want_you_gone/song.mp3")

# Simulated chart data for testing purposes
# var file_lyrics := {
# 	5.2: "[W]ell ",
# 	5.86: " here we [a]re again",
# 	6.3: " [a]re again. ",
# 	8.4: " It's always [s][u]ch a pleasure. ",
# 	10.2: " [R]emember [w]hen you ",
# 	11.4: " [t]ried to kill me twi",
# 	13.0: "c[e]?"
# }

var file_lyrics := {
	2.65: "[I]t's ",
	2.9059: "time ",
	3.153: "for ",
	3.3419999: "the ",
	3.662: "[R]ed",
	4.357: "[d]it ",
	4.967: "[R]e",
	5.631: "[c]ap ",
	6.319: "[R]ed",
	6.67: "[d]it ",
	7.01: "[R]e",
	7.384: "[c]ap ",
	7.894: "So ",
	8.00: "go ",
	8.2: "and ",
	8.5: "join ",
	8.7: "      ",
	8.9: "[r]",
	9.0: "           ",
	9.685: "[/]",
	9.885: "           ",
	10.34: "[L]ud",
	10.54: "        ",
	11.0: "[w]ig",
	11.2: "        ",
	11.70: "[Ahahah]",
	12.70: "[grennnnnnnnnnnnn]",
	14.8: "." # End of lyrics
}


## Glyphs keeps track of character positions and key target status.[br]
## - [b]global_index[/b]: The index in the final displayed text.[br]
## - [b]word_index[/b]: The index within its word.[br]
## - [b]local_index[/b]: The index within the original word.[br]
## - [b]is_target[/b]: Boolean indicating if this is a key press target.[br]
var glyphs: Array[Dictionary] = []

## Key targets is a list of dictionaries with the time of the lyric and the corresponding glyph index in the final text that should be hit at that time.[br]
## Each entry has:[br]
## - [b]word_index[/b]: The index of the word in the chart entries.[br]
## - [b]local_index[/b]: The index of the character within the original word (including brackets).[br]
## - [b]start_window[/b]: The time when the key press window starts for this target.[br]
## - [b]end_window[/b]: The time when the key press window ends for this target.[br]
var key_targets: Array[Dictionary] = []

var global_built_glyph_index := 0

## Captures each word's first letter position after layout
var word_offsets: Array[float] = []

## Chart entries is an array of dictionaries representing each lyric line, with its text, timing, target indices, and the starting index of the first character in the final displayed text.[br]
## Each entry has:[br]
## - [b]time[/b]: The time in seconds when this lyric should be hit.[br]
## - [b]text[/b]: The full text of the lyric line, with brackets removed.[br]
## - [b]targets[/b]: An array of indices indicating which characters in the text are key press targets (indices are relative to the final displayed text, after removing brackets).[br]
## - [b]start_index[/b]: The index in the final displayed text where this lyric line starts (the index of the first character of this line in the final text). This is used to calculate the position of the lyric line for key press timing and visual feedback
var chart_entries: Array[Dictionary] = []

func parse_chunk(word: String) -> Dictionary:
	var result = {
		"text": "",
		"targets": [],
		"start_index": 0
	}

	var in_target := false
	var word_index := 0
	for i in range(word.length()):
		var current_char = word[i]
		if current_char == "[":
			in_target = true
			continue
		elif current_char == "]":
			in_target = false
			continue

		result["text"] += current_char

		# Build the glyph data for this character
		glyphs.append({
			"char": current_char,
			"global_index": global_built_glyph_index, # Index in the final text (after removing brackets)
			"word_index": word_index, # Index in the current word (after removing brackets)
			"local_index": i, # Index in the original word (including brackets)
			"is_target": in_target
		})

		if word_index == 0:
			result.start_index = global_built_glyph_index

		if in_target:
			result["targets"].append(word_index) # Adjust index for removed brackets
		
		# Only incremented when we actually add a character to the text, so it reflects the index in the final displayed string
		word_index += 1
		global_built_glyph_index += 1

	return result

func parse_chart(chart: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var times: Array = chart.keys()
	times.sort()

	for t in times:
		var parsed = parse_chunk(str(chart[t]))
		result.append({
			"time": float(t),
			"text": parsed["text"],
			"targets": parsed["targets"],
			"start_index": parsed["start_index"]
		})

		# Build glyph key targets based on the parsed data
		for target_index in parsed["targets"]:
			var glyph_index = parsed["start_index"] + target_index
			key_targets.append({
				"time": float(t),
				"glyph_index": glyph_index,
				"word_index": result.size() - 1,
			})

	return result

func create_lyric_letters(entries: Array[Dictionary]) -> void:
	for entry in entries:
		var text: String = entry["text"]
		var targets: Array = entry["targets"]

		print("Creating letters for lyric: '%s' with targets at indices %s" % [text, str(targets)])

		for letterIdx in range(text.length()):
			var letter = text[letterIdx]
			var new_letter_node = lyric_letter.duplicate() as RichTextLabel
			new_letter_node.name = "Letter_%d" % letterIdx
			new_letter_node.text = letter
			new_letter_node.size = lyric_font.get_string_size(letter)
			lyric_container.add_child(new_letter_node)
			new_letter_node.show()

			if letterIdx in targets:
				print("Letter '%s' is a target!" % letter)
				new_letter_node.add_theme_color_override("default_color", Color.from_rgba8(80, 80, 80))

# After all letters are created, we can calculate the offsets for each word based on the position of their first letter
func build_word_offsets() -> void:
	word_offsets.clear()
	for entry in chart_entries:
		print("Calculating offset for word '%s' starting at index %d" % [entry["text"], entry["start_index"]])
		var start_index: int = entry["start_index"]
		var letter_node := lyric_container.get_child(start_index) as Control
		var offset_x := letter_node.position.x + (letter_node.size.x * 0.5)
		word_offsets.append(offset_x)

enum JudgeResult {
	TOO_EARLY,
	HIT,
	TOO_LATE,
	WRONG_KEY,
	NONE
}

func judge_key_press(event: InputEvent, target: Dictionary, song_time: float) -> JudgeResult:
	if not (event is InputEventKey):
		return JudgeResult.NONE

	var expected_char: String = glyphs[target["glyph_index"]]["char"]
	var expected_keycode := OS.find_keycode_from_string(expected_char)

	var char_time: float = target["time"]
	var word_index: int = target["word_index"]
	var word_text: String = chart_entries[word_index]["text"]
	var extra_time: float = word_text.length() * Constants.LETTER_EXTRA_TIME

	var start_window: float = char_time - Constants.PRESS_MARGIN_START
	var end_window: float = char_time + extra_time + Constants.PRESS_MARGIN_END

	if song_time < start_window:
		return JudgeResult.TOO_EARLY
	if song_time > end_window:
		return JudgeResult.TOO_LATE

	# We are in the timing window; now decide hit vs wrong key
	if event.keycode != expected_keycode:
		return JudgeResult.WRONG_KEY
		
	return JudgeResult.HIT

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Song Play Scene Ready!")

	chart_entries = parse_chart(file_lyrics)
	create_lyric_letters(chart_entries)
	call_deferred("build_word_offsets")
	# build_word_offsets()

	audio_player.stream = music_to_load
	audio_player.play()

var current_word_index := 0

var next_target_index := 0
func _process(_delta: float) -> void:
	var song_time := audio_player.get_playback_position()

	####### Positioning
	if word_offsets.is_empty():
		return

	while current_word_index + 1 < chart_entries.size() and chart_entries[current_word_index + 1]["time"] <= song_time:
		current_word_index += 1
		
	var current_word := chart_entries[current_word_index]
	var next_word_index = current_word_index + 1 if current_word_index + 1 < chart_entries.size() else current_word_index
	var next_word := chart_entries[next_word_index]
	var current_offset := word_offsets[current_word_index]
	var next_offset := word_offsets[next_word_index]

	# Update lyric position based on current song time and the timing of the current and next words
	var denom: float = max(next_word["time"] - current_word["time"], 0.0001)
	var t: float = clamp((song_time - current_word["time"]) / denom, 0.0, 1.0)
	var offset: float = lerp(current_offset, next_offset, t)
	lyric_container.position.x = judge_x - offset

	####### Update next_target_index based on song time
	if next_target_index >= key_targets.size():
		return

	var current_target := key_targets[next_target_index]

	var next_target_time: float = current_target["time"]
	var word_text: String = chart_entries[current_target["word_index"]]["text"]
	var extra_time: float = word_text.length() * Constants.LETTER_EXTRA_TIME

	# We consider a target missed if we have passed the end of its timing window
	var target_end_window = current_target["time"] + extra_time + Constants.PRESS_MARGIN_END

	if song_time > target_end_window:
		var current_char_label: RichTextLabel = lyric_container.get_child(key_targets[next_target_index]["glyph_index"])
		print("Missed target for glyph '%s' at time %.2f (current song time: %.2f)" % [glyphs[key_targets[next_target_index]["glyph_index"]]["char"], next_target_time, song_time])
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
	var input_result := judge_key_press(event, target, song_time)

	var current_char_label: RichTextLabel = lyric_container.get_child(target["glyph_index"])

	if input_result == JudgeResult.HIT:
		print("HIT target for glyph '%s' at time %.2f!" % [glyphs[target["glyph_index"]]["char"], song_time])
		judge_label.text = "PERFECT!"
		next_target_index += 1
		current_char_label.add_theme_color_override("default_color", Color.from_rgba8(0, 255, 0)) # Change color to indicate hit
	elif input_result == JudgeResult.TOO_EARLY:
		print("TOO_EARLY for glyph '%s' at time %.2f" % [glyphs[target["glyph_index"]]["char"], song_time])
		judge_label.text = "TOO EARLY!"
		next_target_index += 1
		current_char_label.add_theme_color_override("default_color", Color.from_rgba8(255, 255, 0))
	elif input_result == JudgeResult.TOO_LATE:
		print("TOO_LATE for glyph '%s' at time %.2f" % [glyphs[target["glyph_index"]]["char"], song_time])
		judge_label.text = "TOO LATE!"
		next_target_index += 1
		current_char_label.add_theme_color_override("default_color", Color.from_rgba8(255, 101, 0))
	elif input_result == JudgeResult.WRONG_KEY:
		print("WRONG_KEY for glyph '%s' at time %.2f" % [glyphs[target["glyph_index"]]["char"], song_time])
		judge_label.text = "WRONG KEY!"
		next_target_index += 1
		current_char_label.add_theme_color_override("default_color", Color.from_rgba8(255, 0, 0))