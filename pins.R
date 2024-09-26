library(httr2)


# "/api/2.1/unity-catalog/volumes"

host <- Sys.getenv("DATABRICKS_HOST")

host_url <- url_parse(host)
if (is.null(host_url$scheme)) host_url$scheme <- "https"

resp <- host_url |> 
  url_build() |> 
  request() |> 
  req_url_path_append("/api/2.1/unity-catalog/volumes") |> 
  req_auth_bearer_token(Sys.getenv("DATABRICKS_TOKEN")) |> 
  req_body_json(
    list(
      catalog_name = "workshop", 
      schema_name = "models"
    )
  ) |> 
  req_perform()

  

