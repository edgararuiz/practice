library(reticulate)

uv <- function(...) {
  reticulate:::system2t(fs::path_rel("~/.local/bin/uv"), paste(c(...), collapse = " "))
}

uv("venv")
use_virtualenv(here::here(".venv"))

uv_install <- function(..., python = py_exe()) {
  uv("pip install",
     "--python", shQuote(fs::path_rel(python)),
     c(...))
}

uv_install("polars")

uv_install("--no-progress", "pandas")

uv_install("--color", "never", "jax")

uv_install("--color", "never", "polars")


#fs::dir_delete(here::here(".venv"))
