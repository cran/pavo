#' Categorical fly-visual model
#'
#' Applies the categorical colour vision model of Troje (1993)
#'
#' @param vismodeldata (required) quantum catch color data. Can be either the result
#'  from [vismodel()] or independently calculated data (in the form of a data frame
#'  with four columns named 'u' ,'s', 'm', 'l', representing a tetrachromatic viewer).
#'
#' @return Object of class `colspace` consisting of the following columns:
#' - `R7p, R7y, R8p, R8y`: the quantum catch data used to
#'  calculate the remaining variables.
#' - `x, y`: cartesian coordinates in the categorical colour space.
#' - `r.vec`: the r vector (saturation, distance from the center).
#' - `h.theta`: angle theta (in radians), a continuous measure of stimulus hue.
#' - `category`: fly-colour category. One of `p-y-`, `p-y+`, `p+y-`, `p+y+`.
#'
#' @examples
#' data(flowers)
#' vis.flowers <- vismodel(flowers, visual = "musca", achromatic = "md.r1")
#' cat.flowers <- colspace(vis.flowers, space = "categorical")
#' @author Thomas White \email{thomas.white026@@gmail.com}
#'
#' @export
#'
#' @keywords internal
#'
#' @references Troje N. (1993). Spectral categories in the learning behaviour
#'  of blowflies. Zeitschrift fur Naturforschung C, 48, 96-96.

categorical <- function(vismodeldata) {
  dat <- vismodeldata

  # if object is vismodel:
  if (is.vismodel(dat)) {

    # check if tetrachromat
    if (attr(dat, "conenumb") < 4) {
      stop("vismodel input is not tetrachromatic", call. = FALSE)
    }

    if (attr(dat, "conenumb") > 4) {
      warning("vismodel input is not tetrachromatic, considering first four receptors only", call. = FALSE)
    }

    # check if relative
    if (!attr(dat, "relative")) {
      warning("Quantum catch are not relative, which may produce unexpected results", call. = FALSE)
    }
  } else {  # if not, check if it has more (or less) than 4 columns
    if (ncol(dat) < 4) {
      stop("Input data is not a ", dQuote("vismodel"),
        " object and has fewer than four columns",
        call. = FALSE
      )
    }
    if (ncol(dat) == 4) {
      warning("Input data is not a ", dQuote("vismodel"),
        " object; treating columns as standardized quantum catch for ",
        dQuote("u"), ", ", dQuote("s"), ", ", dQuote("m"), ", and ", dQuote("l"),
        " receptors, respectively",
        call. = FALSE
      )
    }

    if (ncol(dat) > 4) {
      warning("Input data is not a ", dQuote("vismodel"),
        " object *and* has more than four columns; treating the first four columns as standardized quantum catch for ",
        dQuote("u"), ", ", dQuote("s"), ", ", dQuote("m"), ", and ", dQuote("l"),
        " receptors, respectively",
        call. = FALSE
      )
    }

    dat <- dat[, 1:4]
    names(dat) <- c("u", "s", "m", "l")

    # Check that all rows sum to 1 (taking into account R floating point issue)
    if (!isTRUE(all.equal(rowSums(dat), rep(1, nrow(dat)), check.attributes = FALSE))) {
      # dat <- dat/apply(dat, 1, sum)
      warning("Quantum catch are not relative, which may produce unexpected results", call. = FALSE)
      # attr(vismodeldata,'relative') <- TRUE
    }
  }

  if (all(c("u", "s", "m", "l") %in% names(dat))) {
    R7p <- dat[, "u"]
    R7y <- dat[, "s"]
    R8p <- dat[, "m"]
    R8y <- dat[, "l"]
  } else {
    warning("Could not find columns named ", dQuote("u"), ", ", dQuote("s"), ", ",
      dQuote("m"), ", and ", dQuote("l"), ", using first four columns instead.",
      call. = FALSE
    )
    R7p <- dat[, 1]
    R7y <- dat[, 2]
    R8p <- dat[, 3]
    R8y <- dat[, 4]
  }

  # x & y coordinates
  x <- R7p - R8p
  y <- R7y - R8y

  # Colour category calculator
  colcat <- function(object) {
    if (object$x == 0 && object$y == 0) {
      return(NA_character_)
    }
    if (object$x == 0) {
      return(ifelse(object$y > 0, "y+", "y-"))
    }
    if (object$y == 0) {
      return(ifelse(object$x > 0, "p+", "p-"))
    }

    paste0(
      ifelse(object$x > 0, "p+", "p-"),
      ifelse(object$y > 0, "y+", "y-")
    )
  }

  res <- data.frame(R7p, R7y, R8p, R8y, x, y, row.names = rownames(dat))

  res$category <- vapply(seq_len(nrow(res)), function(x) colcat(res[x, ]), character(1))
  res$r.vec <- sqrt(res$x^2 + res$y^2)
  res$h.theta <- atan2(res$y, res$x)

  class(res) <- c("colspace", "data.frame")

  # Descriptive attributes (largely preserved from vismodel)
  attr(res, "clrsp") <- "categorical"
  attr(res, "conenumb") <- 4
  attr(res, "qcatch") <- attr(vismodeldata, "qcatch")
  attr(res, "visualsystem.chromatic") <- attr(vismodeldata, "visualsystem.chromatic")
  attr(res, "visualsystem.achromatic") <- attr(vismodeldata, "visualsystem.achromatic")
  attr(res, "illuminant") <- attr(vismodeldata, "illuminant")
  attr(res, "background") <- attr(vismodeldata, "background")
  attr(res, "relative") <- attr(vismodeldata, "relative")
  attr(res, "vonkries") <- attr(vismodeldata, "vonkries")

  # Data attributes
  attr(res, "data.visualsystem.chromatic") <- attr(vismodeldata, "data.visualsystem.chromatic")
  attr(res, "data.visualsystem.achromatic") <- attr(vismodeldata, "data.visualsystem.achromatic")
  attr(res, "data.background") <- attr(vismodeldata, "data.background")

  res
}
