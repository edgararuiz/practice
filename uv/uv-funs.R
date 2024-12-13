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


uv_install <- function(..., python = py_exe()) {
  uv_process(
    "pip", 
    "install",
    "--python", fs::path_rel(python),
    c(...)
  )
}
