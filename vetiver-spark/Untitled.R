
# Actual script
# Connect to Spark and create table pointer
library(sparklyr)
library(dplyr)
sc <- spark_connect(method = "databricks_connect")
lendingclub_dat <- tbl(sc, dbplyr::in_catalog("hive_metastore", "default", "lendingclub"))

# Prepare the data, replicating what was done in the first article
lendingclub_prep <- lendingclub_dat |> 
  select(term, bc_util, bc_open_to_buy, all_util) |> 
  mutate(term = trimws(substr(term, 1,4))) |> 
  mutate(across(everything(), as.numeric)) |> 
  filter(!if_any(everything(), is.na)) 

# Show how Spark splits the row count into multiple discrite jobs
lendingclub_prep |> 
  spark_apply(nrow) |> 
  collect()

# Create the function that pulls the vetiver model and runs predictions
predict_vetiver <- function(x) {
  library(workflows)
  board <- pins::board_connect(
    auth = "manual", 
    server = "https://pub.demo.posit.team/",
    key = "[YOUR CONNECT KEY]"
  )
  model <- vetiver::vetiver_pin_read(board, "garrett@posit.co/lending_club_model")
  preds <- predict(model, x)
  x$pred <- preds[,1][[1]]
  x[x$pred >= 20, ]
}

# Test locally to make sure the function returns what's expected
# In this case, knowing that all_util drives a lot of the prediction
# we filtered for values over 130 
lendingclub_local <- lendingclub_prep |> 
  filter(all_util >= 130) |> 
  head(50) |> 
  collect()

predict_vetiver(lendingclub_local)

# Executes the prediction function over the entire dataset
lendingclub_prep |> 
  spark_apply(
    f = predict_vetiver,
    columns = "term double, bc_util double, bc_open_to_buy double, all_util double, pred double"
    ) 



