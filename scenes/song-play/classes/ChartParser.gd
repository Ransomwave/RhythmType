class_name ChartParser

var global_built_glyph_index := 0

## Glyphs keeps track of character positions and key target status.
var glyphs: Array[Dictionary] = []

## Key targets is a list of dictionaries with the time of the lyric and the corresponding glyph index in the final text that should be hit at that time.
var key_targets: Array[Dictionary] = []

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
				"time": float(t) + target_index * Constants.LETTER_EXTRA_TIME, # Stagger targets based on their position in the word
				"glyph_index": glyph_index,
				"word_index": result.size() - 1,
			})

	return result