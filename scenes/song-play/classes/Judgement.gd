extends Node
class_name Judgement

enum JudgeResult {
	MISS,
	TOO_EARLY,
	PERFECT,
	TOO_LATE,
	WRONG_KEY,
	NONE
}

var glyphs: Array[ChartParser.Glyph] = []

func _init(glyphs_array: Array[ChartParser.Glyph]) -> void:
	glyphs = glyphs_array

func judge_key_press(event: InputEvent, target: ChartParser.KeyTarget, song_time: float) -> JudgeResult:
	if not (event is InputEventKey):
		return JudgeResult.NONE

	var expected_char := glyphs[target.glyph_index].character
	var expected_keycode := OS.find_keycode_from_string(expected_char)

	var char_time := target.time
	var offset := song_time - char_time
	var start_window := -Constants.PRESS_MARGIN_START
	var end_window := Constants.PRESS_MARGIN_END

	if event.keycode != expected_keycode:
		return JudgeResult.WRONG_KEY

	if offset < start_window or offset > end_window:
		return JudgeResult.MISS
	if abs(offset) <= Constants.PERFECT_MARGIN:
		return JudgeResult.PERFECT
	if offset < 0:
		return JudgeResult.TOO_EARLY
	return JudgeResult.TOO_LATE