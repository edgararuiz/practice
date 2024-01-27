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
python_func <- paste0("import pandas as pd
import rpy2.robjects as robjects
from rpy2.robjects import pandas2ri
def r_apply(key, pdf: pd.DataFrame) -> pd.DataFrame:
  pandas2ri.activate()
  r_func =robjects.r(\"function(x) data.frame(avg_mpg = mean(x$mpg), avg_wt = mean(x$wt))\")
  ret = r_func(pdf)
  return pandas2ri.rpy2py_dataframe(ret)
")
py_run_string(python_func)
main <- reticulate::import_main()
pd_grouped$applyInPandas(main$r_apply, schema = "avg_mpg double, avg_wt double")$show()
