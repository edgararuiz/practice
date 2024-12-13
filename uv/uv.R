uv <- function(...) {
  reticulate:::system2t(fs::path_real("~/.local/bin/uv"), paste(c(...), collapse = " "))
}

uv("venv")
reticulate:::py_activate_virtualenv(fs::path_real(".venv/bin/"))


uv_install <- function(..., python = py_exe()) {
  uv("pip install",
     "--python", shQuote(python),
     c(...))
}

uv_venv_create <- function(envname = NULL, python_version = "3.11",
                           packages = "numpy", ..., force = FALSE) {
  path <- path.expand(reticulate:::virtualenv_path(envname))
  if (force)
    unlink(path, recursive = TRUE, force = TRUE)
  dir.create(path, showWarnings = FALSE, recursive = TRUE)
  
  uv(
    "venv",
    "--no-project",
    "--seed",
    "--no-config",
    "--python-preference only-managed",
    "--python", python_version,
    ...,
    shQuote(path)
  )
  
  if (length(packages))
    uv_install(packages, python = reticulate:::virtualenv_python(path))
  
  invisible(path)
}

