


rd_extract_text <- function(x, collapse = TRUE) {
  attributes(x) <- NULL
  class(x) <- "Rd"
  rd_text <- as.character(x)
  if (collapse) {
    rd_text <- paste0(as.character(x), collapse = "")
  }
  temp_rd <- tempfile(fileext = ".Rd")
  writeLines(rd_text, temp_rd)
  rd_txt <- capture.output(tools::Rd2txt(temp_rd, fragment = TRUE))
  if (collapse) {
    rd_txt[rd_txt == ""] <- "\n\n"
    rd_txt <- paste0(rd_txt, collapse = "")
  }
  rd_txt
}

out <- list()
rd_content <- tools::parse_Rd("man/rd_to_qmd.Rd")
tag_text <- NULL
tag_name <- NULL
tag_label <- NULL
cli_progress_message("Translating: {.emph {tag_label}}")
for (i in seq_along(rd_content)) {
  rd_i <- rd_content[[i]]
  tag_name <- attr(rd_i, "Rd_tag")
  standard_tags <- c(
    "\\title", "\\description",
    "\\value", "\\details",
    "\\seealso", "\\section"
  )
  if (tag_name == "\\section") {
    tag_label <- paste0("Section: '", as.character(rd_i[[1]]), "'")
  }
  if (is.null(tag_label)) {
    tag_label <- tag_label #tag_to_label(tag_name)
  }
  #tag_label <-  to_title(tag_label)
  cli_progress_update()
  if (tag_name %in% standard_tags) {
    out[tag_name] <- rd_extract_text(rd_i)
  }
  if (tag_name == "\\section") {
    out[tag_name] <- list(rd_extract_text(rd_i[[1]]), rd_extract_text(rd_i[[2]]))
  }
  if (tag_name == "\\arguments") {
    args_list <- NULL
    args <- rd_i
    for (k in seq_along(rd_i)) {
      rd_k <- rd_i[[k]]
      if (length(rd_k) > 1) {
        curr_arg <- list(argument = as.character(rd_k[[1]]), description =  rd_extract_text(rd_k[[2]]))
        args_list <- c(args_list, curr_arg)
      }
    }
    out["arguments"] <- as.list(args_list)
  }
  if (tag_name == "\\name") {
    topic_name <- rd_i
  }
  if (tag_name == "\\examples") {
    for (k in seq_along(rd_i)) {
      rd_k <- rd_i[[k]]
      rd_char <- as.character(rd_k)
      if (length(rd_char) == 1) {
        if (substr(rd_char, 1, 2) == "# ") {
          last_char <- substr(rd_char, nchar(rd_char), nchar(rd_char))
          n_char <- ifelse(last_char == "\n", 1, 0)
          rd_char <- substr(rd_char, 3, nchar(rd_char) - n_char)
          rd_char <- llm_vec_translate(rd_char, lang)
          rd_char <- paste0("# ", rd_char, "\n")
          attributes(rd_char) <- attributes(rd_k)
          rd_i[[k]] <- rd_char
        }
      }
    }
    rd_content[[i]] <- rd_i
  }
}
tag_name <- NULL
cli_progress_update()
rd_text <- paste0(as.character(rd_content), collapse = "")
#rd_text
out
#topic_path <- fs::path(tempdir(), topic_name, ext = "Rd")
#writeLines(rd_text, topic_path)
#topic_path




#rd_to_list("rd_to_qmd.Rd")
