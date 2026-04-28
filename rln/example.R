library(yardstick)
library(keras3)
source("rln/rln_mlp.R")

boston <- dataset_boston_housing()
x_train <- boston$train$x
y_train <- boston$train$y
x_test <- boston$test$x
y_test <- boston$test$y

col_means <- colMeans(x_train)
col_sds <- apply(x_train, 2, sd)
x_train <- scale(x_train, center = col_means, scale = col_sds)
x_test <- scale(x_test, center = col_means, scale = col_sds)

model <- rln_mlp(
  x_train,
  y_train,
  hidden_units = 64L,
  epochs = 100L,
  batch_size = 10L,
  validation_split = 0.2,
  norm = 1L
)

predictions <- predict(model, x_test)

results <- tibble::tibble(
  truth = y_test,
  estimate = as.vector(predictions)
)

metrics(results, truth = truth, estimate = estimate)
