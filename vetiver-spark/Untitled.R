
# One time in your machine
pak::pak("mlverse/pysparklyr")
pak::pak("rstudio/reticulate")

# Actual script
library(sparklyr)
library(dplyr)
sc <- spark_connect(method = "databricks_connect")
lendingclub_dat <- tbl(sc, dbplyr::in_catalog("hive_metastore", "default", "lendingclub"))

predict_vetiver <- function(x) {
  library(workflows)
  board <- pins::board_connect(
    auth = "manual", 
    server = "https://pub.demo.posit.team/",
    key = "brlZsHOg6DwIH9K2UDDW3msAn6TwFDF7"
    )
  model <- vetiver::vetiver_pin_read(board, "garrett@posit.co/lending_club_model")
  preds <- predict(model, x)
  data.frame(mean_preds = mean(preds[, 1][[1]]))
}

lendingclub_dat |> 
  head() |> 
  mutate(term = trimws(substr(term, 1,4))) |> 
  select(term, bc_util, bc_open_to_buy, all_util) |> 
  mutate(across(everything(), as.numeric)) |> 
  spark_apply(predict_vetiver, columns = "mean_preds double") 

