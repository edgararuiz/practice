#' Probability calibration using isotonic regression
#' @param probs A vector of estimated classification probabilities.
#' @param truth A factor vector with two levels corresponding to the known
#' outcome values.
#' @param ... Not currently used.
#' @examples
#'
#' # Simulate data using function from modeldata package
#' set.seed(5660)
#' tr <- sim_classification(1000)
#' te <- sim_classification(1000)
#' rs <- vfold_cv(tr)
#'
#' # Define a random forest model
#' rf_spec <- rand_forest() %>% set_mode("classification")
#'
#' # Resample the model to get realistic estimates
#' set.seed(8401)
#' rf_rs <- rf_spec %>% fit_resamples(class ~ ., rs, control = control_resamples(save_pred = TRUE))
#'
#' # Save held out predictions
#' rf_tr_holdout <- collect_predictions(rf_rs)
#'
#' rf_iso <- cal_isotonic(rf_tr_holdout$.pred_class_1, rf_tr_holdout$class)
#' rf_iso
#'
#' # Demonstrate the new calibration using and fitted model
#' set.seed(9451)
#' rf_fit <- rf_spec %>% fit(class ~ ., data = tr)
#' rf_te_pred <- augment(rf_fit, te) %>% select(class, .pred_class_1, .pred_class_2)
#'
#' # Apply the calibration to the new data
#' rf_te_calibrated <- predict(rf_iso, rf_te_pred$.pred_class_1)
#'
#' @export

# TODO this might need to be an S3 generic with methods for tune_results objects,
# workflow sets, and general data frames (like the caret interface)
cal_isotonic <- function(probs, truth, ...) {
  # TODO catch options other than times and fail
  lvls <- levels(truth)
  # TODO allow x to be data frame with correct column names.
  na_val <- is.na(probs) | is.na(truth)
  probs <- probs[!na_val]
  truth <- truth[!na_val]
  dat <- prepare_data_isoreg(probs, truth, ...)
  # TODO check for null
  mod <- isoreg(dat$x, dat$y)
  steps <- as.stepfun(mod)
  new_x <- environment(steps)$x
  new_y <- environ
  ment(steps)$y
  res <- list(x = new_x, y = new_y, levels = table(truth), n = sum(!na_val))
  class(res) <- c("cal_isotonic", "cal_binary")
  res
}

#' @export
print.cal_isotonic <- function (x, ...)  {
  cat("isotonic probability calibration\n")
  cls <- paste0(names(x$levels), collapse = ", ")
  cat("training data: n = ", x$n, "\nclasses: ", cls, "\n", sep = "")
  invisible(x)
}

prepare_data_isoreg <- function(prob, truth,  sampled = FALSE) {
  # TODO check for complete separation, warn, and return null.
  n <- length(truth)
  ord <- order(prob)
  y <- ifelse(truth == levels(truth)[1], 1, 0)
  prob <- prob[ord]
  y <- y[ord]
  if (sampled) {
    ind <- sort(sample(1:n, n, replace = TRUE))
    prob <- prob[ind]
    y <- y[ind]
  }
  list(x = prob, y = y)
}


#' @export
predict.cal_isotonic <- function(object, new_data, ...) {
  # TODO check for null
  # TODO handle missing values
  ref_ind <- findInterval(new_data, object$x)
  res <- tibble::tibble(one = object$y[ref_ind])
  res$two <- 1 - res$one
  names(res) <- paste0(".pred_", names(object$levels))
  res
}

# ------------------------------------------------------------------------------

#' @rdname cal_isotonic
#' @param times The number of bootstrapped samples
#' @examples
cal_isotonic_boot <- function(probs, truth, times = 5, ...) {
  seeds <- sample.int(10000, times)
  mods <- purrr::map(seeds, ~ boot_iso(.x, x = probs, y = truth))
  res <- list(models = mods)
  class(res) <- c("cal_isotonic_boot", "cal_binary")
  res

}

boot_iso <- function(seed, x, y) {
  withr::with_seed(seed, cal_isotonic(x, y, sampled = TRUE))
}

#' @export
print.cal_isotonic_boot <- function (x, ...)  {
  cat("bootstrapped isotonic probability calibration\n")
  cls <- paste0(names(x$models[[1]]$levels), collapse = ", ")
  cat("training data: n = ", x$models[[1]]$n, "\nclasses: ", cls, "\n", sep = "")
  cat("bootstraps:", length(x$models), "\n")
  invisible(x)
}

#' @export
predict.cal_isotonic_boot <- function(object, new_data, ...) {
  cls_nm <- paste0(".pred_", names(object$models[[1]]$levels))
  purrr::map_dfr(object$models, ~ predict(.x, new_data) %>% add_rowindex()) %>%
    setNames(c("prob", "prob2", ".row")) %>%
    group_by(.row) %>%
    summarize(prob = mean(prob, na.rm = TRUE), .groups = "drop") %>%
    mutate(prob2 = 1 - prob) %>%
    arrange(.row) %>%
    select(-.row) %>%
    setNames(cls_nm)
}


# Open questions
# How to handle multiclass?
# How/where to have users interface with this? After the optimizations? How would
#   they tune them then?
# How to plot multiple models on the same calibration plot?
