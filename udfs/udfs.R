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

library(dbplyr)
library(dplyr)
library(sparklyr)
library(reticulate)
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


library(dbplyr)
library(dplyr)
library(sparklyr)
library(reticulate)
sc <- spark_connect(
  method = "databricks_connect",
  cluster_id = "1026-175310-7cpsh3g8"
)
tbl_trips <- tbl(sc, in_catalog("samples", "nyctaxi", "trips"))
pd_trips <- tbl_trips[[1]]$session

r_func <- py_func(function(x) head(x))

pd_trips$mapInArrow(func = r_func, schema = pd_trips$schema)
pd_trips$mapInPandas(func = r_func, schema = pd_trips$schema)


sc <- spark_connect(
  method = "databricks_connect",
  cluster_id = "1026-175310-7cpsh3g8"
)
tbl_mtcars <- copy_to(sc, mtcars)
pd_mtcars <- tbl_mtcars[[1]]$session
pd_grouped <- pd_mtcars$groupby("am")
orig_func <- function(x) return(head(x))
r_func <- py_func(orig_func)
pd_grouped$applyInPandas(r_func, pd_mtcars$schema)


library(reticulate)
library(sparklyr)
pysparklyr::spark_connect_service_start()
sc <- spark_connect("sc://localhost", method = "spark_connect", version = "3.5")
tbl_mtcars <- copy_to(sc, mtcars)

orig_func <- function(x) return(head(x))
r_func <- py_func(orig_func)
pd_grouped$applyInPandas(r_func, pd_mtcars$schema)
pd_mtcars <- tbl_mtcars[[1]]$session
pd_grouped <- pd_mtcars$groupby("am")
r_func <- py_func(function(x)x$count())
pd_grouped$applyInPandas(r_func, schema =  pd_mtcars$schema)
