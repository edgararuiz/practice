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




