# Regularization Learning Networks (RLN) - keras3 R implementation
# Based on: https://arxiv.org/abs/1805.06440
# Original Python/Keras: https://github.com/irashavitt/regularization_learning_networks

library(keras3)

#' RLN Callback
#'
#' Implements Regularization Learning as a Keras callback. Learns per-weight
#' regularization coefficients (lambdas) during training rather than using a
#' fixed global regularization strength.
#'
#' @param layer  A Keras layer whose kernel will be regularized.
#' @param norm   Regularization norm: 1 (L1) or 2 (L2). L1 recommended.
#' @param avg_reg  Mean regularization coefficient (Theta in the paper).
#'                 Operates in log scale, so -7.5 ~ exp(-7.5) ≈ 0.00055.
#' @param learning_rate  Learning rate for lambda updates (nu in the paper).
#'                       Large values (1e4–1e6) work best due to log-scale updates.
RLNCallback <- new_callback_class(
  classname = "RLNCallback",

  initialize = function(layer, norm = 1L, avg_reg = -7.5, learning_rate = 6e5) {
    stopifnot("Only L1 and L2 norms are supported" = norm %in% c(1, 2))
    private$kernel    <- layer$kernel
    private$norm      <- as.integer(norm)
    private$avg_reg   <- avg_reg
    private$lr        <- learning_rate
    private$weights   <- NULL
    private$prev_weights <- NULL
    private$lambdas   <- NULL
    private$prev_regularization <- NULL
  },

  on_train_begin = function(logs = NULL) {
    private$update_values()
    private$lambdas <- matrix(
      private$avg_reg,
      nrow = nrow(private$weights),
      ncol = ncol(private$weights)
    )
  },

  on_batch_end = function(batch, logs = NULL) {
    private$prev_weights <- private$weights
    private$update_values()
    gradients <- private$weights - private$prev_weights

    if (private$norm == 1L) {
      norms_derivative <- sign(private$weights)
    } else {
      norms_derivative <- private$weights * 2
    }

    if (!is.null(private$prev_regularization)) {
      # Update lambdas via gradient step
      lambda_gradients <- gradients * private$prev_regularization
      private$lambdas  <- private$lambdas - private$lr * lambda_gradients

      # Project onto simplex: keep mean(lambdas) == avg_reg
      translation      <- private$avg_reg - mean(private$lambdas)
      private$lambdas  <- private$lambdas + translation
    }

    # Clip lambdas to prevent weight update overflow
    ratio <- private$weights / norms_derivative
    max_lambdas <- log(abs(ratio))
    max_lambdas[!is.finite(max_lambdas)] <- Inf   # NaN → no clipping (equiv. fillna(inf))
    private$lambdas <- pmin(private$lambdas, max_lambdas)

    # Apply regularization and push updated weights back to the layer
    regularization <- norms_derivative * exp(private$lambdas)
    # Guard: zero out any non-finite regularization terms to avoid NaN propagation
    regularization[!is.finite(regularization)] <- 0
    new_weights <- private$weights - regularization
    private$kernel$assign(t(new_weights))          # transpose back to kernel shape
    private$prev_regularization <- regularization
  },

  private = list(
    kernel               = NULL,
    norm                 = NULL,
    avg_reg              = NULL,
    lr                   = NULL,
    weights              = NULL,
    prev_weights         = NULL,
    lambdas              = NULL,
    prev_regularization  = NULL,

    # Reads current kernel values and stores them transposed (outputs × inputs),
    # matching the DataFrame(kernel.T) convention in the original Python code.
    update_values = function() {
      private$weights <- t(as.array(private$kernel))
    }
  )
)


# ── Example usage (see keras_tutorial.R) ─────────────────────────────────────
#
# set.seed(42)
#
# n_samples  <- 1000L
# n_features <- 20L
# n_classes  <- 3L
#
# x_train <- matrix(rnorm(n_samples * n_features), nrow = n_samples)
# y_train <- to_categorical(sample(0:(n_classes - 1), n_samples, replace = TRUE))
#
# model <- keras_model_sequential(input_shape = n_features) |>
#   layer_dense(64, activation = "relu") |>
#   layer_dense(32, activation = "relu") |>
#   layer_dense(n_classes, activation = "softmax")
#
# model |> compile(
#   optimizer = optimizer_adam(),
#   loss      = "categorical_crossentropy",
#   metrics   = "accuracy"
# )
#
# # Attach RLN to the first Dense layer
# rln <- RLNCallback(
#   layer         = model$layers[[2]],   # first hidden layer (index 1 is InputLayer)
#   norm          = 1L,
#   avg_reg       = -7.5,
#   learning_rate = 6e5
# )
#
# model |> fit(
#   x_train, y_train,
#   epochs          = 10L,
#   batch_size      = 32L,
#   validation_split = 0.2,
#   callbacks       = list(rln),
#   verbose         = 1L
# )
