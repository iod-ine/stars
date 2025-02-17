# reduce resolution of x, keeping (most of) extent
#' @export
#' @name st_downsample
st_downsample = function(x, n, ...) UseMethod("st_downsample")

#' downsample stars or stars_proxy object by skipping rows, columns and bands
#' 
#' @param x object of class stars or stars_proxy
#' @param n numeric; the number of pixels/lines/bands etc that will be skipped; see Details.
#' @param ... ignored
#' @details If all n == 0, no downsampling takes place; if it is 1, every second row/column/band
#' is skipped, if it is 2, every second+third row/column/band are skipped, etc.
#' 
#' Downsampling a \code{stars_proxy} object returns a \code{stars} object, is
#' equivalent to calling \code{st_as_stars(x, downsample = 2)}, and only downsamples
#' the first two (x and y) dimensions.
#'
#' Downsampled regular rasters keep their dimension offsets, have a cell size (delta) that
#' is n[i]+1 times larger, and may result in a (slightly) different extent.
#' @name st_downsample
#' @export
st_downsample.stars = function(x, n, ...) {
	n = as.integer(n)
	stopifnot(all(n >= 0))
	if (!all(n == 0)) {
		d = dim(x)
		n = rep(n, length.out = length(d))
		dims = st_dimensions(x)
		regular = is_regular_grid(x)
		args = rep(list(rlang::missing_arg()), length(d)+1)
		for (i in seq_along(d)) {
			if (n[i] > 0) {
				sq = seq(1, d[i], n[i] + 1)
				args[[i+1]] = sq
				# $values:
				if (!is.null(dims[[i]]$values))
					dims[[i]]$values = dims[[i]]$values[sq]
			}
		}
		x = eval(rlang::expr(x[!!!args]))
		if (regular) {
			d_new = st_dimensions(x)
			for (i in seq_along(d)) {
				dims[[i]]$delta = dims[[i]]$delta * (n[i] + 1)
				dims[[i]]$from = d_new[[i]]$from
				dims[[i]]$to = d_new[[i]]$to
			}
			x = structure(x, dimensions = dims)
		}
	}
	x
}

#' @export
#' @name st_downsample
st_downsample.stars_proxy = function(x, n, ...) {
	if (length(n) != 2)
		message("for stars_proxy objects, downsampling only happens for dimensions x and y")
	st_as_stars(x, downsample = n)
}


#' @export
st_sample.stars = function(x, size, ..., type = "random", replace = FALSE) {
	if (length(x) > 1)
		warning("only sampling the first attribute")
	if (type != "random")
		warning("only type 'random' supported")
	v = structure(x[[1]], dim = NULL)
	if (missing(replace))
		replace = size > length(v)
	v[sample(length(v), size, replace = replace, ...)]
}

#' @export
st_sample.stars_proxy = function(x, size, ..., type = "regular", quiet = TRUE) {
	if (type != "regular")
		stop("only type 'regular' for stars_proxy objects supported") # FIXME: tbd
	d = dim(x)
	downsampling_rate = c(floor(d[1:2] / sqrt(size)), d[-(1:2)])
	if (!quiet)
		print(downsampling_rate) # nocov
	st_as_stars(x, downsample = downsampling_rate)
	# st_sample(st, size, ...)
}
