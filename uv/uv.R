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

library(processx)

run("uv", "venv")
