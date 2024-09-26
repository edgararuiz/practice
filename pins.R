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
  req_headers(catalog_name = "workshops") |> 
  #req_body_json(list(catalog_name = "workshops")) |> 
  req_perform(verbosity = 3) |> 
  resp_body_json() |> 
  list_flatten() |> 
  map(~.x$name)

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


#curl --request GET "https://${DATABRICKS_HOST}api/2.1/unity-catalog/volumes/" --header "Authorization: Bearer ${DATABRICKS_TOKEN}" | jq .



headers <- c(Authentication = paste("Bearer", Sys.getenv("DATABRICKS_TOKEN"))) 
headers["Connection"] <- "close"
body <- NULL
if (!is.null(body)) {
  body <- base::Filter(length, body)
  body <- jsonlite::toJSON(body, auto_unbox = TRUE, digits = 22, null = "null")
}
url <- paste0(
  "https://rstudio-partner-posit-default.cloud.databricks.com",
  "/api/2.1/unity-catalog/volumes"
)
method <- "GET"
query <- list(catalog_name = "workshops", schema_name = "models")
response <- httr::VERB(method, url, httr::add_headers(headers), httr::user_agent("test"),
                       httr::config(verbose = FALSE, connecttimeout = 30), httr::accept_json(),
                       httr::write_memory(), query = base::Filter(length, query), body = body)

json_string <- httr::content(response, as = "text", encoding = "UTF-8")
jsonlite::fromJSON(json_string)
