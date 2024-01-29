remotes::install_github("mlverse/pysparklyr", ref = "updates")

library(reticulate)
library(sparklyr)
pysparklyr::spark_connect_service_start()
sc <- spark_connect("sc://localhost", method = "spark_connect", version = "3.5")
spark <- sc$session
np <- import("numpy")
pd <- import("pandas")
pyspark <- import("pyspark")
pdf <- pd$DataFrame(np$random$rand(100L, 3L))
head(pdf["2"])
df <- spark$createDataFrame(pdf)
new_func <- py_func(function(x) x + 1)
sel_col <- pyspark$sql$functions$col("2")
udf <- df$select(new_func(sel_col))$toPandas()
head(udf[[1]])
spark_disconnect(sc)
pysparklyr::spark_connect_service_stop()


sc <- spark_connect(
  method = "databricks_connect",
  cluster_id = "1026-175310-7cpsh3g8"
)
tbl_trips <- tbl(sc, in_catalog("samples", "nyctaxi", "trips"))
r_func <- py_func(function(x) x + 100)
pd_trips <- tbl_trips[[1]]$session
pyspark <- import("pyspark")
sel_col <- pyspark$sql$functions$col("trip_distance")
run_udf <- pd_trips$select(r_func(sel_col))
pd_udf <- run_udf$toPandas()
head(pd_udf)
spark_disconnect(sc)



library(fs)
library(reticulate)
library(sparklyr)
Sys.setenv("PYTHON_VERSION_MISMATCH" = "/Users/edgar/.virtualenvs/r-sparklyr-pyspark-3.5/bin/python")
Sys.setenv("PYSPARK_DRIVER_PYTHON" = "/Users/edgar/.virtualenvs/r-sparklyr-pyspark-3.5/bin/python")
pysparklyr::spark_connect_service_start()
sc <- spark_connect("sc://localhost", method = "spark_connect", version = "3.5")
# sc <- spark_connect(method = "databricks_connect", cluster_id = "1026-175310-7cpsh3g8")
tbl_mtcars <- copy_to(sc, mtcars)
pd_mtcars <- tbl_mtcars[[1]]$session

pd_grouped <- pd_mtcars$groupby("am")

sa_function_to_string <- function(.f, ...) {
  path_scripts <- here::here("udfs")
  fn_r <- paste0(
    readLines(path(path_scripts, "udf-function.R")),
    collapse = ""
    )
  fn_python <- paste0(
    readLines(path(path_scripts, "udf-function.py")), 
    collapse = "\n"
  )
  fn <- purrr::as_mapper(.f = .f, ... = ...)
  fn_str <- paste0(deparse(fn), collapse = "")
  if(inherits(fn, "rlang_lambda_function")) {
    fn_str <- paste0(
      "function(...) {x <- (",
      fn_str,
      "); x(...)}"
    )
  }
  fn_str <- gsub("\"", "'", fn_str)
  fn_rep <- "function\\(\\.\\.\\.\\) 1"
  fn_r_new <- gsub(fn_rep, fn_str, fn_r)
  gsub(fn_rep, fn_r_new, fn_python)
}

sa_pandas_grouped <- function(x, .f, ..., .schema = "x double", group_by = NULL) {
  fn <- sa_function_to_string(.f = .f, ... = ...)
  py_run_string(fn)
  main <- reticulate::import_main()
  if(!is.null(group_by)) {
    renamed_gp <- paste0("_", group_by)
    df <- x[[1]]$session
    w_gp <- df$withColumn(colName = renamed_gp, col = df[group_by])
    tbl_gp <- w_gp$groupby(renamed_gp)
    tbl_gp$applyInPandas(main$r_apply, schema = .schema)$toPandas()  
  } else {
    stop("group_by = NULL is not supported yet") 
  }
  
}

main <- reticulate::import_main()

tbl_mtcars %>% 
  sa_pandas_grouped(~ mean(.x$mpg), group_by = "cyl")

pd_mtcars$groupby("cyl") %>% 
  sa_pandas_grouped(function(e) summary(lm(wt ~ ., e))$r.squared)

pd_grouped$apply(main$r_apply)

pd_grouped %>% 
  sa_pandas_grouped(~ summary(lm(.$wt ~ ., .x)$r.squared))

pd_grouped %>% 
  sa_pandas_grouped(function(e) mean(e$mpg)) 

pd_grouped %>% 
  sa_pandas_grouped(~ head(.x))

sa_function_to_string(~ mean(.x$mpg))%>% 
  cat()

spark_disconnect(sc)
pysparklyr::spark_connect_service_stop()

