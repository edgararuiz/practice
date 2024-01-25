import pandas as pd
from pyspark.sql.functions import pandas_udf
@pandas_udf("double")  # type: ignore[call-overload]
def mean_udf(v: pd.Series) -> float:
    return v.mean()

def subtract_mean(pdf: pd.DataFrame) -> pd.DataFrame:
    # pdf is a pandas.DataFrame
    v = pdf.mpg
    return pdf.assign(mpg=v - v.mean())
