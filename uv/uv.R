library(reticulate)

uv <- function(...) {
  system2(
    fs::path_rel("~/.local/bin/uv"),
    paste(c(...), collapse = " "),
    stderr = TRUE,
    stdout = TRUE
    )
}

uv("venv", "--color", "never")
use_virtualenv(here::here(".venv"))

uv_install <- function(..., python = py_exe()) {
  uv(
    "pip install",
     "--python", shQuote(fs::path_rel(python)),
     c("--color", "never", ...)
    )
}

cli::cli_alert_success(uv_install("polars", "jax"))
uv_install("-n", "jax")


#fs::dir_delete(here::here(".venv"))

# ------------------- test ------------------------------

library(processx)

x <- run(fs::path_rel("~/.local/bin/uv"), c("-h"))
cat(x$stdout)


x <- process$new(fs::path_rel("~/.local/bin/uv"), c("venv"),stdout = "|", stderr = "|")
while(x$is_alive()) {
  cat(x$read_error())
  cat(x$read_output())
}

# ------------------------- new -------------------------

library(processx)
library(reticulate)

uv_exe <- function() {
  fs::path_rel("~/.local/bin/uv")
}

uv_process <- function(...) {
  x <- process$new(uv_exe(), c(...),stdout = "|", stderr = "|")
  while(x$is_alive()) {
    cat(x$read_error())
    cat(x$read_output())
  }
  invisible()
}

uv_process("venv")
use_virtualenv(here::here(".venv"))
uv_install <- function(..., python = py_exe()) {
  uv_process(
    "pip", 
    "install",
    "--python", shQuote(fs::path_rel(python)),
    c(...)
  )
}

uv_install("polars", "jax")
