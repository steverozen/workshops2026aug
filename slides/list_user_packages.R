# List packages installed in the user library, with version and source,
# and write them to user_packages.csv in the current directory.

user_lib <- Sys.getenv("R_LIBS_USER")
if (!dir.exists(user_lib)) {
  stop("User library not found: ", user_lib)
}

pkgs <- rownames(installed.packages(lib.loc = user_lib))

package_source <- function(pkg) {
  desc <- packageDescription(pkg, lib.loc = user_lib)
  if (!is.null(desc$RemoteType)) {
    # Installed via remotes/pak, e.g. from GitHub
    if (!is.null(desc$RemoteUsername) && !is.null(desc$RemoteRepo)) {
      paste0(desc$RemoteType, " (", desc$RemoteUsername, "/", desc$RemoteRepo, ")")
    } else {
      desc$RemoteType
    }
  } else if (!is.null(desc$biocViews)) {
    "Bioconductor"
  } else if (!is.null(desc$Repository)) {
    desc$Repository
  } else {
    "unknown (perhaps installed from local source)"
  }
}

result <- data.frame(
  package = pkgs,
  version = vapply(pkgs, function(p) packageDescription(p, lib.loc = user_lib)$Version, ""),
  source  = vapply(pkgs, package_source, ""),
  row.names = NULL
)

write.csv(result, "user_packages.csv", row.names = FALSE)
message("Wrote ", nrow(result), " packages to user_packages.csv")
