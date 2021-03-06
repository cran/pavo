% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/plot.rimg.R
\name{plot.rimg}
\alias{plot.rimg}
\title{Plot unprocessed or colour-classified images}
\usage{
\method{plot}{rimg}(x, axes = TRUE, col = NULL, ...)
}
\arguments{
\item{x}{(required) an image of class rimg, or list thereof.}

\item{axes}{should axes be drawn? (defaults to \code{TRUE})}

\item{col}{optional vector of colours when plotting colour-classified images.
Defaults to the mean RGB values of the k-means centres (i.e. the average 'original'
colours).}

\item{...}{additional graphical parameters. Also see \code{\link[=par]{par()}}.}
}
\value{
an image plot.
}
\description{
Plot unprocessed or colour-classified image data. If the
images are in a list, they will be stepped through
one by one.
}
\examples{
papilio <- getimg(system.file("testdata/images/papilio.png", package = "pavo"))
plot(papilio)
\donttest{
papilio_class <- classify(papilio, kcols = 4)
plot(papilio_class)
}

# Multiple images
snakes <- getimg(system.file("testdata/images/snakes", package = "pavo"))
plot(snakes)
\donttest{
snakes_class <- classify(snakes, kcols = 3)
plot(snakes_class)
}

}
\author{
Thomas E. White \email{thomas.white026@gmail.com}
}
