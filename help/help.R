library(mall)
library(ggplot2)
library(tools)
library(fs)
library(pkgsite)

topic <- "llm_classify"
package <- NULL
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
  paste0(rd_txt, collapse = "")
}

tag_text <- NULL
for(i in seq_along(rd_content)) {
  rd_i <- rd_content[[i]]
  tag_name <- attr(rd_i, "Rd_tag")
  if(tag_name %in% c("\\title", "\\description", "\\value", "\\details")) {
    tag_text <- llm_vec_translate(extract_text(rd_i), "spanish")
    attrs <- attributes(rd_i[[1]])
    attr(attrs, "Rd_tag") <- "TEXT"
    attributes(tag_text) <- attrs
    obj <- list(tag_text)
    attributes(obj) <- attributes(rd_i)
    rd_content[[i]] <- obj
  }
}

rd_text <- paste0(as.character(rd_content), collapse = "")
writeLines(rd_text, "content.Rd")
rstudioapi::previewRd("content.Rd")

#llm_vec_translate(paste0(rd_content[[5]], collapse = ""), "spanish")
# new_content <- rd_content[[1]][[1]]
# new_content[[1]] <- llm_vec_translate(new_content[[1]], "spanish")
# rd_content[[1]][[1]] <- new_content
