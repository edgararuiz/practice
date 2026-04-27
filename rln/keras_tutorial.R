# R translation of the RLN Keras tutorial

library(keras3)
source(file.path(dirname(sys.frame(1)$ofile), "rln_callback.R"))

set.seed(32292) # Michael Jordan total career points

# ── Data ─────────────────────────────────────────────────────────────────────

boston <- dataset_boston_housing()
x_train <- boston$train$x
y_train <- boston$train$y
x_test <- boston$test$x
y_test <- boston$test$y

# Augment with 1,000 noise features to challenge regularization
noise_features <- 1000L
x_train <- cbind(
  x_train,
  matrix(rnorm(nrow(x_train) * noise_features), nrow = nrow(x_train))
)
x_test <- cbind(
  x_test,
  matrix(rnorm(nrow(x_test) * noise_features), nrow = nrow(x_test))
)

# Standardize (fit on train only)
col_means <- colMeans(x_train)
col_sds <- apply(x_train, 2, sd)
col_sds[col_sds == 0] <- 1
x_train <- scale(x_train, center = col_means, scale = col_sds)
x_test <- scale(x_test, center = col_means, scale = col_sds)

INPUT_DIM <- ncol(x_train)

# ── Model builder ─────────────────────────────────────────────────────────────

# Layer widths form a geometric series from INPUT_DIM down to 1 output
build_model <- function(layers = 4L, l1 = 0) {
  stopifnot(layers > 1)
  widths <- as.integer(round(
    exp(log(INPUT_DIM) * seq(layers - 1, 1) / layers)
  ))

  model <- keras_model_sequential(input_shape = INPUT_DIM)
  inner_l1 <- l1
  for (w in widths) {
    model <- model |>
      layer_dense(
        units = w,
        activation = "relu",
        kernel_initializer = "glorot_normal",
        kernel_regularizer = if (inner_l1 > 0) {
          regularizer_l1(inner_l1)
        } else {
          NULL
        }
      )
    inner_l1 <- 0 # only regularize the first layer (matches original)
  }
  model <- model |> layer_dense(1L, kernel_initializer = "glorot_normal")
  model |> compile(loss = "mean_squared_error", optimizer = "rmsprop")
  model
}

# ── Evaluation helper ─────────────────────────────────────────────────────────

test_model <- function(model_fn, label, num_repeats = 10L, callback_fn = NULL) {
  results <- numeric(num_repeats)
  for (i in seq_len(num_repeats)) {
    model     <- model_fn()
    callbacks <- if (!is.null(callback_fn)) callback_fn(model) else list()
    model |> fit(
      x_train, y_train,
      epochs     = 100L,
      batch_size = 10L,
      verbose    = 0L,
      callbacks  = callbacks
    )
    results[i] <- (model |> evaluate(x_test, y_test, verbose = 0L))[["loss"]]
  }
  cat(sprintf("%s: %.2f (%.2f) MSE\n", label, mean(results), sd(results)))
  mean(results)
}

# ── 1. Find optimal network depth ─────────────────────────────────────────────

cat("\n=== Searching for best depth ===\n")

best_layers <- 2L
best_depth_mse <- Inf

layers <- 1L
repeat {
  layers <- layers + 1L
  cur_score <- test_model(
    \() build_model(layers = layers),
    sprintf("Network with %d layers", layers)
  )
  if (cur_score >= best_depth_mse) {
    break
  }
  best_depth_mse <- cur_score
  best_layers <- layers
}

cat(sprintf("Best depth: %d layers (MSE %.2f)\n", best_layers, best_depth_mse))

# ── 2. Find best L1 regularization strength ──────────────────────────────────

cat("\n=== Searching for best L1 strength ===\n")

l1 <- 1e-3
best_l1 <- l1
best_l1_mse <- Inf

repeat {
  l1 <- l1 * 10
  cur_score <- test_model(
    \() build_model(layers = best_layers, l1 = l1),
    sprintf("L1 regularization %.0E", l1)
  )
  if (cur_score >= best_l1_mse) {
    break
  }
  best_l1_mse <- cur_score
  best_l1 <- l1
}

cat(sprintf("Best L1: %.0E (MSE %.2f)\n", best_l1, best_l1_mse))

# ── 3. Tune RLN hyperparameters ───────────────────────────────────────────────

cat("\n=== Tuning RLN ===\n")

rln_grid <- list(
  list(theta = -8, log_lr = 6),
  list(theta = -10, log_lr = 5),
  list(theta = -10, log_lr = 6),
  list(theta = -10, log_lr = 7),
  list(theta = -12, log_lr = 6)
)

best_rln_mse <- Inf
best_theta <- NULL
best_lr <- NULL

for (params in rln_grid) {
  cur_lr    <- 10^params$log_lr
  cur_theta <- params$theta
  cur_score <- test_model(
    model_fn    = \() build_model(layers = best_layers),
    callback_fn = function(m) {
      list(RLNCallback(
        layer         = m$layers[[2]],  # layers[[1]] is the InputLayer
        norm          = 1L,
        avg_reg       = cur_theta,
        learning_rate = cur_lr
      ))
    },
    label = sprintf("RLN Theta=%d lr=%.1E", cur_theta, cur_lr)
  )
  if (cur_score < best_rln_mse) {
    best_rln_mse <- cur_score
    best_theta <- cur_theta
    best_lr <- cur_lr
  }
}

cat(sprintf(
  "Best RLN: Theta=%d lr=%.1E (MSE %.2f)\n",
  best_theta,
  best_lr,
  best_rln_mse
))

# ── 4. Final comparison ───────────────────────────────────────────────────────

cat("\n=== Results ===\n")
cat(sprintf(
  "RLN outperforms L1: %.2f < %.2f\n",
  best_rln_mse,
  best_l1_mse
))
cat(sprintf(
  "Average regularization in RLN is much smaller: %.1E << %.1E\n",
  exp(best_theta),
  best_l1
))
