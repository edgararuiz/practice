import pandas as pd
from pyspark.sql.functions import pandas_udf
@pandas_udf("double")  # type: ignore[call-overload]
def mean_udf(v: pd.Series) -> float:
    return v.mean()

import pyarrow as py
def subtract_mean(pdf: py.table) -> py.table:
    # pdf is a pandas.DataFrame
    v = pdf.mpg
    return pdf.assign(mpg=v - v.mean())

from pyspark.sql.functions import pandas_udf

import pyarrow as py
def subtract_mean(pdf: py.table) -> py.table:
    # pdf is a pandas.DataFrame
    v = pdf.mpg
    return pdf.assign(mpg=v - v.mean())
  
import rpy2.robjects as robjects
from rpy2.robjects import pandas2ri

def r_apply(pdf: float) -> float:
  pandas2ri.activate()
  robjects.numpy2ri.activate()
  r_func =robjects.r("function (x) x")
  return r_func(pdf)

def filter_func(iterator):
    for pdf in iterator:
        yield pdf
        
