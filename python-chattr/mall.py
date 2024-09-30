import polars as pl

@pl.api.register_dataframe_namespace("llm")
class MallFrame:
    def __init__(self, df: pl.DataFrame) -> None:
        self._df = df

    def sentiment(self, col) -> list[pl.DataFrame]:
        df = self._df.with_columns(  
           pl.col(col)
            .map_elements(lambda x: len(x), return_dtype=pl.Int64)
            .alias("a_times_2")
            )
        return(df)


df = pl.DataFrame(
    data=["I am happy", "I am sad"],
    schema=[("txt", pl.String)],
)

df.llm.sentiment("txt")

