
#' Configure which version of Python to use
#'
#' @param python Path to Python binary
#' @param virtualenv Directory of Python virtualenv
#' @param condaenv Name of Conda environment
#' @param conda Conda executable. Default is `"auto"`, which checks the `PATH`
#'   as well as other standard locations for Anaconda installations.
#' @param required Is this version of Python required? If `TRUE` then an error
#'   occurs if it's not located. Otherwise, the version is taken as a hint only
#'   and scanning for other versions will still proceed.
#'
#' @importFrom utils file_test
#'
#' @export
use_python <- function(python, required = FALSE) {

  if (required && !file_test("-f", python) && !file_test("-d", python))
    stop("Specified version of python '", python, "' does not exist.")

  # if required == TRUE and python is already initialized then confirm that we
  # are using the correct version
  if (required && is_python_initialized()) {
    normalize <- function(path) {
      normalizePath(normalize_python_path(path)$path, winslash = "/")
    }
    if (!identical(normalize(py_config()$python), normalize(python))) {
      stop("Required version of Python '", python ,"' cannot be used ",
           "because another version of Python ('", py_config()$python,
           "') is already initialized ", "for this process.")
    }
  }

  if (required)
    .globals$required_python_version <- python

  .globals$use_python_versions <- unique(c(.globals$use_python_versions, python))
}


#' @rdname use_python
#' @export
use_virtualenv <- function(virtualenv, required = FALSE) {

  # prepend root virtualenv directory it doesn't exist and
  # it's not an absolute path
  if (!utils::file_test("-d", virtualenv) &
      !grepl("^/|^[a-zA-Z]:/|^~", virtualenv, perl = TRUE)) {
    workon_home <- Sys.getenv("WORKON_HOME", unset = "~/.virtualenvs")
    virtualenv <- file.path(workon_home, virtualenv)
  }

  # compute the bin dir
  if (is_windows())
    python_dir <- file.path(virtualenv, "Scripts")
  else
    python_dir <- file.path(virtualenv, "bin")


  # validate it if required
  if (required && !is_python_virtualenv(virtualenv))
    stop("Directory ", virtualenv, " is not a Python virtualenv")

  # set the option
  python <- file.path(python_dir, "python")
  if (is_windows())
    python <- paste0(python, ".exe")
  use_python(python, required = required)
}

#' @rdname use_python
#' @export
use_condaenv <- function(condaenv, conda = "auto", required = FALSE) {

  # list all conda environments
  conda_envs <- conda_list(conda)

  # look for one with that name
  conda_env_python <- subset(conda_envs, conda_envs$name == condaenv)$python
  if (length(conda_env_python) == 0 && required)
    stop("Unable to locate conda environment '", condaenv, "'.")

  if (!is.null(condaenv))
    use_python(conda_env_python, required = required)

  invisible(NULL)
}
