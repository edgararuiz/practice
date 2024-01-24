library(reticulate)
library(sparklyr)
pysparklyr::spark_connect_service_start()
sc <- spark_connect("sc://localhost", method = "spark_connect", version = "3.5")
spark <- sc$session
spark$conf$set("spark.sql.execution.arrow.pyspark.enabled", "true")
spark$conf$set("spark.sql.execution.arrow.pyspark.fallback.enabled", "false")
np <- import("numpy")
pd <- import("pandas")
pdf <- pd$DataFrame(np$random$rand(100L, 3L))
df <- spark$createDataFrame(pdf)
result_pdf <- df$select("*")$toPandas()
result_pdf
