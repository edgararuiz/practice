library(mall)
library(ggplot2)
library(tools)
library(fs)
library(pkgsite)

topic <- "aes"
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

for(i in seq_along(rd_content)) {
  rd_i <- rd_content[[i]]
  print(attr(rd_i, "Rd_tag"))
}

#llm_vec_translate(paste0(rd_content[[5]], collapse = ""), "spanish")

new_content <- rd_content[[1]][[1]]
new_content[[1]] <- llm_vec_translate(new_content[[1]], "spanish")
rd_content[[1]][[1]] <- new_content

extract_text <- function(x) {
  attributes(x) <- NULL
  class(x) <- "Rd"
  rd_text <- paste0(as.character(x), collapse = "")
  temp_rd <- tempfile(fileext = ".Rd")
  writeLines(rd_text, temp_rd)
  rd_txt <- capture.output(Rd2txt(temp_rd, fragment = TRUE))
  paste0(rd_txt, collapse = "")
}
extract_text(rd_content[[8]])

