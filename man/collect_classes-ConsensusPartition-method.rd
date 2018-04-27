\name{collect_classes-ConsensusPartition-method}
\alias{collect_classes,ConsensusPartition-method}
\title{
Collect classes from ConsensusPartitionList object
}
\description{
Collect classes from ConsensusPartitionList object
}
\usage{
\S4method{collect_classes}{ConsensusPartition}(object, internal = FALSE)
}
\arguments{

  \item{object}{a \code{\link{ConsensusPartitionList-class}} object.}
  \item{internal}{used internally.}

}
\details{
Membership matrix and the classes with each k are plotted in the heatmap.
}
\value{
No value is returned.
}
\author{
Zuguang Gu <z.gu@dkfz.de>
}
\examples{
data(cola_rl)
collect_classes(cola_rl["sd", "kmeans"])
}
