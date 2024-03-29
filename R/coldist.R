#' Colour distances
#'
#' Calculates colour distances. When data are the result of [vismodel()], it
#' applies the receptor-noise model of Vorobyev et al. (1998) to calculate
#' colour distances with noise based on relative photoreceptor densities. It
#' also accepts [colspace()] data in which case unweighted Euclidean distances,
#' CIE2000 distances (cielab and cielch only), or Manhattan distances (coc model only)
#' are returned.
#'
#' @param modeldata (required) quantum catch colour data. Can be the result from
#'   [vismodel()] for noise-weighted Euclidean distances, or [colspace()] for
#'   unweighted (typically) Euclidean distances. Data may also be independently
#'   calculated quantum catches, in the form of a data frame with columns
#'   representing photoreceptors.
#' @param qcatch if the object is of class [`vismodel`] or [`colspace`], this
#'   argument is ignored. If the object is a data frame of quantal catches from
#'   another source, this argument is used to specify what type of quantum catch
#'   is being used, so that the noise can be calculated accordingly: * `Qi`:
#'   Quantum catch for each photoreceptor * `fi`: Quantum catch according to
#'   Fechner's law (the signal of the receptor channel is proportional to the
#'   logarithm of the quantum catch)
#' @param subset If only some of the comparisons should be returned, a character
#'   vector of length 1 or 2 can be provided, indicating which samples are
#'   desired. The subset vector must match the labels of the input samples, but
#'   partial matching (and regular expressions) are supported.
#' @param achromatic Logical. If `TRUE`, last column of the data frame is used
#'   to calculate the achromatic contrast, the form of which will depend on the
#'   input data and will be indicated by a message during execution. For
#'   noise-weighted distances, noise is based on the Weber fraction given by the
#'   argument `weber.achro`.
#' @param n photoreceptor densities for the cones used in visual modeling. must
#'   have same length as number of columns (excluding achromatic receptor if
#'   used; defaults to the Pekin robin *Leiothrix lutea* densities:
#'   `c(1,2,2,4)`). Ignored for [`colspace`] objects.
#' @param weber The Weber fraction(s) to be used (often also referred to as
#'   receptor noise, or *e*). The noise-to-signal ratio `v` is unknown, and
#'   therefore must be calculated based on the empirically estimated Weber
#'   fraction of one or (more rarely) all the cone classes. When noise is only
#'   known for one receptor, as is typical, `v` is then applied to estimate the
#'   Weber fraction of the other cones. By default, the value of 0.1 is used
#'   (the empirically estimated value for the LWS cone from *Leiothrix lutea*).
#'   See Olsson et al. 2017 for a review of published values in the literature.
#'   Ignored for `colspace` objects.
#' @param weber.ref the cone class used to obtain the empirical estimate of the
#'   Weber fraction used for the `weber` argument, if a single value is
#'   specified. By default, `n4` is used, representing the LWS cone for
#'   *Leiothrix lutea*. Ignored for `colspace` objects.
#' @param weber.achro the Weber fraction to be used to calculate achromatic
#'   contrast, when `achromatic = TRUE`. Defaults to 0.1. Ignored for `colspace`
#'   objects.
#' @param noise how the noise will be calculated (ignored for `colspace`
#'   objects):
#'   * `neural` (default): noise is proportional to the Weber fraction and is
#'   independent of the intensity of the signal received (i.e. assumes bright
#'   conditions).
#'   * `quantum`: noise is the sum of the neural noise and receptor noise, and
#'   is thus proportional to the Weber fraction and inversely proportional to
#'   the intensity of the signal received (the quantum catches).
#'   Note that the `quantum` option will only work with objects of
#'   class `vismodel`.
#'
#' @return A data frame containing up to 4 columns. The first two
#'   (`patch1, patch2`) refer to the two colors being contrasted; `dS` is the
#'   chromatic contrast (delta S) and `dL` is the achromatic contrast (delta L).
#'   Units of `dS` JND's in the receptor-noise model, unweighted Euclidean
#'   distances in colorspace models, and Manhattan distances in the
#'   colour-opponent-coding space. Units of `dL` vary, and are either simple
#'   contrast, Weber contrast, or Michelson contrast, as indicated by the output
#'   message.
#'
#' @section Note on previous versions: Generic di- tri- and tetra-chromatic
#'   `colspace` objects were previously passed through the receptor-noise
#'   limited model to return noise-weighted Euclidean distances. This behaviour
#'   has been amended, and generic spaces now return unweighted Euclidean
#'   distances. Equivalent results to the former behaviour can be attained by
#'   sending the results of [vismodel()] directly to [coldist()] , as
#'   previously, which also offers greater flexibility and reliability. Thus
#'   [coldist()] now returns unweighted Euclidean distances for `colspace`
#'   objects (with the exception of Manhattan distances for the coc space, and CIE2000,
#'   distances for CIELab and CIELCh spaces), and noise-weighted Euclidean distances
#'   for `vismodel` objects.
#'
#' @export
#'
#' @importFrom stats dist setNames
#' @importFrom farver compare_colour
#' @importFrom utils combn
#'
#' @examples
#' \donttest{
#' # Dichromat
#' data(flowers)
#' vis.flowers <- vismodel(flowers, visual = "canis", relative = FALSE)
#' didist.flowers <- coldist(vis.flowers, n = c(1, 2))
#'
#' # Trichromat
#' vis.flowers <- vismodel(flowers, visual = "apis", relative = FALSE)
#' tridist.flowers <- coldist(vis.flowers, n = c(1, 2, 1))
#'
#' # Trichromat, colour-hexagon model (euclidean distances)
#' vis.flowers <- vismodel(flowers,
#'   visual = "apis", qcatch = "Ei",
#'   relative = FALSE, vonkries = TRUE, achromatic = "l", bkg = "green"
#' )
#' hex.flowers <- colspace(vis.flowers, space = "hexagon")
#' hexdist.flowers <- coldist(hex.flowers)
#'
#' # Trichromat, colour-opponent-coding model (manhattan distances)
#' vis.flowers <- vismodel(flowers, visual = "apis", qcatch = "Ei", relative = FALSE, vonkries = TRUE)
#' coc.flowers <- colspace(vis.flowers, space = "coc")
#' hexdist.flowers <- coldist(coc.flowers)
#'
#' # Tetrachromat
#' data(sicalis)
#' vis.sicalis <- vismodel(sicalis, visual = "avg.uv", relative = FALSE)
#' tetradist.sicalis.n <- coldist(vis.sicalis)
#' }
#'
#' @author Thomas E. White \email{thomas.white026@@gmail.com}
#' @author Rafael Maia \email{rm72@@zips.uakron.edu}
#'
#' @references Vorobyev, M., Osorio, D., Bennett, A., Marshall, N., & Cuthill,
#'   I. (1998). Tetrachromacy, oil droplets and bird plumage colours. Journal Of
#'   Comparative Physiology A-Neuroethology Sensory Neural And Behavioral
#'   Physiology, 183(5), 621-633.
#' @references Hart, N. S. (2001). The visual ecology of avian photoreceptors.
#'   Progress In Retinal And Eye Research, 20(5), 675-703.
#' @references Endler, J. A., & Mielke, P. (2005). Comparing entire colour
#'   patterns as birds see them. Biological Journal Of The Linnean Society,
#'   86(4), 405-431.
#' @references Olsson, P., Lind, O., & Kelber, A. (2015) Bird colour vision:
#'   behavioural thresholds reveal receptor noise. Journal of Experimental
#'   Biology, 218, 184-193.
#' @references Lind, O. (2016) Colour vision and background adaptation in a
#'   passerine bird, the zebra finch (Taeniopygia guttata). Royal Society Open
#'   Science, 3, 160383.
#' @references Olsson, P., Lind, O., & Kelber, A. (2017) Chromatic and
#'   achromatic vision: parameter choice and limitations for reliable model
#'   predictions. Behavioral Ecology, \doi{10.1093/beheco/arx133}


