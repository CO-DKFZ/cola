\name{dimension_reduction-matrix-method}
\alias{dimension_reduction,matrix-method}
\title{
Visualize columns after dimension reduction
}
\description{
Visualize columns after dimension reduction
}
\usage{
\S4method{dimension_reduction}{matrix}(object,
    pch = 16, col = "black", cex = 1, main = "",
    method = c("PCA", "MDS", "t-SNE", "UMAP"),
    control = list(),
    scale_rows = TRUE,
    internal = FALSE, verbose = TRUE)
}
\arguments{

  \item{object}{a numeric matrix.}
  \item{method}{which method to reduce the dimension of the data. \code{MDS} uses \code{\link[stats]{cmdscale}}, \code{PCA} uses \code{\link[stats]{prcomp}}. \code{t-SNE} uses \code{\link[Rtsne]{Rtsne}}. \code{UMAP} uses \code{\link[umap]{umap}}.}
  \item{control}{a list of parameters for \code{\link[Rtsne]{Rtsne}} or \code{\link[umap]{umap}}.}
  \item{pch}{shape of points.}
  \item{col}{color of points.}
  \item{cex}{size of points.}
  \item{main}{title of the plot.}
  \item{scale_rows}{whether perform scaling on matrix rows.}
  \item{internal}{internally used.}
  \item{verbose}{whether print messages.}

}
\value{
No value is returned.
}
\author{
Zuguang Gu <z.gu@dkfz.de>
}
\examples{
# There is no example
NULL
}
