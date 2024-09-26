library(httr2)


# "/api/2.1/unity-catalog/volumes"

host <- Sys.getenv("DATABRICKS_HOST")

host_url <- url_parse(host)
if (is.null(host_url$scheme)) host_url$scheme <- "https"

library(purrr)

host_url |> 
  url_build() |> 
  request() |> 
  req_url_path_append("/api/2.1/unity-catalog/catalogs") |> 
  req_auth_bearer_token(Sys.getenv("DATABRICKS_TOKEN")) |> 
  #req_headers(catalog_name = "workshops") |> 
  #req_body_json(list(catalog_name = "workshops")) |> 
  req_url_query(catalog_name = "workshops") |> 
  req_perform() |> 
  resp_body_json() |> 
  list_flatten() |> 
  map(~.x$name)

volumes <- host_url |> 
  url_build() |> 
  request() |> 
  req_url_path_append("/api/2.1/unity-catalog/volumes") |> 
  req_auth_bearer_token(Sys.getenv("DATABRICKS_TOKEN")) |> 
  req_url_query(catalog_name = "workshops", schema_name = "models") |> 
  req_perform() |> 
  resp_body_json() |> 
  list_flatten() 
  
volumes$volumes$full_name

host_url |> 
  url_build() |> 
  request() |> 
  req_url_path_append("/api/2.0/fs/directories/") |> 
  req_url_path_append("Volumes/workshops/models/vetiver/mtcars") |> 
  req_auth_bearer_token(Sys.getenv("DATABRICKS_TOKEN")) |> 
  req_perform() |> 
  resp_body_json() |> 
  list_flatten() 


paste0(
  "https://rstudio-partner-posit-default.cloud.databricks.com",
  "/api/2.1/unity-catalog/catalogs"
) |> 
  request() |> 
  req_auth_bearer_token(Sys.getenv("DATABRICKS_TOKEN")) |> 
  #req_body_json(list(catalog_name = "workshops")) |> 
  #req_headers(catalog_name = "workshops") |> 
  #req_method("GET") |> 
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




host_url |> 
  url_build() |> 
  request() |> 
  req_url_path_append("/api/2.1/unity-catalog/volumes") |> 
  req_auth_bearer_token(Sys.getenv("DATABRICKS_TOKEN")) |> 
  req_headers(name = "workshops.models.vetiver") |> 
  req_perform()




headers <- c(Authentication = paste("Bearer", Sys.getenv("DATABRICKS_TOKEN"))) 
#headers["Connection"] <- "close"
#body <- NULL
url <- paste0(
  "https://rstudio-partner-posit-default.cloud.databricks.com",
  "/api/2.1/unity-catalog/volumes"
)
method <- "GET"
query <- list(catalog_name = "workshops", schema_name = "models")
response <- httr::GET(
  url = url, 
  httr::add_headers(headers), 
  #httr::user_agent("test"),
  #httr::config(verbose = FALSE, connecttimeout = 30), 
  #httr::accept_json(),
  #httr::write_memory(), 
  #query = base::Filter(length, query),
  query = query
  )

json_string <- httr::content(response, as = "text", encoding = "UTF-8")
jsonlite::fromJSON(json_string)
