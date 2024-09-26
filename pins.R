library(httr2)


# "/api/2.1/unity-catalog/volumes"

host <- Sys.getenv("DATABRICKS_HOST")

host_url <- url_parse(host)
if (is.null(host_url$scheme)) host_url$scheme <- "https"

library(purrr)

paste0(
  "https://rstudio-partner-posit-default.cloud.databricks.com",
  "/api/2.1/unity-catalog/catalogs"
) |> 
  request() |> 
  req_auth_bearer_token(Sys.getenv("DATABRICKS_TOKEN")) |> 
  #req_headers(name = "workshops") |> 
  req_headers(catalog_name = "workshops") |> 
  req_method("GET") |> 
  #req_dry_run()
  req_perform() |> 
  resp_body_json() |> 
  list_flatten() |> 
  map(~.x$name)



paste0(
  "https://rstudio-partner-posit-default.cloud.databricks.com",
  "/api/2.0/unity-catalog/schemas"
) |> 
  request() |> 
  #req_body_json(list(catalog_name = "workshops")) |> 
  req_headers(catalog_name = "workshops") |> 
  req_auth_bearer_token(Sys.getenv("DATABRICKS_TOKEN")) |> 
  req_perform()



request("https://rstudio-partner-posit-default.cloud.databricks.com") |> 
  req_url_path_append("/api/2.1/unity-catalog/volumes") |> 
  req_auth_bearer_token(Sys.getenv("DATABRICKS_TOKEN")) |> 
  req_headers(name = "workshops.models.vetiver") |> 
  req_perform()


#curl --request GET "https://${DATABRICKS_HOST}api/2.1/unity-catalog/volumes/" --header "Authorization: Bearer ${DATABRICKS_TOKEN}" | jq .


