
# One time in your machine
pak::pak("mlverse/pysparklyr")
pak::pak("rstudio/reticulate")

# Actual script
library(sparklyr)
sc <- spark_connect(method = "databricks_connect")
lendingclub_dat <- tbl(sc, dbplyr::in_catalog("hive_metastore", "default", "lendingclub"))

predict_vetiver <- function(x) {
  board <- pins::board_connect(
    auth = "manual", 
    server = "https://pub.demo.posit.team/",
    key = "brlZsHOg6DwIH9K2UDDW3msAn6TwFDF7"
    )
  model <- vetiver::vetiver_pin_read(board, "garrett@posit.co/lending_club_model")
  term <- lapply(strsplit(x$term, " "), function(x) x[[2]])
  x$term <- as.numeric(term)
  x$bc_util <- as.numeric(x$bc_util)
  x$all_util <- as.numeric(x$all_util)
  x$bc_open_to_buy <- as.numeric(x$bc_open_to_buy)
  x <- x[!is.na(x$bc_util), ]
  x <- x[!is.na(x$all_util), ]
  x <- x[!is.na(x$bc_open_to_buy), ]
  library(workflows)
  preds <- predict(model, x)
  data.frame(mean_preds = mean(preds[, 1][[1]]))
}

lendingclub_dat |> 
  head(100) |> 
  spark_apply(predict_vetiver, columns = "mean_preds double") 



