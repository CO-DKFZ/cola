\name{enrich_signatures_to_genesets}
\alias{enrich_signatures_to_genesets}
\title{
Enrich signature genes to genesets
}
\description{
Enrich signature genes to genesets
}
\usage{
enrich_signatures_to_genesets(x, genesets, map = NULL, bg, min_count = 50, max_count = 5000,
    fdr_cutoff1 = 0.05, fdr_cutoff2 = 0.5)
}
\arguments{

  \item{x}{the object returned from \code{\link{get_signatures}}}
  \item{map}{mapping between rows of \code{x$mat} and genes in \code{genesets}}
  \item{bg}{background gene list}
  \item{genesets}{a object constructed from \code{\link{msigdb_catalogue}}}
  \item{min_count}{minimal number of genes in genesets}
  \item{max_count}{maximal number of genes in genesets}
  \item{fdr_cutoff1}{cutoff of FDR for the geneset to be significantly enriched}
  \item{fdr_cutoff2}{cutoff of RDR for the geneset to be not enriched}

}
\details{
The function tries to find significantly enriched genesets which at the same time
are also subgroup specific.
}
\value{
A list with significant genesets in each subgroup
}
\author{
Zuguang Gu <z.gu@dkfz.de>
}
\examples{
# There is no example
NULL

}