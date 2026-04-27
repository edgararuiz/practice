# Tutorial using rln_mlp() — the self-contained RLN training function
# Reproduces the same Boston housing benchmark as keras_tutorial.R

library(keras3)
source("rln/rln_mlp.R")

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

# ── Evaluation helper ─────────────────────────────────────────────────────────

eval_mse <- function(model) {
  (model |> evaluate(x_test, y_test, verbose = 0L))[["loss"]]
}

repeat_test <- function(fit_fn, label, num_repeats = 10L) {
  results <- vapply(seq_len(num_repeats), \(i) eval_mse(fit_fn()), numeric(1))
  cat(sprintf("%s: %.2f (%.2f) MSE\n", label, mean(results), sd(results)))
  mean(results)
}

# ── 1. Baseline: parsnip-style keras3_mlp (no regularization) ────────────────

cat("\n=== Baseline (no regularization) ===\n")

baseline_mse <- repeat_test(
  \() {
    keras3_mlp(
      x_train,
      y_train,
      hidden_units = 128L,
      epochs = 100L,
      batch_size = 10L,
      verbose = 0L
    )
  },
  "No regularization"
)

# ── 2. L1 regularization (parsnip-style, fixed penalty) ──────────────────────

cat("\n=== L1 regularization ===\n")

best_l1_mse <- Inf
best_l1 <- 0.01

for (l1 in c(0.01, 0.1, 1.0)) {
  mse <- repeat_test(
    \() {
      keras3_mlp(
        x_train,
        y_train,
        hidden_units = 128L,
        penalty = l1,
        epochs = 100L,
        batch_size = 10L,
        verbose = 0L
      )
    },
    sprintf("L1 penalty = %.2f", l1)
  )
  if (mse < best_l1_mse) {
    best_l1_mse <- mse
    best_l1 <- l1
  }
}

cat(sprintf("Best L1: penalty=%.2f (MSE %.2f)\n", best_l1, best_l1_mse))

# ── 3. RLN (adaptive per-weight regularization) ───────────────────────────────

cat("\n=== RLN ===\n")

rln_grid <- list(
  list(theta = -8, log_lr = 6),
  list(theta = -10, log_lr = 5),
  list(theta = -10, log_lr = 6),
  list(theta = -10, log_lr = 7),
  list(theta = -12, log_lr = 6)
)

best_rln_mse <- Inf
best_theta <- -10
best_lr <- 1e6

for (params in rln_grid) {
  cur_theta <- params$theta
  cur_lr <- 10^params$log_lr
  mse <- repeat_test(
    \() {
      rln_mlp(
        x_train,
        y_train,
        hidden_units = 128L,
        norm = 1L,
        avg_reg = cur_theta,
        learning_rate = cur_lr,
        epochs = 100L,
        batch_size = 10L,
        verbose = 0L
      )
    },
    sprintf("RLN Theta=%d lr=%.0E", cur_theta, cur_lr)
  )
  if (mse < best_rln_mse) {
    best_rln_mse <- mse
    best_theta <- cur_theta
    best_lr <- cur_lr
  }
}

cat(sprintf(
  "Best RLN: Theta=%d lr=%.0E (MSE %.2f)\n",
  best_theta,
  best_lr,
  best_rln_mse
))

# ── 4. Final comparison ───────────────────────────────────────────────────────

cat("\n=== Results ===\n")
cat(sprintf("Baseline MSE : %.2f\n", baseline_mse))
cat(sprintf("Best L1  MSE : %.2f  (penalty = %.2f)\n", best_l1_mse, best_l1))
cat(sprintf(
  "Best RLN MSE : %.2f  (Theta = %d, lr = %.0E)\n",
  best_rln_mse,
  best_theta,
  best_lr
))
cat(sprintf(
  "Avg regularization — RLN: %.1E  vs  L1: %.2f\n",
  exp(best_theta),
  best_l1
))
