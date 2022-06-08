options(
  repos = c(CRAN = "https://packagemanager.rstudio.com/all/latest")
)
if (!nzchar(Sys.getenv("GITHUB_PAT"))) {
  try(Sys.setenv(GITHUB_PAT = gitcreds::gitcreds_get(
    url = "https://github.com"
  )$password), silent = TRUE)
  if (!nzchar(Sys.getenv("GITHUB_PAT"))) {
    stop("Failed to get GITHUB_PAT environment variable. Generate and copy a PAT using `usethis::create_github_token()`. Either add GitHub PAT to system using `gitcreds::gitcreds_set()`, or add GITHUB_PAT=<gh_pat> to .Renviron file.") # nolint
  }
}

if (any(grepl("^SLURM_", names(Sys.getenv())))) {
  grDevices::png(file.path(tempdir(), "test.png"))
}
