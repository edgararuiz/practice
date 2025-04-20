library(tidyverse)
library(tidymodels)

lendingclub_dat <- read_csv("endtoend/loans_full_schema.csv")

colnames(lendingclub_dat)

lendingclub_dat |>
  mutate(across(c(starts_with("annual")), ~ as.numeric(.))) |> 
  select(interest_rate, starts_with("annual")) |> 
  head()


set.seed(1234)

train_test_split <- initial_split(lendingclub_dat)
lend_train <- training(train_test_split)
lend_test <- testing(train_test_split)

rec_obj <- recipe(interest_rate ~ ., data = lend_train) |> 
  step_mutate(homeownership = factor(homeownership, levels = c("MORTGAGE", "RENT", "OWN"))) |> 
  step_rm(emp_title, state, state, application_type, verified_income, verification_income_joint, loan_purpose, application_type, grade, sub_grade, issue_month, loan_status, initial_listing_status, disbursement_method) |> 
  step_zv(all_predictors()) |>   
  step_integer(homeownership) |> 
  step_normalize(all_numeric_predictors()) |>
  step_impute_mean(all_numeric_predictors())

rec_obj

lend_lasso <- 
  linear_reg(penalty = tune(), mixture = 1) |> 
  set_engine("glmnet")

lend_lasso_wflow <-
  workflow() |>
  add_model(lend_lasso) |>
  add_recipe(rec_obj)


lambda_grid <- 
  grid_regular(penalty(), levels = 50)

lasso_grid <- 
  lend_lasso_wflow |> 
  tune_grid(grid = lambda_grid, resamples = vfold_cv(lend_train))

lasso_grid

lasso_grid |> 
  collect_metrics()

lasso_grid |> 
  autoplot()

final_lasso_wflow <- 
  lend_lasso_wflow |> 
  finalize_workflow(list(penalty = 0.1))

lend_lasso_fit <-
  final_lasso_wflow |>
  fit(data = lend_train)

lend_lasso_fit
