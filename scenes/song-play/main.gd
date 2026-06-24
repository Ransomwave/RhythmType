extends Node

@onready var audio_player: AudioStreamPlayer = $AudioPlayer
@onready var lyric_container: HBoxContainer = $Gameplay/LyricsLine/LyricsHContainer
@onready var lyric_letter: RichTextLabel = $LetterTemplate
@onready var judgement_line: ColorRect = $Gameplay/JudgeLine
@onready var judge_label: Label = $Gameplay/JudgeLabel

@onready var lyric_font = lyric_letter.get_theme_font("font")

@onready var judge_x = judgement_line.position.x

var music_to_load := "res://maps/reddit_recap/song.mp3"

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


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Song Play Scene Ready!")

	var song_player = SongPlayer.new(
		music_to_load,
		file_lyrics,
		audio_player,
		lyric_container,
		lyric_letter,
		judgement_line,
		judge_label
	)
	add_child(song_player)
	await get_tree().create_timer(5).timeout
	song_player.play()