coldist <- function(modeldata,
                    noise = c("neural", "quantum"), subset = NULL,
                    achromatic = FALSE, qcatch = NULL,
                    n = c(1, 2, 2, 4), weber = 0.1, weber.ref = "longest",
                    weber.achro = 0.1) {

  # Prepare output
  pairsid <- t(combn(nrow(modeldata), 2))

  # Prepare pairwise combinations of stimuli for output
  res <- as.data.frame(matrix(rownames(modeldata)[pairsid],
                              ncol = 2, dimnames = list(NULL, c("patch1", "patch2"))
  ), stringsAsFactors = FALSE)

  res[, "dS"] <- NA # Chromatic contrasts
  if (achromatic) { # Achromatic contrasts
    res[, "dL"] <- NA
  }

  noise <- match.arg(noise)

  usereceptornoisemodel <- !inherits(modeldata, "colspace")

  if (noise == "quantum") {
    if (!is.vismodel(modeldata) && !is.colspace(modeldata)) {
      stop("Object must be of class vismodel or colspace to calculate quantum receptor noise model", call. = FALSE)
    }
  }

  ncone <- attr(modeldata, "conenumb")

  if (isTRUE(attr(modeldata, "relative"))) {
    message("Quantum catch are relative, distances may not be meaningful")
  }

  # Pre-processing for colspace objects
  if (is.colspace(modeldata) || is.vismodel(modeldata)) {
    qcatch <- attr(modeldata, "qcatch")
    # Pre-processing for vismodel objects
    if (is.vismodel(modeldata)) {
      if (qcatch == "Ei") {
        stop("Receptor-noise model not compatible with hyperbolically transformed quantum catches (Ei)", call. = FALSE)
      }
    }
    # Convert lum values to 0 instead of NA, for convenient
    # processing. Converted back to NA at the end.
    if (attr(modeldata, "visualsystem.achromatic") == "none" && !(any(c("CIELAB", "CIELCh") %in% attr(modeldata, "clrsp")))
        || is.null(attr(modeldata, "visualsystem.achromatic"))) {
      modeldata$lum <- 0
      if (achromatic) {
        message("achromatic = TRUE but visual model was calculated with achromatic = ",
                dQuote("none"), "; achromatic contrast not calculated."
        )
      }
      achromatic <- FALSE
    }
  }

  # Transformations in case object is neither from colspace or vismodel. Changed
  # warnings to messages, since there's no way to directly specify 'ncone' when using
  # custom data you'd always get scary warnings.
  if (is.null(ncone)) {
    if (achromatic) {
      ncone <- ncol(modeldata) - 1
      message(
        "Number of cones assumed to be ", ncone,
        " (last column ignored for chromatic contrast, used only for achromatic contrast)"
      )
    } else {
      # Don't count all-NA columns when guessing ncone
      # FIXME: this only works if there is a single all-NA column. But we have
      # no guarantee this will always be the case
      if (any(sapply(modeldata, function(x) all(is.na(x))))) {
        ncone <- ncol(modeldata) - 1
      } else {
        ncone <- ncol(modeldata)
      }
      message("Number of cones assumed to be ", ncone)
    }
  }

  if (is.null(qcatch)) {
    stop("Scale of quantum catches not defined (Qi or fi in argument qcatch).",
         call. = FALSE
    )
  }

  if (usereceptornoisemodel) {

    #########################
    # Receptor Noise Models #
    #########################

    # should be used when:
    # - colspace object: never
    # - vismodel object: always
    # - user input data: always

    note_dS <- "Calculating noise-weighted Euclidean distances"
    note_dL <- NULL

    dat <- as.matrix(modeldata)
    rownames(dat) <- rownames(modeldata)
    colnames(dat) <- colnames(modeldata)

    # Ensure catches are log transformed
    dat <- switch(qcatch,
                  fi = dat,
                  Qi = log(dat)
    )
    # Quantum catch models need Qi in original scale (not log transformed)
    # to calculate the noise. Save as qndat object.
    qndat <- switch(qcatch,
                    Qi = dat,
                    fi = exp(dat)
    )

    # Keep only cone-catch data
    dat2 <- dat[, seq_len(ncone), drop = FALSE]

    if (is.numeric(weber.ref) && weber.ref > length(n)) {
      stop("reference cone class for the empirical estimate of the Weber fraction (",
           dQuote("weber ref"),
           ") is greater than the length of vector of relative cone densities (",
           dQuote("n"), ")",
           call. = FALSE
      )
    }

    # Set weber cone reference
    if (weber.ref == "longest") {
      weber.ref <- length(n)
    }

    if (length(n) != ncone) {
      stop("vector of relative cone densities (", dQuote("n"),
           ") has a different length than the number of cones (columns) used for the visual model",
           call. = FALSE
      )
    }

    # CREATE REFERENCE OBJECTS FOR CARTESIAN TRANSFORMATION
    refsamp <- min(dim(dat2)[1], ncone)

    visref <- matrix(NA,
                     ncol = ncone,
                     nrow = refsamp + ncone + 1,
                     dimnames = list(
                       c(
                         rownames(dat2)[seq(refsamp)],
                         paste0("jnd2xyzrrf.", c("achro", colnames(dat2)))
                       ),
                       colnames(dat2)
                     )
    )

    rrf <- diag(9, ncone)
    rrf[lower.tri(rrf)] <- 0.001
    rrf[upper.tri(rrf)] <- 0.001

    rrf <- log(rrf)

    visref[seq(refsamp), ] <- dat2[seq(refsamp), ]
    visref[refsamp + 1, ] <- log(1e-10)
    visref[-seq(refsamp + 1), ] <- rrf

    resref <- as.data.frame(matrix(rownames(visref)[t(combn(nrow(visref), 2))],
                                   ncol = 2, dimnames = list(NULL, c("patch1", "patch2"))
    ), stringsAsFactors = FALSE)
    resref[, "dS"] <- NA
    if (achromatic) {
      resref[, "dL"] <- NA
    }

    ## Calculate dS
    res[, "dS"] <- switch(noise,
                          "neural" = newreceptornoise(dat2, n, weber, weber.ref, res),
                          "quantum" = newreceptornoise(dat2, n, weber, weber.ref, res, qndat[, seq_len(ncone)])
    )
    resref[, "dS"] <- switch(noise,
                             "neural" = newreceptornoise(visref, n, weber, weber.ref, resref),
                             "quantum" = newreceptornoise(visref, n, weber, weber.ref, resref, exp(visref))
    )

    ## Calculate dL
    if (achromatic) {
      note_dL <- " and noise-weighted luminance contrasts"
      visref <- cbind(visref, lum = log(1e-10))
      visref[grep("jnd2xyzrrf", rownames(visref), invert = TRUE, fixed = TRUE), "lum"] <-
        dat[seq(refsamp), dim(dat)[2]]

      res[, "dL"] <- switch(noise,
                            "neural" = unlist(lapply(seq_len(nrow(res)), function(x) {
                              ttdistcalcachro(
                                dat[res[x, 1], ], dat[res[x, 2], ],
                                NULL, NULL, weber.achro
                              )
                            })),
                            "quantum" = unlist(lapply(seq_len(nrow(res)), function(x) {
                              ttdistcalcachro(
                                dat[res[x, 1], ], dat[res[x, 2], ],
                                qndat[res[x, 1], ], qndat[res[x, 2], ], weber.achro
                              )
                            }))
      )

      resref[, "dL"] <- switch(noise,
                               "neural" = unlist(lapply(seq_len(nrow(resref)), function(x) {
                                 ttdistcalcachro(
                                   visref[resref[x, 1], ], visref[resref[x, 2], ],
                                   NULL, NULL,
                                   weber.achro = weber.achro
                                 )
                               })),
                               "quantum" = unlist(lapply(seq_len(nrow(resref)), function(x) {
                                 ttdistcalcachro(
                                   visref[resref[x, 1], ], visref[resref[x, 2], ],
                                   exp(visref)[resref[x, 1], ], exp(visref)[resref[x, 2], ], weber.achro
                                 )
                               }))
      )

      if (dim(dat)[2] <= ncone) {
        warning(
          "achromatic is set to TRUE, but input data has the same number of columns for sensory data as number of cones in the visual system. ",
          "There is no column in the data that represents an exclusively achromatic channel, so the last column of the sensory data is being used. ",
          "Treat achromatic results with caution, and check if this is the desired behavior.", call. = FALSE
        )
      }
    }
    message(note_dS, note_dL)
  } else {
    dat <- as.matrix(modeldata[, sapply(modeldata, is.numeric)])

    # Message about the distances being calculated
    note_dS <- switch(attr(modeldata, "clrsp"),
                      "dispace" = ,
                      "trispace" = ,
                      "tcs" = ,
                      "hexagon" = ,
                      "categorical" = ,
                      "CIEXYZ" = ,
                      "segment" = "Calculating unweighted Euclidean distances",
                      "CIELAB" = ,
                      "CIELCh" = "Calculating CIE2000 distances",
                      "coc" = "Calculating Manhattan distances"
    )
    note_dL <- NULL

    res[, "dS"] <- switch(attr(modeldata, "clrsp"),
                          "dispace" = apply(pairsid, 1, function(x) dist(rbind(dat[x[1], "x"], dat[x[2], "x"]))),
                          "tcs" = apply(pairsid, 1, function(x) dist(rbind(dat[x[1], c("x", "y", "z")], dat[x[2], c("x", "y", "z")]))),
                          "trispace" = ,
                          "hexagon" = ,
                          "CIEXYZ" = ,
                          "categorical" = apply(pairsid, 1, function(x) dist(rbind(dat[x[1], c("x", "y")], dat[x[2], c("x", "y")]))),
                          "segment" = apply(pairsid, 1, function(x) dist(rbind(dat[x[1], c("MS", "LM")], dat[x[2], c("MS", "LM")]))),
                          "CIELAB" = ,
                          "CIELCh" = apply(pairsid, 1, function(x) {
                            d <- as.data.frame(dat)
                            compare_colour(d[x[1], c("L", "a", "b")], d[x[2], c("L", "a", "b")], from_space = "lab", method = "cie2000")
                          }),
                          "coc" = apply(pairsid, 1, function(x) dist(rbind(dat[x[1], c("x", "y")], dat[x[2], c("x", "y")]), method = "manhattan"))
    )
    if (achromatic) {
      note_dL <- switch(attr(modeldata, "clrsp"),
                        "dispace" = ,
                        "trispace" = ,
                        "tcs" = " and Weber luminance contrast",
                        "hexagon" = " and simple luminance contrast",
                        "segment" = " and Michelson luminance contrast",
                        "CIELAB" = ,
                        "categorical" = ,
                        "coc" = ,
                        "CIELCh" = " and Weber luminance contrast",
      )

      res[, "dL"] <- switch(attr(modeldata, "clrsp"),
                            "dispace" = ,
                            "trispace" = ,
                            "categorical" = ,
                            "coc" = ,
                            "tcs" = lumcont(dat[pairsid[, 1], "lum"], dat[pairsid[, 2], "lum"], type = "weber"),
                            "hexagon" = lumcont(dat[pairsid[, 1], "l"], dat[pairsid[, 2], "l"], type = "simple"),
                            "CIELAB" = ,
                            "CIELCh" = lumcont(dat[pairsid[, 1], "L"], dat[pairsid[, 2], "L"], type = "weber"),
                            "segment" = lumcont(dat[pairsid[, 1], "B"], dat[pairsid[, 2], "B"], type = "michelson")
      )
    }
    message(note_dS, note_dL)
  }

  # Subsetting samples
  if (length(subset) > 2) {
    stop("Too many subsetting conditions; one or two allowed.", call. = FALSE)
  }

  if (length(subset) == 1) {
    condition1 <- grep(subset, res$patch1)
    condition2 <- grep(subset, res$patch2)
    subsamp <- unique(c(condition1, condition2))
    res <- res[subsamp, ]
  }

  if (length(subset) == 2) {
    condition1 <- intersect(
      grep(subset[1], res$patch1),
      grep(subset[2], res$patch2)
    )

    condition2 <- intersect(
      grep(subset[2], res$patch1),
      grep(subset[1], res$patch2)
    )

    subsamp <- unique(c(condition1, condition2))
    res <- res[subsamp, ]
    row.names(res) <- NULL
  }

  if (exists("resref", inherits = FALSE)) {
    attr(res, "resref") <- resref
  }

  # Set achro contrasts to NA if no lum values supplied
  if (((is.vismodel(modeldata) || is.colspace(modeldata)) && attr(modeldata, "visualsystem.achromatic") == "none") || !(achromatic)) {
    res$dL <- NA
  }

  # if (attr(modeldata, "visualsystem.achromatic") == "none" || !(achromatic)) {
  #   res$dL <- NA
  # }

  attr(res, "ncone") <- ncone
  attr(res, "isrnoise") <- usereceptornoisemodel

  res
}

