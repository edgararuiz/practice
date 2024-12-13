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

cat("\033[2mAudited \033[1m2 packages\033[0m \033[2min 1ms\033[0m\033[0m\n")
cat("Audited \033[1m2 packages\033[0m in 1ms\033[0m\033[0m\n")

cat("\033[1mAudited \033[1m2 packages\033[0m \033[1min 1ms\033[0m\033[0m\n")


x <- "\033[2mAudited \033[1m2 packages\033[0m \033[2min 1ms\033[0m\033[0m\n"
cat(x)
out <- "\033[2mAudited \033[1m2 packages\033[0m \033[2min 1ms\033[0m\033[0m\n"
cat(out)
out_split <- unlist(strsplit(out, "\\[2m"))
out <- paste0(out_split, collapse = "[1m")
cat(out)
grepl("[\\[]", out)

cli::ansi_strip(out)


# ------------------------- new -------------------------

library(processx)
library(reticulate)

uv_exe <- function() {
  fs::path_rel("~/.local/bin/uv")
}

remove_blur <- function(x) {
  x_split <- unlist(strsplit(x, "\033\\[2m"))
  paste0(x_split, collapse = "")
}

uv_process <- function(...) {
  x <- process$new(
    uv_exe(), 
    c(...),
    stdout = "|",
    stderr = "|"
    )
  while(x$is_alive()) {
    read_error <- remove_blur(x$read_error())
    read_output <- remove_blur(x$read_output())
    if(read_error != "") {
      cat(read_error)  
    }
    if(read_output != "") {
      cat(read_output) 
    }
  }
  invisible()
}

use_virtualenv(here::here(".venv"))
uv_install <- function(..., python = py_exe()) {
  uv_process(
    "pip", 
    "install",
    "--python", fs::path_rel(python),
    c(...)
  )
}

uv_process("venv")


uv_install("polars", "jax")


uv_install("jax2")

uv_install("numpy")


uv_process("venv", "--allow-existing", "--python", "3.10")

uv_install("polars", "jax")
uv_install("notreal")

source("uv/uv-funs.R")
uv_envs <- fs::path_expand(path(rappdirs::user_data_dir(), "uv-envs"))
uv_path <- path(uv_envs, paste0("r-", hash(fs::path_expand(here::here()))))
uv_process(uv_path, "--allow-existing", "--python", "3.10")

use_virtualenv(uv_path)

uv_install("polars")

