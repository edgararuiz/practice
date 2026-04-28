library(torch)
library(keras3)
library(yardstick)
source("rln/rln_mlp_torch.R")

# ── Data ──────────────────────────────────────────────────────────────────────

boston <- dataset_boston_housing()
x_train <- boston$train$x
y_train <- boston$train$y
x_test <- boston$test$x
y_test <- boston$test$y

# Standardize (fit on train only)
col_means <- colMeans(x_train)
col_sds <- apply(x_train, 2, sd)
x_train <- scale(x_train, center = col_means, scale = col_sds)
x_test <- scale(x_test, center = col_means, scale = col_sds)

# ── Train ──────────────────────────────────────────────────────────────────────

fitted <- rln_mlp_torch(
  x_train,
  y_train,
  hidden_units = 64L,
  norm = 1L,
  epochs = 100L,
  batch_size = 10L,
  validation_split = 0.2
)

# ── Training history ──────────────────────────────────────────────────────────

plot(
  fitted$history$train_loss,
  type = "l",
  col = "steelblue",
  lwd = 2,
  xlab = "Epoch",
  ylab = "MSE Loss",
  main = "RLN Training History"
)
if (!is.null(fitted$history$val_loss)) {
  lines(fitted$history$val_loss, col = "tomato", lwd = 2)
  legend(
    "topright",
    c("Train", "Validation"),
    col = c("steelblue", "tomato"),
    lty = 1,
    lwd = 2
  )
}

# ── Predict ───────────────────────────────────────────────────────────────────

fitted$model$eval()
x_test_t <- torch_tensor(x_test, dtype = torch_float())
predictions <- with_no_grad(as.array(fitted$model(x_test_t)))

# ── Evaluate ──────────────────────────────────────────────────────────────────

results <- tibble::tibble(
  truth = y_test,
  estimate = as.vector(predictions)
)

metrics(results, truth = truth, estimate = estimate)
