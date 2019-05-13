\name{get_param-ConsensusPartition-method}
\alias{get_param,ConsensusPartition-method}
\title{
Get parameters
}
\description{
Get parameters
}
\usage{
\S4method{get_param}{ConsensusPartition}(object, k = object@k, unique = TRUE)
}
\arguments{

  \item{object}{a \code{\link{ConsensusPartition-class}} object.}
  \item{k}{number of partitions.}
  \item{unique}{whether apply \code{\link[base]{unique}} to rows of the returned data frame.}

}
\details{
It is mainly used internally.
}
\value{
A data frame of parameters corresponding to the current k. In the data frame, each row corresponds
to a partition run.
}
\author{
Zuguang Gu <z.gu@dkfz.de>
}
\examples{
data(cola_rl)
obj = cola_rl["sd", "kmeans"]
get_param(obj)
get_param(obj, k = 2)
get_param(obj, unique = FALSE)
}
\alias{get_param}
