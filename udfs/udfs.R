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

tbl_mtcars %>% 
  spark_apply(nrow, group_by = "cyl")

tbl_mtcars %>% 
  spark_apply(nrow, barrier = TRUE)

####################
spark_disconnect(sc)
pysparklyr::spark_connect_service_stop()
####################


tbl_mtcars %>% 
  spark_apply()

pd_mtcars <- tbl_mtcars[[1]]$session

pd_grouped <- pd_mtcars$groupby("am")

sa_function_to_string <- function(.f, .group_by = NULL, ...) {
  path_scripts <- here::here("udfs")
  if(!is.null(.group_by)) {
    udf_r <- "udf-apply.R"
    udf_py <- "udf-apply.py"
    
  } else {
    udf_r <- "udf-map.R"
    udf_py <- "udf-map.py"
  }
  fn_r <- paste0(
    readLines(path(path_scripts, udf_r)),
    collapse = ""
  )
  fn_python <- paste0(
    readLines(path(path_scripts, udf_py)), 
    collapse = "\n"
  )
  if(!is.null(.group_by))  {
    fn_r <- gsub(
      "gp_field <- 'am'",
      paste0("gp_field <- '", .group_by,"'"),
      fn_r
    )     
  }
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

sa_in_pandas <- function(x, .f, ..., .schema = "x double", .group_by = NULL) {
  
  fn <- sa_function_to_string(.f = .f, .group_by = .group_by, ... = ...)
  py_run_string(fn)
  main <- reticulate::import_main()
  df <- x[[1]]$session
  if(!is.null(.group_by)) {
    #TODO: Add support for multiple grouping columns
    renamed_gp <- paste0("_", .group_by)
    w_gp <- df$withColumn(colName = renamed_gp, col = df[.group_by])
    tbl_gp <- w_gp$groupby(renamed_gp)
    ret <- tbl_gp$applyInPandas(main$r_apply, schema = .schema)$toPandas()  
  } else {
    ret <- df$mapInPandas(main$r_apply, schema = .schema)$toPandas()
  }
  ret
}

tbl_mtcars %>% 
  sa_in_pandas(nrow)

tbl_mtcars %>% 
  sa_in_pandas(~ mean(.x$mpg), .group_by = "cyl", .schema = "cyl long, x double")

tbl_mtcars %>% 
  sa_in_pandas(function(e) data.frame(x = mean(e$mpg)))

tbl_mtcars %>% 
  spark_apply(function(e) summary(
    lm(wt ~ ., e))$r.squared, 
    group_by = "cyl", 
    columns = "cyl long, x double" 
    )

pd_grouped$apply(main$r_apply)

pd_grouped %>% 
  sa_in_pandas(~ summary(lm(.$wt ~ ., .x)$r.squared))

pd_grouped %>% 
  sa_in_pandas(function(e) mean(e$mpg)) 

pd_grouped %>% 
  sa_in_pandas(~ head(.x))

sa_function_to_string(~ mean(.x$mpg))%>% 
  cat()


model <- lm(mpg ~ ., mtcars)
saveRDS(model, "/Users/edgar/r_projects/practice/udfs/model.rds")
py_run_string("def filter_func(iterator):
  import pandas as pd
  for pdf in iterator:
      yield pd.DataFrame(pdf['mpg'])"
)
py_run_string("import pandas as pd
import rpy2.robjects as robjects
from rpy2.robjects import pandas2ri
def r_map(iterator):
  for pdf in iterator:
    pandas2ri.activate()
    #r_func = robjects.r(\"function(df) df[1, 1:3]\")
    r_func = robjects.r(\"function(df) data.frame(x = mean(df$mpg))\")
    ret = r_func(pdf)
    yield pandas2ri.rpy2py_dataframe(ret)"
  )
main <- reticulate::import_main()
pd_mtcars$mapInPandas(main$r_map, "x double")$show()
pd_second <- pd_mtcars$repartition(numPartitions = 2L)
pd_second$mapInPandas(main$r_map, "x double")$show()


pd_mtcars$mapInPandas(main$r_map, "mpg double, cyl double, disp long")$show()

mtcars[1, 1:3]


trees_tbl <- sdf_copy_to(sc, trees, repartition = 2)

spark_apply(trees_tbl, function(e) head(e, 1))

spark_apply(trees_tbl, function(e) scale(e), columns = "Girth double, Height double, Volume double")

spark_apply(
  trees_tbl,
  function(e) nrow(e), names = "n"
)


iris_tbl <- sdf_copy_to(sc, iris)

spark_apply(iris_tbl, nrow, group_by = "Species", "Species string, x long")

remotes::install_github("sparklyr/sparklyr", ref = "udf")
remotes::install_github("mlverse/pysparklyr", ref = "udf")
library(sparklyr)
library(dplyr)
library(dbplyr)
sc <- spark_connect(method = "databricks_connect", cluster_id = "1026-175310-7cpsh3g8")

tbl_mtcars <- copy_to(sc, mtcars)

tbl_mtcars %>% 
  spark_apply(nrow, group_by = "am")

tbl_mtcars %>% 
  spark_apply(function(e) scale(e))

tbl_mtcars %>%
  spark_apply(
    function(e) summary(lm(mpg ~ ., e))$r.squared,
    columns = "am long, x double",
    group_by = "am"
  )

spark_apply(
  tbl_mtcars,
  function(e) x <- broom::tidy(lm(wt ~ ., e)),
  group_by = "am"
)



test1 <- sa_function_to_string(function(e) x <- broom::tidy(lm(wt ~ ., e)), .group_by = "am", .r_only = TRUE) %>% 
  rlang::parse_expr() %>% 
  eval()

test1()