##################################
# START RECEPTOR NOISE FUNCTIONS #
##################################

newreceptornoise <- function(qcatch_raw, n, weber, weber.ref, res, qcatch_log = NULL) {

  # Calculate relative receptor density
  reln <- n / sum(n)

  # Back-calculate photoreceptor noise from channel-noise (weber fraction)
  if (length(weber) == length(n)) { # For when weber is known for all receptors
    v <- weber * sqrt(reln)
  } else {
    v <- weber * sqrt(reln[weber.ref])
  } # When weber is known for one receptor (typical)

  if (is.null(qcatch_log)) {
    e <- setNames(v / sqrt(reln), colnames(qcatch_raw))
  } else {
    # Negative qcatch check
    if (any(qcatch_log < 0)) {
      stop(
        length(qcatch_log[qcatch_log < 0]),
        " negative quantum-catch value(s) returned following log-transformation, as required when noise = 'quantum',
        so distances cannot be calculated. This typically results from very small raw quantum catches estimates (< 1).",
        "Consider whether the illuminant is properly scaled, and the appropriate",
        " form of noise is being calculated."
      )
    }
    ept1 <- setNames(v^2 / reln, colnames(qcatch_raw))
    ept2 <- 2 / t(apply(res, 1, function(x) qcatch_log[x[1], ] + qcatch_log[x[2], ]))
    e <- sqrt(sweep(ept2, 2, ept1, "+"))
  }

  ###############
  # NUMERATOR #
  ###############

  # all n-2 combinations (first part numerator)
  n1combs <- combn(colnames(qcatch_raw), dim(qcatch_raw)[2] - 2)

  if (is.null(qcatch_log)) {
    # get those combinations of ei and prod(ei)^2
    num1 <- setNames(
      apply(n1combs, 2, function(x) prod(e[x])),
      apply(n1combs, 2, paste, collapse = "")
    )
  } else {
    # get those combinations of ei and prod(ei)^2
    num1 <- do.call("rbind", lapply(seq_len(dim(res)[1]), function(z) {
      apply(n1combs, 2, function(x) prod(e[z, x]))
    }))
    colnames(num1) <- apply(n1combs, 2, paste, collapse = "")
  }

  # remaining 2 combinations (second part numerator)
  n2combs <- apply(n1combs, 2, function(x) colnames(qcatch_raw)[!colnames(qcatch_raw) %in% x])

  # f_d and f_e
  deltaqiqj <- lapply(seq_len(dim(n1combs)[2]), function(y) {
    t(apply(res, 1, function(x) {
      qcatch_raw[x[1], n2combs[, y]] - qcatch_raw[x[2], n2combs[, y]]
    }))
  })
  names(deltaqiqj) <- apply(n2combs, 2, paste, collapse = "")

  # (f_d-f_e)^2
  num2 <- do.call(cbind, lapply(deltaqiqj, function(x) x[, 1] - x[, 2]))

  # (e_abc)^2*(f_d-f_e)^2
  if (is.null(qcatch_log)) {
    etimesq <- num2 %*% diag(num1)
  } else {
    etimesq <- num2 * num1
  }

  # sum numerator
  numerator <- rowSums(etimesq^2)

  ###############
  # DENOMINATOR #
  ###############

  # all n-1 combinations
  dcombs <- combn(colnames(qcatch_raw), dim(qcatch_raw)[2] - 1)

  if (is.null(qcatch_log)) {
    den <- setNames(
      apply(dcombs, 2, function(x) prod(e[x])),
      apply(dcombs, 2, paste, collapse = "")
    )
    denominator <- sum(den^2)
  } else {
    den <- do.call("rbind", lapply(seq_len(dim(res)[1]), function(z) {
      apply(dcombs, 2, function(x) prod(e[z, x]))
    }))
    colnames(den) <- apply(dcombs, 2, paste, collapse = "")
    denominator <- rowSums(den^2)
  }
  sqrt(numerator / denominator) # DELTA S
}

# Achromatic function
ttdistcalcachro <- function(f1, f2, qn1 = NULL, qn2 = NULL, weber.achro) {
  dq1 <- f1[length(f1)] - f2[length(f1)]
  dq1 <- as.numeric(dq1)
  if (is.null(qn1)) {
    w <- weber.achro
  } else {
    w <- sqrt((weber.achro)^2 + (2 / (qn1[length(qn1)] + qn2[length(qn1)])))
  }
  round(abs(dq1 / w), 7)
}


################################
# END RECEPTOR NOISE FUNCTIONS #
################################

#########################
# START OTHER DISTANCES #
#########################

# Luminance contrast
lumcont <- function(coord1, coord2, type = c("simple", "weber", "michelson")) {
  contrast <- match.arg(type)

  dLout <- switch(contrast,
                  "simple" = coord1 / coord2,
                  "weber" = (pmax(coord1, coord2) - pmin(coord1, coord2)) / pmin(coord1, coord2),
                  "michelson" = (pmax(coord1, coord2) - pmin(coord1, coord2)) / (pmax(coord1, coord2) + pmin(coord1, coord2))
  )
  dLout
}

#######################
# END OTHER DISTANCES #
#######################
