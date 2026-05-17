class_name Judgement

enum JudgeResult {
	TOO_EARLY,
	HIT,
	TOO_LATE,
	WRONG_KEY,
	NONE
}

var glyphs: Array[Dictionary] = []

func _init(glyphs_array: Array[Dictionary]) -> void:
	glyphs = glyphs_array

func judge_key_press(event: InputEvent, target: Dictionary, song_time: float) -> JudgeResult:
	if not (event is InputEventKey):
		return JudgeResult.NONE

	var expected_char: String = glyphs[target["glyph_index"]]["char"]
	var expected_keycode := OS.find_keycode_from_string(expected_char)

	var char_time: float = target["time"]
	# var word_index: int = target["word_index"]
	# var word_text: String = chart_entries[word_index]["text"]

	var start_window: float = char_time - Constants.PRESS_MARGIN_START
	var end_window: float = char_time + Constants.PRESS_MARGIN_END

	if event.keycode != expected_keycode:
		return JudgeResult.WRONG_KEY

	if song_time < start_window:
		return JudgeResult.TOO_EARLY
	if song_time > end_window:
		return JudgeResult.TOO_LATE
		
	return JudgeResult.HIT