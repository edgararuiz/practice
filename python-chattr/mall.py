import polars as pl

@pl.api.register_dataframe_namespace("llm")
class MallFrame:
    def __init__(self, df: pl.DataFrame) -> None:
        self._df = df

    def sentiment(self, col) -> list[pl.DataFrame]:
        return(self._df[col])


df = pl.DataFrame(
    data=["I am happy", "I am sad"],
    schema=[("txt", pl.String)],
)

df.llm.sentiment("txt")
