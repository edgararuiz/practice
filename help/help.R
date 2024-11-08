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

rd_content2 <- rd_content[[8]]
attributes(rd_content2) <- NULL
class(rd_content2) <- "Rd"
rd_text <- paste0(as.character(rd_content2), collapse = "")
writeLines(rd_text, "content.Rd")
original <- paste0(capture.output(Rd2txt("content.Rd", fragment = TRUE)), collapse = "")
llm_vec_translate(original, "spanish")

