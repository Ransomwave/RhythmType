extends RefCounted
class_name UiHandler

var lyric_container: HBoxContainer
var lyric_letter: RichTextLabel
var lyric_font: Font
var judge_line: ColorRect
var judge_label: Label
var judge_x: float

var word_offsets: Array[float] = []

var judgement: Judgement

func _init(
	p_lyric_container: HBoxContainer,
	p_lyric_letter: RichTextLabel,
	p_judge_line: ColorRect,
	p_judge_label: Label,
) -> void:
	lyric_container = p_lyric_container
	lyric_letter = p_lyric_letter
	judge_line = p_judge_line
	judge_label = p_judge_label

	
	lyric_font = lyric_letter.get_theme_font("font")
	judge_x = judge_line.position.x

func connect_listeners():
	SongPlayer.judgement.on_judgement.connect(self.on_judgement)

func create_lyric_letters(entries: Array[ChartParser.ParseChartResult]) -> void:
	for entry in entries:
		var text: String = entry.text
		var targets: Array = entry.targets

		print("Creating letters for lyric: '%s' with targets at indices %s" % [text, str(targets)])

		for letterIdx in range(text.length()):
			var letter = text[letterIdx]
			print("Letter '%s' at index %d" % [letter, letterIdx])

			# var new_letter_node = lyric_letter.duplicate() as RichTextLabel
			var new_letter_node = RichTextLabel.new()
			new_letter_node.name = "Letter_%d" % letterIdx
			new_letter_node.text = letter
			new_letter_node.size = lyric_font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, Constants.LETTER_FONT_SIZE)
			new_letter_node.custom_minimum_size = new_letter_node.size
			new_letter_node.add_theme_font_override("normal_font", lyric_font)
			new_letter_node.add_theme_font_size_override("normal_font_size", Constants.LETTER_FONT_SIZE)
			lyric_container.add_child(new_letter_node)
			new_letter_node.show()

			if letterIdx in targets:
				print("Letter '%s' is a target!" % letter)
				new_letter_node.add_theme_color_override("default_color", Color.from_rgba8(80, 80, 80))

## After all letters are created, we can calculate the offsets for each word based on the position of their first letter
func build_word_offsets(chart_entries: Array[ChartParser.ParseChartResult]) -> void:
	word_offsets.clear()
	for entry in chart_entries:
		print("Calculating offset for word '%s' starting at index %d" % [entry.text, entry.start_index])
		var start_index: int = entry.start_index
		var letter_node := lyric_container.get_child(start_index) as Control
		var offset_x := letter_node.position.x + (letter_node.size.x * 0.5)
		word_offsets.append(offset_x)

## Visually position the lyrics container based on the current song time and the timing of the current and next words
func position_letters(song_time: float, chart_entries: Array[ChartParser.ParseChartResult], current_word_index: int):
	var current_word := chart_entries[current_word_index]
	var next_word_index = current_word_index + 1 if current_word_index + 1 < chart_entries.size() else current_word_index
	var next_word := chart_entries[next_word_index]
	var current_offset: float = word_offsets[current_word_index]
	var next_offset: float = word_offsets[next_word_index]

	# Update lyric position based on current song time and the timing of the current and next words
	var denom: float = max(next_word.time - current_word.time, 0.0001)
	var t: float = clamp((song_time - current_word.time) / denom, 0.0, 1.0)
	var offset: float = lerp(current_offset, next_offset, t)
	lyric_container.position.x = judge_x - offset

func on_judgement(input_result: Judgement.JudgeResult, event: InputEvent, target: ChartParser.KeyTarget, song_time: float) -> void:
	print("Received judgement: %s for glyph index %d at time %.2f" % [str(input_result), target.glyph_index, target.time])

	var current_char_label: RichTextLabel = lyric_container.get_child(target.glyph_index)

	if input_result == Judgement.JudgeResult.PERFECT:
		judge_label.text = "PERFECT!"
		current_char_label.add_theme_color_override("default_color", Color.from_rgba8(0, 255, 0))
	elif input_result == Judgement.JudgeResult.TOO_EARLY:
		judge_label.text = "TOO EARLY!"
		current_char_label.add_theme_color_override("default_color", Color.from_rgba8(255, 255, 0))
	elif input_result == Judgement.JudgeResult.TOO_LATE:
		judge_label.text = "TOO LATE!"
		current_char_label.add_theme_color_override("default_color", Color.from_rgba8(255, 101, 0))
	elif input_result == Judgement.JudgeResult.MISS:
		judge_label.text = "MISSED!"
		current_char_label.add_theme_color_override("default_color", Color.from_rgba8(255, 0, 0))
	elif input_result == Judgement.JudgeResult.WRONG_KEY:
		judge_label.text = "WRONG KEY!"
		current_char_label.text = "%s" % OS.get_keycode_string(event.keycode).to_lower() # Show the wrong key pressed
		current_char_label.add_theme_color_override("default_color", Color.from_rgba8(255, 0, 0))