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
rd_text <- paste0(as.character(rd_content), collapse = "")
writeLines(rd_text, "content.Rd")
rstudioapi::previewRd("content.Rd")

