import pandas as pd
import rpy2.robjects as robjects
from rpy2.robjects import pandas2ri

def r_apply(key, pdf: pd.DataFrame) -> pd.DataFrame:
  pandas2ri.activate()
  r_func =robjects.r("library(arrow); function (x) dplyr::count(x)")
  ret = r_func(pdf)
  return pd.DataFrame(ret)

def filter_func(iterator):
    for pdf in iterator:
        yield pdf
        
