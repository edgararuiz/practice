# Self-contained RLN training function, mirroring the style of parsnip's keras3_mlp()

library(keras3)
source(file.path(dirname(sys.frame(1)$ofile), "rln_callback.R"))

#' Fit a single-hidden-layer MLP with Regularization Learning
#'
#' Drop-in alternative to parsnip's keras3_mlp(). Instead of a fixed penalty,
#' each weight in the hidden layer learns its own regularization coefficient
#' via RLNCallback. Supports regression, binary, and multiclass outcomes.
#'
#' @param x           Numeric matrix of predictors.
#' @param y           Outcome vector or factor.
#' @param hidden_units  Number of units in the hidden layer.
#' @param norm          Regularization norm: 1 (L1) or 2 (L2).
#' @param avg_reg       Target mean of log-scale lambda coefficients (Theta).
#' @param learning_rate Step size for lambda updates (nu). Large values (1e4–1e6) typical.
#' @param epochs        Number of training epochs.
#' @param activation    Hidden layer activation function.
#' @param seed          Random seed for reproducibility.
#' @param ...           Additional args passed to keras3::fit() or keras3::compile().
rln_mlp <- function(
    x,
    y,
    hidden_units   = 5L,
    norm           = 1L,
    avg_reg        = -7.5,
    learning_rate  = 6e5,
    epochs         = 20L,
    activation     = "relu",
    seed           = sample.int(10^5, size = 1),
    ...
) {
  keras3::set_random_seed(seed)

  if (!is.matrix(x)) x <- as.matrix(x)
  if (is.character(y)) y <- as.factor(y)

  factor_y <- is.factor(y)
  binary_y <- factor_y && nlevels(y) == 2L

  if (factor_y) {
    if (binary_y) {
      y_mat <- matrix(class2ind(y, drop2nd = TRUE), ncol = 1)
    } else {
      y_mat <- class2ind(y)
    }
  } else {
    y_mat <- if (isTRUE(ncol(y) > 1)) as.matrix(y) else matrix(y, ncol = 1)
  }

  # Build model (same single-hidden-layer structure as parsnip's keras3_mlp)
  model <- keras3::keras_model_sequential(input_shape = ncol(x)) |>
    keras3::layer_dense(
      units              = hidden_units,
      activation         = activation,
      kernel_initializer = "glorot_normal"
    )

  if (binary_y) {
    model <- model |> keras3::layer_dense(units = 1L, activation = "sigmoid")
  } else if (factor_y) {
    model <- model |> keras3::layer_dense(units = ncol(y_mat), activation = "softmax")
  } else {
    model <- model |> keras3::layer_dense(units = ncol(y_mat), activation = "linear")
  }

  # Separate ... into compile vs fit args (mirrors parse_keras3_args logic)
  fit_arg_names <- c(
    "batch_size", "verbose", "callbacks", "validation_split",
    "validation_data", "shuffle", "class_weight", "sample_weight",
    "initial_epoch", "steps_per_epoch", "validation_steps"
  )
  compile_arg_names <- c(
    "optimizer", "loss", "metrics", "loss_weights",
    "weighted_metrics", "run_eagerly", "steps_per_execution", "jit_compile"
  )
  dots        <- list(...)
  fit_args     <- dots[names(dots) %in% fit_arg_names]
  compile_args <- dots[names(dots) %in% compile_arg_names]

  # Compile
  if (is.null(compile_args[["loss"]])) {
    compile_args$loss <- if (binary_y) "binary_crossentropy" else if (factor_y) "categorical_crossentropy" else "mse"
  }
  if (is.null(compile_args[["optimizer"]])) {
    compile_args$optimizer <- "rmsprop"   # RMSprop recommended by the RLN paper
  }
  do.call(keras3::compile, c(list(object = model), compile_args))

  # RLN callback on the hidden layer (layers[[1]] is InputLayer, [[2]] is Dense)
  rln <- RLNCallback(
    layer         = model$layers[[2]],
    norm          = norm,
    avg_reg       = avg_reg,
    learning_rate = learning_rate
  )

  # Inject RLN alongside any user-supplied callbacks
  fit_args$callbacks <- c(list(rln), fit_args$callbacks)

  # Fit
  do.call(
    keras3::fit,
    c(list(object = model, x = x, y = y_mat, epochs = epochs), fit_args)
  )

  model$y_names <- colnames(y_mat)
  model
}
