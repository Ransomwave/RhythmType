class_name Constants

# The total time to hit a letter is PRESS_MARGIN_START + PRESS_MARGIN_END (0.35 seconds)
static var PRESS_MARGIN_START = 0.15
static var PRESS_MARGIN_END = 0.2

# Timing is judged relative to the target time:
# miss | too_early | perfect | too_late | miss
# "too_early" means early but still inside the early window
# "perfect" means within +/- PERFECT_MARGIN of the target time
# "too_late" means late but still inside the late window
static var PERFECT_MARGIN = 0.07

# LETTER_EXTRA_TIME is the delay added to each subsequent target character within a single lyric chunk.
static var LETTER_EXTRA_TIME = 0.1

static var LETTER_FONT_SIZE = 55