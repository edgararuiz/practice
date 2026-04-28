# Self-contained RLN training function — pure torch, manual training loop

library(torch)
source(file.path(dirname(sys.frame(1)$ofile), "rln_callback_torch.R"))

#' Fit a single-hidden-layer MLP with Regularization Learning (torch)
#'
#' @param x               Numeric predictor matrix.
#' @param y               Outcome: numeric vector (regression) or factor (classification).
#' @param hidden_units    Units in the hidden layer.
#' @param norm            1 = L1, 2 = L2 regularization norm.
#' @param avg_reg         Target mean of log-scale lambda coefficients (Theta).
#' @param learning_rate   Step size for lambda updates (nu).
#' @param epochs          Number of training epochs.
#' @param batch_size      Mini-batch size.
#' @param optimizer_lr    Learning rate for the RMSprop optimizer.
#' @param activation      Hidden layer activation: "relu", "tanh", or "sigmoid".
#' @param seed            Optional integer seed for reproducibility.
#' @param validation_split  Fraction of training data to use for validation (0 = none).
#' @param checkpoint_dir  Optional directory for checkpointing model weights and
#'                        lambda state. Model saved as model_epoch_NNN.pt,
#'                        lambda state as rln_state_epoch_NNN.rds.
#' @param verbose         Print per-epoch loss. Default TRUE.
#'
#' @return A list with: model, history, y_levels, binary_y, factor_y.
rln_mlp_torch <- function(
  x,
  y,
  hidden_units     = 5L,
  norm             = 1L,
  avg_reg          = -7.5,
  learning_rate    = 6e5,
  epochs           = 20L,
  batch_size       = 32L,
  optimizer_lr     = 1e-3,
  activation       = "relu",
  seed             = NULL,
  validation_split = 0,
  checkpoint_dir   = NULL,
  verbose          = TRUE
) {
  if (!is.null(seed)) torch_manual_seed(seed)

  if (!is.matrix(x)) x <- as.matrix(x)
  if (is.character(y)) y <- as.factor(y)

  factor_y <- is.factor(y)
  binary_y <- factor_y && nlevels(y) == 2L

  # ── Prepare target ───────────────────────────────────────────────────────────

  if (factor_y) {
    if (binary_y) {
      y_num     <- as.numeric(y) - 1          # 0 / 1 float
      out_units <- 1L
      loss_fn   <- nn_bce_with_logits_loss()
    } else {
      y_num     <- as.integer(y) - 1L          # 0-indexed long for cross-entropy
      out_units <- nlevels(y)
      loss_fn   <- nn_cross_entropy_loss()
    }
  } else {
    y_num     <- as.numeric(y)
    out_units <- 1L
    loss_fn   <- nn_mse_loss()
  }

  # ── Train / validation split ─────────────────────────────────────────────────

  n <- nrow(x)
  if (validation_split > 0) {
    n_val     <- floor(n * validation_split)
    n_train   <- n - n_val
    # Take the last n_val rows as validation — matches Keras default behaviour
    train_idx <- seq_len(n_train)
    val_idx   <- seq(n_train + 1L, n)
    x_val     <- x[val_idx, , drop = FALSE]
    y_val     <- y_num[val_idx]
    x         <- x[train_idx, , drop = FALSE]
    y_num     <- y_num[train_idx]
  } else {
    x_val <- y_val <- NULL
  }

  # ── Dataloaders ───────────────────────────────────────────────────────────────

  make_dl <- function(xm, yv, shuffle = FALSE) {
    x_t <- torch_tensor(xm, dtype = torch_float())
    y_t <- if (factor_y && !binary_y) {
      torch_tensor(yv, dtype = torch_long())      # [n] for cross-entropy
    } else {
      torch_tensor(matrix(yv, ncol = 1L), dtype = torch_float())  # [n, 1]
    }
    dataloader(tensor_dataset(x_t, y_t), batch_size = batch_size, shuffle = shuffle)
  }

  train_dl <- make_dl(x, y_num, shuffle = TRUE)
  val_dl   <- if (!is.null(x_val)) make_dl(x_val, y_val) else NULL

  # ── Model ────────────────────────────────────────────────────────────────────

  act_layer <- switch(
    activation,
    relu    = nn_relu(),
    tanh    = nn_tanh(),
    sigmoid = nn_sigmoid(),
    nn_relu()
  )

  model <- nn_sequential(
    nn_linear(ncol(x), hidden_units),
    act_layer,
    nn_linear(hidden_units, out_units)
  )

  # Match Keras glorot_normal (Xavier normal) weight initialisation
  for (m in model$modules) {
    if (inherits(m, "nn_linear")) {
      nn_init_xavier_normal_(m$weight)
      nn_init_zeros_(m$bias)
    }
  }

  # Match Keras RMSprop defaults: rho = 0.9, epsilon = 1e-7
  optimizer <- optim_rmsprop(model$parameters, lr = optimizer_lr, alpha = 0.9, eps = 1e-7)

  # ── RLN callback ─────────────────────────────────────────────────────────────

  rln <- RLNCallback$new(
    model          = model,
    layer_index    = 1L,
    norm           = norm,
    avg_reg        = avg_reg,
    learning_rate  = learning_rate,
    checkpoint_dir = checkpoint_dir
  )

  if (!is.null(checkpoint_dir)) {
    dir.create(checkpoint_dir, showWarnings = FALSE, recursive = TRUE)
  }

  # ── Training loop ─────────────────────────────────────────────────────────────

  history <- list(
    train_loss = numeric(epochs),
    val_loss   = if (!is.null(val_dl)) numeric(epochs) else NULL
  )

  rln$on_train_begin()

  for (epoch in seq_len(epochs)) {
    model$train()
    batch_losses <- c()

    coro::loop(for (batch in train_dl) {
      optimizer$zero_grad()
      pred <- model(batch[[1]])
      loss <- loss_fn(pred, batch[[2]])
      loss$backward()
      optimizer$step()
      rln$on_batch_end()
      batch_losses <- c(batch_losses, loss$item())
    })

    history$train_loss[epoch] <- mean(batch_losses)

    # Validation
    if (!is.null(val_dl)) {
      model$eval()
      val_losses <- c()
      with_no_grad({
        coro::loop(for (batch in val_dl) {
          pred <- model(batch[[1]])
          val_losses <- c(val_losses, loss_fn(pred, batch[[2]])$item())
        })
      })
      history$val_loss[epoch] <- mean(val_losses)
    }

    rln$on_epoch_end(epoch)

    # Save model weights checkpoint
    if (!is.null(checkpoint_dir)) {
      torch_save(model, file.path(checkpoint_dir, sprintf("model_epoch_%03d.pt", epoch)))
    }

    if (verbose) {
      msg <- sprintf("Epoch %d/%d — loss: %.4f", epoch, epochs, history$train_loss[epoch])
      if (!is.null(val_dl)) {
        msg <- paste0(msg, sprintf(" — val_loss: %.4f", history$val_loss[epoch]))
      }
      cat(msg, "\n")
    }
  }

  list(
    model    = model,
    history  = history,
    y_levels = if (factor_y) levels(y) else NULL,
    binary_y = binary_y,
    factor_y = factor_y
  )
}
