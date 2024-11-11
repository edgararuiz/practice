library(mall)
library(ggplot2)
library(tools)
library(fs)
library(pkgsite)

llm_use("ollama", "llama3.2", seed = 100, .cache = "_temp_folder")

topic <- "mutate"
package <- "dplyr"
help_file <- help(topic, help_type = "text")
help_path <- as.character(help_file)

if(topic == path_file(help_path) && is.null(package)) {
  help_folder <- path_dir(help_path)
  help_pkg <- path_dir(help_folder)  
  package <- path_file(help_pkg)
}
db <- Rd_db(package)
rd_content <- db[[path(topic, ext = "Rd")]]

extract_text <- function(x) {
  attributes(x) <- NULL
  class(x) <- "Rd"
  rd_text <- paste0(as.character(x), collapse = "")
  temp_rd <- tempfile(fileext = ".Rd")
  writeLines(rd_text, temp_rd)
  rd_txt <- capture.output(Rd2txt(temp_rd, fragment = TRUE))
  rd_txt[rd_txt == ""] <- "\n\n"
  paste0(rd_txt, collapse = "")
}

prep_translate <- function(x) {
  tag_text <- llm_vec_translate(extract_text(x), "french")
  attrs <- attributes(x[[1]])
  attr(attrs, "Rd_tag") <- "TEXT"
  attributes(tag_text) <- attrs
  obj <- list(tag_text)
  attributes(obj) <- attributes(x)
  obj
}

tag_text <- NULL
for(i in seq_along(rd_content)) {
  rd_i <- rd_content[[i]]
  tag_name <- attr(rd_i, "Rd_tag")
  print(tag_name)
  if(tag_name %in% c("\\title", "\\description", "\\value", "\\details")) {
    rd_content[[i]] <- prep_translate(rd_i)
  }
  if(tag_name == "\\section") {
    rd_content[[i]][[1]] <- prep_translate(rd_i[[1]])
    rd_content[[i]][[2]] <- prep_translate(rd_i[[2]])
  }
  if(tag_name == "\\arguments") {
    for(k in seq_along(rd_i)) {
      rd_k <- rd_i[[k]]
      if(length(rd_k) > 1) {
        rd_i[[k]][[2]] <- prep_translate(rd_k[[2]])
      }
    }    
    rd_content[[i]] <- rd_i
  }
}

rd_text <- paste0(as.character(rd_content), collapse = "")
writeLines(rd_text, "content.Rd")
rstudioapi::previewRd("content.Rd")
