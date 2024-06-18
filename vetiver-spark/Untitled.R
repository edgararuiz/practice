
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
