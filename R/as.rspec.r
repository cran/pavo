#' Convert data to an rspec object
#'
#' Converts data frames or matrices containing spectral data to \code{rspec}
#' object
#'
#' @param object (required) a data frame or matrix containing spectra to
#' process.
#' @param whichwl specifies which column contains wavelengths. If NULL
#' (default), function searches for column containing equally spaced numbers
#' and sets it as wavelengths "wl". If no wavelengths are found or
#' \code{whichwl} is not given, returns arbitrary index values.
#' @param interp whether to interpolate wavelengths in 1-nm bins (defaults to
#' TRUE).
#' @param lim vector specifying wavelength range to interpolate over (e.g.
#' \code{c(300, 700)}).
#'
#' @return an object of class \code{rspec} for use in further \code{pavo}
#' functions
#'
#' @export as.rspec is.rspec
#'
#' @examples \dontrun{
#'
#' # Generate some fake reflectance data
#' fakedat <- data.frame(wl = 300:700, refl1 = rnorm(401), refl2 = rnorm(401))
#' head(fakedat)
#'
#' # Determine if is rspec object
#' is.rspec(fakedat)
#'
#' # Convert to rspec object
#' fakedat2 <- as.rspec(fakedat)
#' is.rspec(fakedat2)
#' head(fakedat2)}
#'
#' @author Chad Eliason \email{cme16@@zips.uakron.edu}

as.rspec <- function(object, whichwl = NULL, interp = TRUE, lim = NULL) {

  # tibble dodge
  if ("tbl_df" %in% attr(object, "class")) object <- data.frame(object)

  if (is.matrix(object) || is.data.frame(object)) {
    name <- colnames(object)
  } else {
    stop("object must be a data frame or matrix")
  }

  # How to handle wavelength column.
  # Possible conditions for wavelength column:
  #            |  specified   | not specified
  # -----------------------------------------
  # given      |      1       |     3
  # not given  |      2       |     4
  # Case 1: wl | col1 | col2... whichwl=... --> use whichwl
  # Case 2:      col1 | col2...; lim=c(300, 700) --> use lim[1]:lim[2]
  # Case 3: wl | col1 | col2... (no whichwl, lim) --> use correlation find
  # Case 4:      col1 | col2... --> use arbitrary numbering

  # try to automatically find wavelength column. for increasing wavelengths,
  # expect a perfect correlation between lambda values and column indices
  # ind <- sapply(1:ncol(object), function(x) {sd(diff(object[,x]))})
  ind <- apply(object, 2, function(x) {
    cor(x, 1:nrow(object))
  })

  if (!is.null(whichwl)) {
    wl_index <- whichwl
    wl <- object[, wl_index]
    object <- object[, -wl_index, drop = FALSE]
    name <- name[-wl_index]
  } else if (any(ind > 0.999)) {
    wl_index <- which(ind > 0.999)[1]
    wl <- object[, wl_index]
    object <- object[, -wl_index, drop = FALSE]
    name <- name[-wl_index]
    message("wavelengths found in column ", wl_index)
  } else if (!is.null(lim)) {
    wl <- seq(lim[1], lim[2], length = nrow(object))
    warning(
      "No wavelengths contained in dataset, using user-specified range. ",
      "Check output carefully!"
    )
  } else {
    wl <- 1:nrow(object)
    warning(
      "No wavelengths found or whichwl not provided; ",
      "using arbitrary index values"
    )
  }

  l1.dat <- ceiling(wl[which.min(wl)]) # lower wavelength limit of given data
  l2.dat <- floor(wl[which.max(wl)]) # upper wavelength limit of given data

  # Get data limits
  if (is.null(lim)) {
    l1 <- l1.dat
    l2 <- l2.dat
  } else {
    l1 <- lim[1]
    l2 <- lim[2]
    if (l1.dat > lim[1] || l2.dat < lim[2]) {
      warning(
        "Specified wavelength limits outside of actual data. ",
        "Check 'lim' argument."
      )
    }
  }

  # Interpolation & data-trimming
  if (interp) {
    object <- apply(object, 2, function(col) {
      approx(x = wl, y = col, xout = l1:l2, rule = 2)$y
    })
    # rule=2 gives value at nearest point instead of giving NAs in the case of
    # the user inputting wls that start at, say, 300.1nm
    wl <- seq(l1, l2)
  }

  res <- cbind(wl, object)

  colnames(res) <- c("wl", name)

  wl_index <- which(colnames(res) == "wl")

  if (length(wl_index) > 1) {
    warning("Multiple columns named 'wl', check column names")
    colnames(res)[wl_index] <- c("wl", paste0("wl.", wl_index[-1] - 1))
  }

  # Trim data when not interpolating (todo: bit clumsy, weave this in above &
  # perhaps default to nearest-wavelength if incorrect reference is provided)
  if (!interp && !is.null(lim)) {
    if (l1 %in% res$wl && l2 %in% res$wl) {
      res <- res[which(res$wl == l1):which(res$wl == l2), ]
    } else {
      stop(
        "Specified limits do not match a wavelength reference in the data. ",
        "Check 'lim' argument."
      )
    }
  }

  res <- as.data.frame(res)
  class(res) <- c("rspec", "data.frame")

  return(res)
}

#' @rdname as.rspec
#' @return a logical value indicating whether the object is of class
#' \code{rspec}

is.rspec <- function(object) {
  inherits(object, "rspec")
}
