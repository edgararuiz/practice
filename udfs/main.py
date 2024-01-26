import pandas as pd
import rpy2.robjects as robjects
from rpy2.robjects import pandas2ri

def r_apply(key, pdf: pd.DataFrame) -> pd.DataFrame:
  pandas2ri.activate()
  r_func =robjects.r("library(arrow); function (x) dplyr::count(x)")
  ret = r_func(pdf)
  return pd.DataFrame(ret)


import pandas as pd
import rpy2 as rpy2
import rpy2.robjects as robjects
from rpy2.robjects import pandas2ri
def r_apply(key, pdf: pd.DataFrame) -> pd.DataFrame:
  pandas2ri.activate()
  r_func =robjects.r("function(...){x <- structure(function (..., .x = ..1, .y = ..2, . = ..1) mean(.x$mpg) - 2, class = c(\"rlang_lambda_function\", \"function\")); x(...)}")
  ret = r_func(pdf)
  return pd.DataFrame(ret)

df = robjects.r("function() mtcars")

import rpy2.robjects as ro
with (ro.default_converter + pandas2ri.converter).context():
  r_from_pd_df = ro.conversion.py2rpy(df1)

rpy2py(df1)
ro.
df1 = df()
ro.DataFrame()
