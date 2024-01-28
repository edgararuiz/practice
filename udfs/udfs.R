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

pd_mtcars <- pd_mtcars$withColumn("_am", pd_mtcars$am)
pd_grouped <- pd_mtcars$groupby("_am")

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
  fn_rep <- "function\\(\\.\\.\\.\\) 1"
  fn_r_new <- gsub(fn_rep, fn_str, fn_r)
  gsub(fn_rep, fn_r_new, fn_python)
}

sa_pandas_grouped <- function(grouped_tbl, .f, ..., .schema = "x double") {
  fn <- sa_function_to_string(.f = .f, ... = ...)
  py_run_string(fn)
  main <- reticulate::import_main()
  grouped_tbl$applyInPandas(main$r_apply, schema = .schema)$show()
}

pd_grouped %>% 
  sa_pandas_grouped(function(e) summary(lm(wt ~ ., e))$r.squared)

pd_grouped %>% 
  sa_pandas_grouped(function(e) mean(e$mpg))

spark_disconnect(sc)
pysparklyr::spark_connect_service_stop()

