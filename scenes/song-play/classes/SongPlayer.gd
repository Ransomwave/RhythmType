extends Node
class_name SongPlayer

##################### Song-related data
var path_to_song: String
var lyrics: Dictionary[float, String]

## Glyphs keeps track of character positions and key target status.
static var glyphs: Array[ChartParser.Glyph] = []

## Key targets is an array with the time of the lyric and the corresponding glyph index in the final text that should be hit at that time.
static var key_targets: Array[ChartParser.KeyTarget] = []

## Captures each word's first letter position after layout
static var word_offsets: Array[float] = []

## Chart entries is an array representing each lyric line, with its text, timing, target indices, and the starting index of the first character in the final displayed text.
static var chart_entries: Array[ChartParser.ParseChartResult] = []

var judgement: Judgement

##################### Play-related data
var score := 0
var accuracy := 0.0

var combo := 0
var perfects := 0
var greats := 0
var goods := 0
var misses := 0

func _init(p_path_to_song: String, p_lyrics: Dictionary[float, String]) -> void:
	path_to_song = p_path_to_song
	lyrics = p_lyrics

	var chart_parser = ChartParser.new()
	chart_entries = chart_parser.parse_chart(p_lyrics)
	glyphs = chart_parser.glyphs
	key_targets = chart_parser.key_targets
	judgement = Judgement.new(glyphs)
