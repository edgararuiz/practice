library(mall)
library(tools)
library(fs)
library(cli)
library(rlang)

helpr <- function(topic, package = NULL, lang = Sys.getenv("LANG"), type = getOption("help_type")) {
  help_file <- help(topic, help_type = "text")
  help_path <- as.character(help_file)
  if (topic == path_file(help_path) && is.null(package)) {
    help_folder <- path_dir(help_path)
    help_pkg <- path_dir(help_folder)
    package <- path_file(help_pkg)
  }
  db <- Rd_db(package)
  rd_content <- db[[path(topic, ext = "Rd")]]
  tag_text <- NULL
  tag_name <- NULL
  cli_progress_message("Translating: {.emph {substr(tag_name, 2, nchar(tag_name))}}")
  for (i in seq_along(rd_content)) {
    rd_i <- rd_content[[i]]
    tag_name <- attr(rd_i, "Rd_tag")
    standard_tags <- c("\\title", "\\description", "\\value", "\\details", "\\seealso")
    cli_progress_update()
    if (tag_name %in% standard_tags) {
      rd_content[[i]] <- prep_translate(rd_i, lang)
    }
    if (tag_name == "\\section") {
      rd_content[[i]][[1]] <- prep_translate(rd_i[[1]], lang)
      rd_content[[i]][[2]] <- prep_translate(rd_i[[2]], lang)
    }
    if (tag_name == "\\arguments") {
      for (k in seq_along(rd_i)) {
        rd_k <- rd_i[[k]]
        if (length(rd_k) > 1) {
          rd_i[[k]][[2]] <- prep_translate(rd_k[[2]], lang)
        }
      }
      rd_content[[i]] <- rd_i
    }
    if (tag_name == "\\name") {
      topic_name <- rd_i
    }
  }
  tag_name <- NULL
  cli_progress_update()
  rd_text <- paste0(as.character(rd_content), collapse = "")
  topic_path <- fs::path(tempdir(), topic_name, ext = "Rd")
  writeLines(rd_text, topic_path)
  structure(
    list(
      topic = topic,
      pkg = package,
      path = topic_path,
      stage = "render",
      type = type
    ),
    class = "lang_topic"
  )  
}

code_markers <- function(x) {
  split_out <- strsplit(x, "'")[[1]]
  split_out
  new_txt <- NULL
  start_code <- TRUE
  for (i in seq_along(split_out)) {
    if (start_code) {
      if (i == length(split_out)) {
        code_txt <- NULL
      } else {
        code_txt <- "\\code{"
      }
      start_code <- FALSE
    } else {
      code_txt <- "}"
      start_code <- TRUE
    }
    new_txt <- c(new_txt, split_out[[i]], code_txt)
  }
  paste0(new_txt, collapse = "")
}

extract_text <- function(x) {
  attributes(x) <- NULL
  class(x) <- "Rd"
  rd_text <- paste0(as.character(x), collapse = "")
  temp_rd <- tempfile(fileext = ".Rd")
  writeLines(rd_text, temp_rd)
  rd_txt <- capture.output(Rd2txt(temp_rd, fragment = TRUE))
  rd_txt[rd_txt == ""] <- "\n\n"
  out <- paste0(rd_txt, collapse = "")
  out
}

prep_translate <- function(x, lang) {
  tag_text <- llm_vec_translate(extract_text(x), lang, additional_prompt = "Do not translate function names.")
  tag_text <- code_markers(tag_text)
  attrs <- attributes(x[[1]])
  attr(attrs, "Rd_tag") <- "TEXT"
  attributes(tag_text) <- attrs
  obj <- list(tag_text)
  attributes(obj) <- attributes(x)
  obj
}


print.lang_topic <- function(x, ...) {
  type <- arg_match0(x$type %||% "text", c("text", "html"))
  if (type == "html" && rstudioapi_available()) {
    return(rstudioapi::callFun("previewRd", x$path))
  }
  
  # otherwise render and serve
  file <- fs::path_ext_set(fs::path_file(x$path), type)
  
  # This directory structure is necessary for RStudio to open the
  # .html file in the help pane (see rstudio/rstudio#11336)
  doc_path <- fs::path("doc", "html", file)
  path <- fs::path(tempdir(), ".R", doc_path)
  fs::dir_create(fs::path_dir(path), recurse = TRUE)
  
  if (type == "text") {
    topic_write_text(x, path)
    title <- paste(x$pkg, basename(x$path), sep = ":")
    file.show(path, title = title)
  } else if (type == "html") {
    topic_write_html(x, path)
    
    if (is_rstudio()) {
      # This localhost URL is also part of getting RStudio to open in
      # the help pane
      port <- httpdPort()
      url <- sprintf("http://localhost:%i/%s", port, doc_path)
    } else {
      url <- path
    }
    
    utils::browseURL(url)
  }
}

on_load(
  httpdPort %<~% env_get(rlang::ns_env("tools"), "httpdPort")
)

rstudioapi_available <- function() {
  is_installed("rstudioapi") && rstudioapi::isAvailable()
}