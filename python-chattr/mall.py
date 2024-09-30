import polars as pl

@pl.api.register_dataframe_namespace("split")
class SplitFrame:
    def __init__(self, df: pl.DataFrame) -> None:
        self._df = df

    def by_alternate_rows(self) -> list[pl.DataFrame]:
        df = self._df.with_row_index(name="n")
        return [
            df.filter((pl.col("n") % 2) == 0).drop("n"),
            df.filter((pl.col("n") % 2) != 0).drop("n"),
        ]


pl.DataFrame(
    data=["aaa", "bbb", "ccc", "ddd", "eee", "fff"],
    schema=[("txt", pl.String)],
).split.by_alternate_rows()

