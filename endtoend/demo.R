library(DBI)
options("odbc.no_config_override" = TRUE)
con <- dbConnect(odbc::databricks(), httpPath = "/sql/1.0/warehouses/2e801027559d252a")


library(tidyverse)

tbl_lending_club <- tbl(con, I("sol_eng_demo_nickp.default.lending_club"))

DBI::dbSendQuery(
  con,
  "CREATE TABLE sol_eng_demo_nickp.end-to-end.lending_club USING com.databricks.spark.csv OPTIONS(path 'dbfs:/databricks-datasets/lending-club-loan-stats/LoanStats_2018Q2.csv', header 'true');"  
)

