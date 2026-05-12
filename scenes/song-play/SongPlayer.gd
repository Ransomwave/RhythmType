class_name SongPlayer

var path_to_song: String
var lyrics: Dictionary[float, String]

@warning_ignore("SHADOWED_VARIABLE")
func _init(path_to_song: String, lyrics: Dictionary[float, String]) -> void:
    self.path_to_song = path_to_song
    self.lyrics = lyrics