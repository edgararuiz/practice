library(processx)
library(reticulate)
library(fs)

uv_exe <- function() {
  fs::path_rel("~/.local/bin/uv")
}

clean_output <- function(x) {
  # ANSI cleanup, remove blurriness
  x_split <- unlist(strsplit(x, "\033\\[2m"))
  x <- paste0(x_split, collapse = "")
  if(grepl(path_expand(rappdirs::user_data_dir()), x)) {
    
  }
  x <- sub(path_expand(rappdirs::user_data_dir()), "[USER DATA DIR]", x)
  x
}

uv_process <- function(...) {
  x <- process$new(
    uv_exe(), 
    c(...),
    stdout = "|",
    stderr = "|"
  )
  while(x$is_alive()) {
    read_error <- clean_output(x$read_error())
    read_output <- clean_output(x$read_output())
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
