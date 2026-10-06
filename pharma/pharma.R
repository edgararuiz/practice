library(cli)

dir.create("core-assets", showWarnings = FALSE)
assets <- normalizePath("core-assets")

if (!file.exists(file.path(assets, "core/core"))) {
  cli_progress_step("Downloading the CORE CLI")
  system2(
    "gh",
    c(
      "release download v0.17.1 -R cdisc-org/cdisc-rules-engine",
      "-p core-mac-apple-silicon.zip -D",
      shQuote(assets)
    )
  )
  zip <- file.path(assets, "core-mac-apple-silicon.zip")
  unzip(zip, exdir = assets)
  unlink(zip)
  Sys.chmod(file.path(assets, "core/core"), "755")
}

if (!dir.exists(file.path(assets, "rules"))) {
  cli_progress_step("Downloading the published CORE rules")
  repo <- tempfile()
  system2(
    "gh",
    c("repo clone cdisc-org/cdisc-open-rules", repo, "-- --depth 1"),
    stderr = FALSE
  )
  # CORE reads rules from a single folder, so Published/<id>/rule.yml becomes rules/<id>.yml
  rule_files <- Sys.glob(file.path(repo, "Published/*/rule.yml"))
  dir.create(file.path(assets, "rules"))
  file.copy(
    rule_files,
    file.path(assets, "rules", paste0(basename(dirname(rule_files)), ".yml"))
  )
  unlink(repo, recursive = TRUE)
}

if (!dir.exists(file.path(assets, "data"))) {
  cli_progress_step("Downloading the CDISC pilot study SDTM datasets")
  domains <- c(
    "ae",
    "cm",
    "dm",
    "ds",
    "ex",
    "lb",
    "mh",
    "qs",
    "relrec",
    "sc",
    "se",
    "suppae",
    "suppdm",
    "suppds",
    "supplb",
    "sv",
    "ta",
    "te",
    "ti",
    "ts",
    "tv",
    "vs"
  )
  dir.create(file.path(assets, "data"))
  download.file(
    paste0(
      "https://raw.githubusercontent.com/cdisc-org/sdtm-adam-pilot-project/master/",
      "updated-pilot-submission-package/900172/m5/datasets/cdiscpilot01/tabulations/sdtm/",
      domains,
      ".xpt"
    ),
    file.path(assets, "data", paste0(domains, ".xpt")),
    method = "libcurl",
    quiet = TRUE
  )
}
cli_progress_done()

# Runs the first 20 rules. Remove `rbind("-r", rules)` below to run them all.
rules <- head(
  sub(".yml", "", list.files(file.path(assets, "rules")), fixed = TRUE),
  20
)

cli_h2("Running CORE validation")
# CORE looks for its cache and templates in its own folder
withr::with_dir(
  file.path(assets, "core"),
  system2(
    "./core",
    c(
      "validate -s sdtmig -v 3-4 -ct sdtmct-2025-09-26 -ps 4",
      "-lr",
      shQuote(file.path(assets, "rules")),
      "-d",
      shQuote(file.path(assets, "data")),
      "-o",
      shQuote(file.path(assets, "validation_report")),
      "-of JSON",
      rbind("-r", rules)
    )
  )
)

report <- jsonlite::fromJSON(file.path(assets, "validation_report.json"))

cli_h2("Rule results")
print(table(report$Rules_Report$status))

cli_h2("Issues by rule and dataset")
print(
  report$Issue_Summary[c("core_id", "dataset", "issues", "message")],
  right = FALSE
)
