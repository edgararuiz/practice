library(odbc)

con <- dbConnect(
  odbc::databricks(),
  HTTPPath = "/sql/1.0/warehouses/300bd24ba12adf8e"
)
