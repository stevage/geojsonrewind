#' rewind
#'
#' @export
#' @param x A geojson object, either as list, character string, or json
#' class
#' @param outer (logical) clockwise (\code{TRUE}, default) or
#' counterclockwise (\code{FALSE})
#' @details ported from \code{geojson-rewind} JS library at
#' \url{https://github.com/mapbox/geojson-rewind}
#' @return a geojson object, as json/character class
#' @examples
#' x <- '{
#'  "type":"Polygon",
#'  "coordinates":[
#'    [[100.0,0.0],[100.0,1.0],[101.0,1.0],[101.0,0.0],[100.0,0.0]]
#'  ]
#' }'
#' rewind(x)
#' rewind(x, outer = FALSE)
rewind <- function(x, outer = TRUE) {
  UseMethod("rewind")
}

#' @export
rewind.default <- function(x, outer = TRUE) {
  stop("no 'rewind' method for ", class(x), call. = FALSE)
}

#' @export
rewind.character <- function(x, outer = TRUE) {
  x <- jsonlite::fromJSON(x, FALSE)
  rewind_(x, outer)
}

#' @export
rewind.list <- function(x, outer = TRUE) {
  rewind_(x, outer)
}

#' @export
rewind.json <- function(x, outer = TRUE) {
  rewind(unclass(x), outer)
}

rewind_ <- function(x, outer) {
  jsonlite::toJSON(switch(
    x$type,
    FeatureCollection = {
      x$features <- x$features.map(curry_outer(rewind, outer))
      return(x)
    },
    Feature = {
      x$geometry <- rewind(x$geometry, outer)
      return(x)
    },
    Polygon = correct(x, outer),
    MultiPolygon = correct(x, outer),
    return(x)
  ), auto_unbox = TRUE)
}

curry_outer <- function(a, b) {
  function(x) {
    eval(a)(x, b)
  }
}

correct <- function(x, outer) {
  if (x$type == "Polygon") {
    x$coordinates <- correct_rings(x$coordinates, outer)
  } else if (x$type == "MultiPolygon") {
    x$coordinates <- Map(function(z) curry_outer(correct_rings, outer), x$coordinates)
  }
  return(x)
}

correct_rings <- function(x, outer) {
  x[[1]] <- wind(x[[1]], !outer)
  for (i in seq_along(x)[-length(x)]) {
    x[[i]] <- wind(x[[i]], outer)
  }
  return(x)
}

wind <- function(x, dir) {
  if (cw(x) == dir) x else rev(x)
}

cw <- function(x) {
  ring_area(x) >= 0
}
