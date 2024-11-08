library(mall)
library(tools)
library(fs)
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

for(i in seq_along(rd_content)) {
  rd_i <- rd_content[[i]]
  print(attr(rd_i, "Rd_tag"))
}

new_content <- rd_content[[1]][[1]]
new_content[[1]] <- llm_vec_translate(new_content[[1]], "spanish")
rd_content[[1]][[1]] <- new_content

rd_text <- paste0(as.character(rd_content), collapse = "")
writeLines(rd_text, "content.Rd")
rstudioapi::previewRd("content.Rd")


