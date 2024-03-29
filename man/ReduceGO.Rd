% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/objects.R
\name{ReduceGO}
\alias{ReduceGO}
\alias{ReduceGO,scDiffCom-method}
\title{Reduce scDiffCom GO Terms}
\usage{
ReduceGO(
  object,
  method = c("Rel", "Resnik", "Lin", "Jiang", "Wang"),
  threshold = 0.7
)

\S4method{ReduceGO}{scDiffCom}(
  object,
  method = c("Rel", "Resnik", "Lin", "Jiang", "Wang"),
  threshold = 0.7
)
}
\arguments{
\item{object}{\code{scDiffCom} object}

\item{method}{A distance method supported by rrvgo and GOSemSim:
c("Rel", "Resnik", "Lin", "Jiang", "Wang")}

\item{threshold}{Similarity threshold used by \code{rrvgo::reduceSimMatrix}}
}
\value{
A data.table of GO terms with their reduction
}
\description{
Perform semantic similarity analysis and reduction of the
 overrepresented GO terms of an scDiffCom object.
}
\details{
This function is basically a wrapper around \code{rrvgo::calculateSimMatrix}
 and \code{rrvgo::reduceSimMatrix}.
}
