
library(sparklyr)
library(dplyr)

sc <- spark_connect(method = "databricks_connect")
lendingclub_dat <- tbl(sc, dbplyr::in_catalog("hive_metastore", "default", "lendingclub"))

lendingclub_local <- lendingclub_dat |> 
  head(10) |> 
  collect()

library(pins)
library(vetiver)
board <- board_connect(auth = "envvar")
model <- vetiver_pin_read(board, "garrett@posit.co/lending_club_model")

term <- lapply(strsplit(lendingclub_local$term, " "), function(x) x[[2]])
term <- as.numeric(term)

lendingclub_local$term <- term
lendingclub_local$bc_util <- as.numeric(lendingclub_local$bc_util)
lendingclub_local$all_util <- as.numeric(lendingclub_local$all_util)
lendingclub_local$bc_open_to_buy <- as.numeric(lendingclub_local$bc_open_to_buy)

predict(model, lendingclub_local)


predict_vetiver <- function(x) {
  board <- pins::board_connect(auth = "manual", server = "https://pub.demo.posit.team/", key = "brlZsHOg6DwIH9K2UDDW3msAn6TwFDF7")
  model <- vetiver::vetiver_pin_read(board, "garrett@posit.co/lending_club_model")
  term <- lapply(strsplit(lendingclub_local$term, " "), function(x) x[[2]])
  x$term <- as.numeric(term)
  x$bc_util <- as.numeric(lendingclub_local$bc_util)
  x$all_util <- as.numeric(lendingclub_local$all_util)
  x$bc_open_to_buy <- as.numeric(lendingclub_local$bc_open_to_buy)
  library(workflows)
  head(predict(model, x), 1)
}

predict_vetiver(lendingclub_local)

lendingclub_dat |> 
  spark_apply(predict_vetiver)


lendingclub_dat |> 
  head(100) |> 
  spark_apply(function(e) {x<-nrow(e);x+10})

x1 <-function(e) {x<-nrow(e); x + 10;}
x1(mtcars)

lendingclub_dat |> 
  spark_apply(function(x) {
    board <- pins::board_connect(auth = "manual")
    model <- vetiver::vetiver_pin_read(board, "garrett@posit.co/lending_club_model")
    term <- lapply(strsplit(lendingclub_local$term, " "), function(x) x[[2]])
    x$term <- as.numeric(term)
    x$bc_util <- as.numeric(lendingclub_local$bc_util)
    x$all_util <- as.numeric(lendingclub_local$all_util)
    x$bc_open_to_buy <- as.numeric(lendingclub_local$bc_open_to_buy)
    library(workflows)
    head(predict(model, x), 1)
  })
