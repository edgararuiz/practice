# RLN Callback — pure torch (R6), no luz
# Based on: https://arxiv.org/abs/1805.06440

library(R6)
library(torch)

#' RLN Callback (torch)
#'
#' Drop-in RLN update for a manual torch training loop. Call the hook methods
#' explicitly at the appropriate points in your loop.
#'
#' Key difference from the Keras version: nn_linear stores weight as
#' [out_features, in_features] — already transposed — so no transpose is
#' needed when reading or writing.
#'
#' @param model        The nn_module whose layer will be regularized.
#' @param layer_index  Which nn_linear to target (1 = first). Default 1.
#' @param norm         1 for L1, 2 for L2.
#' @param avg_reg      Target mean of log-scale lambdas (Theta). Default -7.5.
#' @param learning_rate  Step size for lambda updates (nu). Default 6e5.
#' @param checkpoint_dir  Optional directory for saving lambda state per epoch.
RLNCallback <- R6Class(
  classname = "RLNCallback",

  private = list(
    layer               = NULL,
    weights             = NULL,
    prev_weights        = NULL,
    lambdas             = NULL,
    prev_regularization = NULL,
    norm                = NULL,
    avg_reg             = NULL,
    lr                  = NULL,
    checkpoint_dir      = NULL,

    read_weights = function() {
      # weight shape: [out_features, in_features] — already outputs x inputs
      private$weights <- as.array(private$layer$weight$detach())
    }
  ),

  public = list(
    initialize = function(
      model,
      layer_index    = 1L,
      norm           = 1L,
      avg_reg        = -7.5,
      learning_rate  = 6e5,
      checkpoint_dir = NULL
    ) {
      stopifnot("Only L1 and L2 norms are supported" = norm %in% c(1, 2))
      private$norm           <- as.integer(norm)
      private$avg_reg        <- avg_reg
      private$lr             <- learning_rate
      private$checkpoint_dir <- checkpoint_dir

      # Find the layer_index-th nn_linear at construction time
      layer_count <- 0L
      for (child in model$children) {
        if (inherits(child, "nn_linear")) {
          layer_count <- layer_count + 1L
          if (layer_count == as.integer(layer_index)) {
            private$layer <- child
            break
          }
        }
      }
      if (is.null(private$layer)) {
        stop(sprintf("No nn_linear layer #%d found in model", layer_index))
      }
    },

    on_train_begin = function() {
      private$read_weights()

      # Restore lambda state from checkpoint, or initialise fresh
      restored <- FALSE
      if (!is.null(private$checkpoint_dir)) {
        state_files <- list.files(
          private$checkpoint_dir,
          pattern    = "^rln_state_epoch_\\d{3}\\.rds$",
          full.names = TRUE
        )
        if (length(state_files) > 0) {
          epochs  <- as.integer(regmatches(
            basename(state_files),
            regexpr("\\d{3}", basename(state_files))
          ))
          latest  <- state_files[which.max(epochs)]
          state   <- readRDS(latest)
          private$lambdas             <- state$lambdas
          private$prev_regularization <- state$prev_regularization
          message(sprintf("RLN: restored lambda state from %s", basename(latest)))
          restored <- TRUE
        }
      }

      if (!restored) {
        private$lambdas <- matrix(
          private$avg_reg,
          nrow = nrow(private$weights),
          ncol = ncol(private$weights)
        )
      }
    },

    on_batch_end = function() {
      private$prev_weights <- private$weights
      private$read_weights()
      gradients <- private$weights - private$prev_weights

      norms_derivative <- if (private$norm == 1L) {
        sign(private$weights)
      } else {
        private$weights * 2
      }

      if (!is.null(private$prev_regularization)) {
        # Lambda gradient step
        lambda_gradients <- gradients * private$prev_regularization
        private$lambdas  <- private$lambdas - private$lr * lambda_gradients

        # Project: keep mean(lambdas) == avg_reg
        private$lambdas  <- private$lambdas + (private$avg_reg - mean(private$lambdas))
      }

      # Clip lambdas to prevent weight sign flip
      max_lambdas <- log(abs(private$weights / norms_derivative))
      max_lambdas[!is.finite(max_lambdas)] <- Inf
      private$lambdas <- pmin(private$lambdas, max_lambdas)

      # Apply regularization in-place (no grad tracking)
      regularization <- norms_derivative * exp(private$lambdas)
      regularization[!is.finite(regularization)] <- 0
      new_weights <- private$weights - regularization

      with_no_grad({
        private$layer$weight$copy_(
          torch_tensor(new_weights, dtype = torch_float())
        )
      })

      private$prev_regularization <- regularization
    },

    on_epoch_end = function(epoch) {
      if (!is.null(private$checkpoint_dir)) {
        dir.create(private$checkpoint_dir, showWarnings = FALSE, recursive = TRUE)
        saveRDS(
          list(
            lambdas             = private$lambdas,
            prev_regularization = private$prev_regularization
          ),
          file.path(
            private$checkpoint_dir,
            sprintf("rln_state_epoch_%03d.rds", epoch)
          )
        )
      }
    }
  )
)
