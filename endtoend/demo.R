library(tidyverse)
library(tidymodels)
library(pins)

lendingclub_dat <- read_csv("endtoend/loans_full_schema.csv")

set.seed(1234)

train_test_split <- initial_split(lendingclub_dat)
lend_train <- training(train_test_split)
lend_test <- testing(train_test_split)

red_rec_obj <- recipe(interest_rate ~ ., data = lend_train) |>
  step_mutate(homeownership = factor(homeownership, levels = c("MORTGAGE", "RENT", "OWN"))) |> 
  step_rm(emp_title, state, state, application_type, verified_income, verification_income_joint, loan_purpose, application_type, grade, sub_grade, issue_month, loan_status, initial_listing_status, disbursement_method) |> 
  step_zv(all_predictors()) |>   
  step_integer(homeownership) |> 
  step_normalize(all_numeric_predictors()) |>
  step_impute_mean(all_numeric_predictors())

lend_linear <- 
  linear_reg()

lend_linear_wflow <-
  workflow() |>
  add_model(lend_linear) |>
  add_recipe(red_rec_obj)

lend_linear_fit <-
  lend_linear_wflow |>
  fit(data = lend_train)


board <- board_databricks("/Volumes/sol_eng_demo_nickp/end-to-end/r-models")
pin_write(board, lend_linear_fit, "lending-model-linear")


library(tidyverse)
library(tidymodels)
library(pins)
board <- board_databricks("/Volumes/sol_eng_demo_nickp/end-to-end/r-models")
model <- pin_read(board, "lending-model-linear")
lendingclub_dat <- read_csv("endtoend/loans_full_schema.csv")
predict(model, lendingclub_dat)


# ----------------------------- data from table -------------------------------
library(tidymodels)
library(sparklyr)
library(dplyr)
library(pins)

sc <- spark_connect(method = "databricks_connect", version = "15.4")

tbl_lending <- tbl(sc, I("sol_eng_demo_nickp.`end-to-end`.loans_full_schema"))

local_lending <- tbl_lending |> 
  sample_n(1000) |> 
  collect()


set.seed(1234)

train_test_split <- initial_split(local_lending)
lend_train <- training(train_test_split)
lend_test <- testing(train_test_split)

red_rec_obj <- recipe(interest_rate ~ ., data = lend_train) |>
  step_mutate(
    homeownership = factor(homeownership, levels = c("MORTGAGE", "RENT", "OWN")),
    annual_income_joint = as.numeric(annual_income_joint),
    debt_to_income_joint = as.numeric(debt_to_income_joint),
    months_since_last_delinq = as.numeric(months_since_last_delinq),
    emp_length = as.numeric(emp_length)
    ) |> 
  step_rm(
    emp_title, state, state, application_type, verified_income,
    verification_income_joint, loan_purpose, application_type, grade, sub_grade,
    issue_month, loan_status, initial_listing_status, disbursement_method,
    months_since_90d_late, months_since_last_credit_inquiry, public_record_bankrupt,
    paid_principal, debt_to_income
    ) |> 
  step_zv(all_predictors()) |>   
  step_integer(homeownership) |> 
  step_normalize(all_numeric_predictors()) |>
  step_impute_mean(all_numeric_predictors())

lend_linear <- linear_reg()

lend_linear_wflow <- workflow() |>
  add_model(lend_linear) |>
  add_recipe(red_rec_obj)

lend_linear_fit <- lend_linear_wflow |>
  fit(data = lend_train)

lend_linear_fit

board <- board_databricks("/Volumes/sol_eng_demo_nickp/end-to-end/r-models")
pin_write(board, lend_linear_fit, "lending-model-linear")

pin_download(board, "lending-model-linear")

lending_predict <- function(local_lending) {
  library(tidymodels)
  library(tidyverse)
  model <- readRDS("/Volumes/sol_eng_demo_nickp/end-to-end/r-models/lending-model-linear/20250420T213446Z-5067f/lending-model-linear.rds")
  preds <- predict(model, local_lending)
  local_lending |> 
    bind_cols(preds) |> 
    select(interest_rate, .pred)
}
lending_predict(local_lending)

#------------------------------------ prediction -----------------------------

pak::pak("mlverse/pysparklyr")

library(tidymodels)
library(sparklyr)
library(dplyr)
library(pins)

sc <- spark_connect(method = "databricks_connect")


columns <- "interest_rate double, _pred double"

tbl_lending <- tbl(sc, I("sol_eng_demo_nickp.`end-to-end`.loans_full_schema"))

board <- board_databricks("/Volumes/sol_eng_demo_nickp/end-to-end/r-models")

model <- pin_read(board, "lending-model-linear")

tbl_lending |> 
  head(10) |> 
  spark_apply(lending_predict, columns = columns)

