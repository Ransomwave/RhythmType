extends Node

@onready var audio_player: AudioStreamPlayer = $AudioPlayer
@onready var lyric_container: HBoxContainer = $LyricsLine/HBoxContainer
@onready var lyric_letter: RichTextLabel = $LetterTemplate
@onready var judgement_line: ColorRect = $JudgementLine

@onready var lyric_font = lyric_letter.get_theme_font("font")

@onready var judge_x = judgement_line.position.x

var music_to_load := load("res://maps/want_you_gone/song.mp3")

# Simulated chart data for testing purposes
var file_lyrics = {
	5.2: "[W]ell ",
	5.86: " here we [a]re again. ",
	8.4: " It's always [s][u]ch a pleasure. ",
	10.2: " [R]emember [w]hen you ",
	11.4: " [t]ried to kill me twi",
	13.0: "c[e]?"
}

			# { text = "[W]ell,", time = 5.2 },
			# { text = " here we [a]re again.", time = 5.86 },
			# { text = " It's always [s][u]ch a pleasure.", time = 8.4, sameLyricDifference = 0.2 },
			# { text = " [R]emember [w]hen you", time = 10.2, sameLyricDifference = 0.7 },
			# { text = " [t]ried to kill me twi", time = 11.4 },
			# { text = "c[e]?", time = 13 },

# char: {
# 	"global_index": 0, # Index in the final text (after removing brackets)
# 	"word_index": 0, # Index within the current word
#	"local_index": 0, # Index within the original word (including brackets)
# 	"is_target": false
# }
var glyphs: Array[Dictionary] = []

# char: {
#	word_index, local_index, start_window, end_window.
#}
var key_targets: Array[Dictionary] = [] # List of dictionaries with "time" and "glyph_index"

var global_glyph_index := 0

var word_offsets: Array[float] = []

var chart_entries: Array[Dictionary] = []

func parse_chunk(word: String) -> Dictionary:
	var result = {
		"text": "",
		"targets": [],
		"start_index": 0 # Index relative to the final text where this lyric starts
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
			"global_index": global_glyph_index, # Index in the final text (after removing brackets)
			"word_index": word_index, # Index in the current word (after removing brackets)
			"local_index": i, # Index in the original word (including brackets)
			"is_target": in_target
		})

		if word_index == 0:
			result.start_index = global_glyph_index

		if in_target:
			result["targets"].append(word_index) # Adjust index for removed brackets
		
		# Only incremented when we actually add a character to the text, so it reflects the index in the final displayed string
		word_index += 1
		global_glyph_index += 1

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
		key_targets.append({
			"time": float(t),
			"glyph_index": parsed["start_index"] # The index of the first character of this lyric in the final text
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
				new_letter_node.add_theme_color_override("default_color", Color(0, 1, 0)) # Highlight target letters

func build_word_offsets() -> void:
	word_offsets.clear()
	for entry in chart_entries:
		print("Calculating offset for word '%s' starting at index %d" % [entry["text"], entry["start_index"]])
		var start_index: int = entry["start_index"]
		var letter_node := lyric_container.get_child(start_index) as Control
		var offset_x := letter_node.position.x + (letter_node.size.x * 0.5)
		word_offsets.append(offset_x)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Song Play Scene Ready!")

	chart_entries = parse_chart(file_lyrics)
	create_lyric_letters(chart_entries)
	call_deferred("build_word_offsets")

	audio_player.stream = music_to_load
	audio_player.play()

var current_word_index := 0

var press_margin_start := 0.5
var press_margin_end := 0.5
var letter_extra_time := 0.2
func _process(delta: float) -> void:
	var song_time = audio_player.get_playback_position()
	if word_offsets.is_empty():
		return

	while current_word_index + 1 < chart_entries.size() and chart_entries[current_word_index + 1]["time"] <= song_time:
		current_word_index += 1
		
	var current_word = chart_entries[current_word_index]
	var next_word_index = current_word_index + 1 if current_word_index + 1 < chart_entries.size() else current_word_index
	var next_word = chart_entries[next_word_index]
	var current_offset = word_offsets[current_word_index]
	var next_offset = word_offsets[next_word_index]

	var start_window = current_word["time"] - press_margin_start
	var end_window = current_word["time"] + (press_margin_end + letter_extra_time) + press_margin_end

	# Update lyric position based on current song time and the timing of the current and next words
	var denom = max(next_word["time"] - current_word["time"], 0.0001)
	var t = clamp((song_time - current_word["time"]) / denom, 0.0, 1.0)
	var offset = lerp(current_offset, next_offset, t)
	lyric_container.position.x = judge_x - offset

	print("Current word: '%s' (targets at %s), song time: %.2f, offset: %.2f" % [current_word["text"], str(current_word["targets"]), song_time, offset])