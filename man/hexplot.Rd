% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/hexplot.R
\name{hexplot}
\alias{hexplot}
\title{Plot a colour hexagon}
\usage{
hexplot(
  hexdata,
  achro = TRUE,
  labels = TRUE,
  sectors = c("none", "fine", "coarse"),
  sec.col = "grey",
  out.lwd = 1,
  out.lty = 1,
  out.lcol = "black",
  labels.cex = 1,
  achrosize = 0.8,
  achrocol = "grey",
  square = TRUE,
  ...
)
}
\arguments{
\item{hexdata}{(required) a data frame, possibly a result from the
\code{\link[=colspace]{colspace()}} or \code{\link[=hexagon]{hexagon()}} function, containing values for the 'x' and 'y'
coordinates as columns (labeled as such)}

\item{achro}{should a point be plotted at the origin (defaults to \code{TRUE})?}

\item{labels}{logical. Should the name of each cone be printed next to the
corresponding vertex?}

\item{sectors}{plot the bee-hue sector dividers? Options are:
\itemize{
\item \code{"none"}: No sectors (default)
\item \code{"fine"}: 36 10-degree sectors
\item \code{"coarse"}: six bee-hue sectors (blue, blue-green, green, uv-green, uv,
uv-blue).
}}

\item{sec.col}{line colour of hue sector dividers. Defaults to \code{"grey"}.}

\item{out.lwd, out.lcol, out.lty}{graphical parameters for the plot outline.}

\item{labels.cex}{size of the arrow labels.}

\item{achrosize}{size of the point at the origin when \code{achro = TRUE}
(defaults to \code{0.8}).}

\item{achrocol}{color of the point at the origin \code{achro = TRUE} (defaults to
\code{'grey'}).}

\item{square}{logical. Should the aspect ratio of the plot be held to 1:1?
(defaults to \code{TRUE}).}

\item{...}{additional graphical options. See \code{\link[=par]{par()}}.}
}
\description{
Produces a colour hexagon plot.
}
\examples{
data(flowers)
vis.flowers <- vismodel(flowers,
  visual = "apis", qcatch = "Ei", relative = FALSE,
  vonkries = TRUE, achromatic = "l", bkg = "green"
)
hex.flowers <- colspace(vis.flowers, space = "hexagon")
plot(hex.flowers)
}
\references{
Chittka L. (1992). The colour hexagon: a chromaticity diagram
based on photoreceptor excitations as a generalized representation of
colour opponency. Journal of Comparative Physiology A, 170(5), 533-543.

Chittka L, Shmida A, Troje N, Menzel R. (1994). Ultraviolet as a
component of flower reflections, and the colour perception of Hymenoptera.
Vision research, 34(11), 1489-1508.
}
\author{
Thomas White \email{thomas.white026@gmail.com}
}
\keyword{internal}
