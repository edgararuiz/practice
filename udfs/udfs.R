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
  fn_output <- paste0(readLines(here::here("udfs/udf-function.R")), collapse = "")
  fn <- purrr::as_mapper(.f = .f, ... = ...)
  str_fn <- paste0(deparse(fn), collapse = "")
  ret <- gsub("function\\(\\.\\.\\.\\) 1", str_fn, fn_output)
  gsub("\"", "'", ret)
}

#sa_function_to_string(~ data.frame(x = .x$am[1], y = mean(.x$mpg)))
#wr <- sa_function_to_string(nrow, na.rm = TRUE)
wr <- sa_function_to_string(function(e) summary(lm(mpg ~ ., e))$r.squared)
wr
py_run_string(
paste0("import pandas as pd
import rpy2.robjects as robjects
from rpy2.robjects import pandas2ri
def r_apply(key, pdf: pd.DataFrame) -> pd.DataFrame:
  pandas2ri.activate()
  r_func =robjects.r(\"", wr, "\")
  ret = r_func(pdf)
  return pandas2ri.rpy2py_dataframe(ret)
"))
main <- reticulate::import_main()
pd_grouped$applyInPandas(main$r_apply, schema = "x double")$show()

  
spark_disconnect(sc)
pysparklyr::spark_connect_service_stop()


library(dplyr)


library(rlang)
test_func <- function(.x, .f, ...) {
  new_f <- purrr::as_mapper(.f, ...)
  new_f
}
f1 <- test_func(mtcars, ~ mean(.x$mpg) - 2) 
f2 <- test_func(mtcars, sd, na.rm = FALSE)

as_function(f1)
rlang::expr_text(f2)

test1 <- function(e) summary(lm(wt ~ ., e))$r.squared
as.data.frame(test1(mtcars))
