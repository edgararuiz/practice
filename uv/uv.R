library(reticulate)

uv <- function(...) {
  reticulate:::system2t(
    fs::path_rel("~/.local/bin/uv"),
    paste(c(...), collapse = " ")
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

uv_install("polars", "jax")
uv_install("jax")


#fs::dir_delete(here::here(".venv"))
