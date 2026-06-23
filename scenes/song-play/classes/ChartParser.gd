class_name ChartParser

## [b]character[/b]: The character of the glyph.[br]
## [b]global_index[/b]: The index of the glyph in the final displayed text (after removing brackets). This is used to calculate the position of the glyph for key press timing and visual feedback[br]
## [b]word_index[/b]: The index of the word in the chart entries.[br]
## [b]local_index[/b]: The index of the character within the original word (including brackets).[br]
## [b]is_target[/b]: Whether the glyph is a key press target.[br]
class Glyph:
	var character: String
	var global_index: int
	var word_index: int
	var local_index: int
	var is_target: bool

	func _init(p_char: String, p_global_index: int, p_word_index: int, p_local_index: int, p_is_target: bool) -> void:
		character = p_char
		global_index = p_global_index
		word_index = p_word_index
		local_index = p_local_index
		is_target = p_is_target
		
## [b]time[/b]: The time in seconds when this key press should be hit.[br]
## [b]glyph_index[/b]: The index of the glyph in the final displayed text (after removing brackets). This is used to calculate the position of the glyph for key press timing and visual feedback[br]
## [b]word_index[/b]: The index of the word in the chart entries.[br]
class KeyTarget:
	var time: float
	var glyph_index: int
	var word_index: int

	func _init(p_time: float, p_glyph_index: int, p_word_index: int) -> void:
		time = p_time
		glyph_index = p_glyph_index
		word_index = p_word_index

## Parsed chunk result[br]
## This is a temporary class to store the parsed data for each word.[br]
## [b]text[/b]: The text of the word (without brackets).[br]
## [b]targets[/b]: An array of indices indicating which characters in the word are key press targets (indices are relative to the final displayed text, after removing brackets).[br]
## [b]start_index[/b]: The index in the final displayed text where this word starts (the index of the first character of this word in the final text).[br]
class ParseChunkResult:
	var text: String
	var targets: Array[int]
	var start_index: int


## Parse chart result[br]
## This is a temporary class to store the parsed data for each lyric line.[br]
## [b]time[/b]: The time in seconds when this lyric line should be hit.[br]
## [b]text[/b]: The text of the lyric line, with brackets removed.[br]
## [b]targets[/b]: An array of indices indicating which characters in the text are key press targets (indices are relative to the final displayed text, after removing brackets).[br]
## [b]start_index[/b]: The index in the final displayed text where this lyric line starts (the index of the first character of this line in the final text). This is used to calculate the position of the lyric line for key press timing and visual feedback
class ParseChartResult:
	var time: float
	var text: String
	var targets: Array[int]
	var start_index: int

	func _init(p_time: float, p_text: String, p_targets: Array[int], p_start_index: int) -> void:
		time = p_time
		text = p_text
		targets = p_targets
		start_index = p_start_index
	

var global_built_glyph_index := 0

## Glyphs keeps track of character positions and key target status.
var glyphs: Array[Glyph] = []

## Key targets is a list of dictionaries with the time of the lyric and the corresponding glyph index in the final text that should be hit at that time.
var key_targets: Array[KeyTarget] = []

func parse_chunk(word: String) -> ParseChunkResult:
	var result := ParseChunkResult.new()
	result.text = ""
	result.targets = []
	result.start_index = 0

	var in_target := false
	var word_index := 0
	for letter_idx in range(word.length()):
		var current_char = word[letter_idx]
		if current_char == "[":
			in_target = true
			continue
		elif current_char == "]":
			in_target = false
			continue

		result["text"] += current_char

		# Build the glyph data for this character
		glyphs.append(Glyph.new(
			current_char,
			global_built_glyph_index, # Index in the final text (after removing brackets)
			word_index, # Index in the current word (after removing brackets)
			letter_idx, # Index in the original word (including brackets)
			in_target
		))

		if word_index == 0:
			result.start_index = global_built_glyph_index

		if in_target:
			result.targets.append(word_index) # Adjust index for removed brackets
		
		# Only incremented when we actually add a character to the text, so it reflects the index in the final displayed string
		word_index += 1
		global_built_glyph_index += 1

	return result

## Parse the raw chart data into a structured format
func parse_chart(chart: Dictionary[float, String]) -> Array[ParseChartResult]:
	var result: Array[ParseChartResult] = []
	var times := chart.keys()
	times.sort()

	for t in times:
		var parsed := parse_chunk(str(chart[t]))
		result.append(ParseChartResult.new(
			float(t),
			parsed.text,
			parsed.targets,
			parsed.start_index
		))

		# Build glyph key targets based on the parsed data
		for target_index in parsed.targets:
			var time := float(t) + (target_index * Constants.LETTER_EXTRA_TIME)
			var glyph_index := parsed.start_index + target_index
			key_targets.append(KeyTarget.new(
				time, # Stagger targets based on their position in the word
				glyph_index,
				result.size() - 1, # word_index
			))

	return result