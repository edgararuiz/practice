# Write SAS/STAT code as text from R.
#
# Every SAS proc has the same shape:
#
#   proc <name> data=<dataset> <options>;
#     <keyword> <arguments> / <options>;
#   run;
#
# `sas_stmt()` makes one statement line. `sas_proc()` puts the statements
# in a fixed order and adds the proc line and the end line.

# Procs that end with quit instead of run.
sas_quit_procs <- c("reg", "glm", "sql", "anova")

# Order of statements inside a proc. Statements that are not in this list
# go after the main statements, in the order you give them.
sas_stmt_order <- list(
  class   = 1,
  tables  = 2, var = 2, model = 2, time = 2, paired = 2,
  by      = 4, where = 4, weight = 4, freq = 4, id = 4,
  output  = 5
)

# Make an options string.
# Unnamed values are flags. Named values become name=value.
# sas_opts(c("chisq", alpha = 0.05)) returns "chisq alpha=0.05".
sas_opts <- function(x) {
  if (is.null(x) || length(x) == 0) {
    return("")
  }
  nms <- names(x)
  if (is.null(nms)) {
    nms <- rep("", length(x))
  }
  x <- as.character(x)
  paste(ifelse(nms == "", x, paste0(nms, "=", x)), collapse = " ")
}

# Make one statement.
# `...` are the arguments, joined with spaces.
# `options` go after a slash.
sas_stmt <- function(keyword, ..., options = NULL) {
  args <- unlist(list(...))
  structure(
    list(
      keyword = tolower(keyword),
      args = paste(args, collapse = " "),
      options = sas_opts(options)
    ),
    class = "sas_stmt"
  )
}

# ---- Syntax color ----------------------------------------------------------

# Colors for each kind of token. `print()` uses them; `format()` and
# `as.character()` return plain text, so the code is safe to write to a file.
sas_colors <- list(
  proc    = function(x) cli::style_bold(cli::col_blue(x)),
  keyword = cli::col_blue,
  macro   = cli::col_magenta,
  string  = cli::col_green,
  number  = cli::col_yellow,
  slash   = cli::col_grey
)

# Apply a color only when `color` is TRUE.
sas_paint <- function(x, type, color) {
  if (color) sas_colors[[type]](x) else x
}

# Color macro variables, quoted strings, and numbers in free text.
# All three are matched in one pass, so color codes added for one token
# are never matched again by another pattern.
sas_paint_text <- function(x, color) {
  if (!color || !nzchar(x)) {
    return(x)
  }
  pattern <- paste(
    "'[^']*'|\"[^\"]*\"",           # quoted strings
    "&[A-Za-z_][A-Za-z0-9_]*\\.?",  # macro variables
    "\\b[0-9]+(\\.[0-9]+)?\\b",    # numbers
    sep = "|"
  )
  m <- gregexpr(pattern, x, perl = TRUE)
  tokens <- regmatches(x, m)[[1]]
  if (length(tokens) == 0) {
    return(x)
  }
  type <- ifelse(
    grepl("^['\"]", tokens), "string",
    ifelse(startsWith(tokens, "&"), "macro", "number")
  )
  regmatches(x, m) <- list(unname(mapply(sas_paint, tokens, type, color)))
  x
}

format.sas_stmt <- function(x, color = FALSE, ...) {
  out <- sas_paint(x$keyword, "keyword", color)
  if (nzchar(x$args)) {
    out <- paste(out, sas_paint_text(x$args, color))
  }
  if (nzchar(x$options)) {
    out <- paste(
      out,
      sas_paint("/", "slash", color),
      sas_paint_text(x$options, color)
    )
  }
  paste0(out, ";")
}

print.sas_stmt <- function(x, ...) {
  cat(format(x, color = TRUE), "\n", sep = "")
  invisible(x)
}

# Make a full proc.
# `...` are statements made with `sas_stmt()`. NULL statements are dropped,
# so wrappers can pass optional statements without checking them first.
sas_proc <- function(name, ..., data = "&dsn", options = NULL) {
  stmts <- Filter(Negate(is.null), list(...))
  is_stmt <- vapply(stmts, inherits, logical(1), "sas_stmt")
  if (!all(is_stmt)) {
    stop("All statements must be made with `sas_stmt()`.")
  }
  structure(
    list(
      name = tolower(name),
      data = data,
      options = sas_opts(options),
      statements = stmts
    ),
    class = "sas_proc"
  )
}

format.sas_proc <- function(x, indent = "  ", color = FALSE, ...) {
  head <- paste(
    sas_paint("proc", "proc", color),
    sas_paint(x$name, "proc", color)
  )
  if (!is.null(x$data) && nzchar(x$data)) {
    head <- paste0(
      head, " ", sas_paint("data", "keyword", color), "=",
      sas_paint_text(x$data, color)
    )
  }
  if (nzchar(x$options)) {
    head <- paste(head, sas_paint_text(x$options, color))
  }
  head <- paste0(head, ";")

  # Main statements get rank 2. Other unknown statements get rank 3.
  rank <- vapply(
    x$statements,
    function(s) {
      r <- sas_stmt_order[[s$keyword]]
      if (is.null(r)) 3 else r
    },
    numeric(1)
  )
  # order() keeps the given order when ranks are equal.
  body <- vapply(
    x$statements[order(rank)], format, character(1), color = color
  )

  end <- if (x$name %in% sas_quit_procs) "quit" else "run"
  end <- paste0(sas_paint(end, "proc", color), ";")

  paste(c(head, paste0(indent, body), end), collapse = "\n")
}

print.sas_proc <- function(x, ...) {
  cat(format(x, color = TRUE, ...), "\n", sep = "")
  invisible(x)
}

as.character.sas_proc <- function(x, ...) {
  format(x, color = FALSE, ...)
}

# ---- Examples ---------------------------------------------------------------

if (FALSE) {
  sas_proc(
    "freq",
    sas_stmt("tables", "&row*&col", options = c("chisq", "exact")),
    sas_stmt("weight", "&count")
  )

  sas_proc(
    "means",
    sas_stmt("var", "&outcome"),
    sas_stmt("class", "&trt"),
    options = c("n", "mean", "std", "clm", alpha = 0.05)
  )

  sas_proc(
    "mixed",
    sas_stmt("model", "&outcome = &trt &visit &trt*&visit",
             options = c("solution", ddfm = "kr")),
    sas_stmt("repeated", "&visit", options = c(subject = "&subj", type = "un")),
    sas_stmt("lsmeans", "&trt*&visit", options = c("diff", "cl")),
    sas_stmt("class", "&trt &visit &subj"),
    options = c(method = "reml")
  )

  sas_proc(
    "reg",
    sas_stmt("model", "&outcome = &x1 &x2", options = "clb")
  )
}
