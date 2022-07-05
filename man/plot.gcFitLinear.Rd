% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/growth_plots.R
\name{plot.gcFitLinear}
\alias{plot.gcFitLinear}
\title{Plot the results of a linear regression on ln-transformed data}
\usage{
\method{plot}{gcFitLinear}(
  gcFittedLinear,
  log = "y",
  which = c("fit", "diagnostics"),
  plot = TRUE,
  export = FALSE,
  height = ifelse(which == "fit", 7, 5),
  width = ifelse(which == "fit", 9, 9),
  out.dir = NULL,
  ...
)
}
\arguments{
\item{gcFittedLinear}{A \code{gcFittedLinear} object created with \code{growth.gcFitLinear()} or stored within a \code{grofit} or \code{gcFit} object created with \code{growth.workflow()} or \code{growth.gcFit()}, respectively.}

\item{log}{("x" or "y") Display the x- or y-axis on a logarithmic scale.}

\item{which}{("fit" or "diagnostics") Display either the results of the linear fit on the raw data or statistical evaluation of the linear regression.}

\item{plot}{(Logical) Show the generated plot in the \code{Plots} pane (\code{TRUE}) or not (\code{FALSE}).}

\item{export}{(Logical) Export the generated plot as PDF and PNG files (\code{TRUE}) or not (\code{FALSE}).}

\item{height}{(Numeric) Height of the exported image in inches.}

\item{width}{(Numeric) Width of the exported image in inches.}

\item{out.dir}{(Character) Name or path to a folder in which the exported files are stored. If \code{NULL}, a "Plots" folder is created in the current working directory to store the files in.}

\item{...}{Further arguments to refine the generated base R plot.}
}
\description{
\code{plot.gcFitLinear} shows the results of a linear regression on log-transformed data and visualizes raw data, data points included in the fit, the tangent obtained by linear regression, and the lag time.
}