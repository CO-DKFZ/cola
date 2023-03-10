\name{dimension_reduction-ConsensusPartition-method}
\alias{dimension_reduction,ConsensusPartition-method}
\title{
Visualize column after dimension reduction
}
\description{
Visualize samples (the matrix columns) after dimension reduction
}
\usage{
\S4method{dimension_reduction}{ConsensusPartition}(object, k, top_n = NULL,
    method = c("PCA", "MDS", "t-SNE", "UMAP"),
    control = list(), color_by = NULL,
    internal = FALSE, nr = 5000,
    silhouette_cutoff = 0.5, remove = FALSE,
    scale_rows = object@scale_rows, verbose = TRUE, ...)
}
\arguments{

  \item{object}{A \code{\link{ConsensusPartition-class}} object.}
  \item{k}{Number of subgroups.}
  \item{top_n}{Top n rows to use. By default it uses all rows in the original matrix.}
  \item{method}{Which method to reduce the dimension of the data. \code{MDS} uses \code{\link[stats]{cmdscale}}, \code{PCA} uses \code{\link[stats]{prcomp}}. \code{t-SNE} uses \code{\link[Rtsne]{Rtsne}}. \code{UMAP} uses \code{\link[umap]{umap}}.}
  \item{color_by}{If annotation table is set, an annotation name can be set here.}
  \item{control}{A list of parameters for \code{\link[Rtsne]{Rtsne}} or \code{\link[umap]{umap}}.}
  \item{internal}{Internally used.}
  \item{nr}{If number of matrix rows is larger than this value, random \code{nr} rows are used.}
  \item{silhouette_cutoff}{Cutoff of silhouette score. Data points with values less than it will be mapped with cross symbols.}
  \item{remove}{Whether to remove columns which have less silhouette scores than the cutoff.}
  \item{scale_rows}{Whether to perform scaling on matrix rows.}
  \item{verbose}{Whether print messages.}
  \item{...}{Pass to \code{\link{dimension_reduction,matrix-method}}.}

}
\value{
Locations of the points.
}
\author{
Zuguang Gu <z.gu@dkfz.de>
}
\examples{
data(golub_cola)
dimension_reduction(golub_cola["ATC", "skmeans"], k = 3)
}
