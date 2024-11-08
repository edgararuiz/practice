library(ggplot2)
library(tools)
library(fs)
topic <- "aes"
pkg_name <- NULL
help_file <- help(topic, help_type = "text")
help_path <- as.character(help_file)

if(topic == path_file(help_path) && is.null(pkg_name)) {
  help_folder <- path_dir(help_path)
  help_pkg <- path_dir(help_folder)  
  pkg_name <- path_file(help_pkg)
}
db <- Rd_db(pkg_name)
db[[path(topic, ext = "Rd")]]
