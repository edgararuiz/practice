library(pins)
board <- board_connect(auth = "envvar")
pin_read(board, "garrett@posit.co/lending_club_model")
