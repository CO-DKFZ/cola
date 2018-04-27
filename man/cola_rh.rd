\name{cola_rh}
\docType{data}
\alias{cola_rh}
\title{
Example for HierarchicalPartition object
}
\description{
Example for HierarchicalPartition object
}
\usage{
data(cola_rh)
}
\details{
Following code was used to generate these two examples:

  \preformatted{
  set.seed(123)
  m = cbind(rbind(matrix(rnorm(20*20, mean = 1,   sd = 0.5), nr = 20),
                  matrix(rnorm(20*20, mean = 0,   sd = 0.5), nr = 20),
                  matrix(rnorm(20*20, mean = 0,   sd = 0.5), nr = 20)),
            rbind(matrix(rnorm(20*20, mean = 0,   sd = 0.5), nr = 20),
                  matrix(rnorm(20*20, mean = 1,   sd = 0.5), nr = 20),
                  matrix(rnorm(20*20, mean = 0,   sd = 0.5), nr = 20)),
            rbind(matrix(rnorm(20*20, mean = 0.5, sd = 0.5), nr = 20),
                  matrix(rnorm(20*20, mean = 0.5, sd = 0.5), nr = 20),
                  matrix(rnorm(20*20, mean = 1,   sd = 0.5), nr = 20))
           ) + matrix(rnorm(60*60, sd = 0.5), nr = 60)
  cola_rh = hierarchical_partition(m, top_n = c(20, 30, 40))  }
}
\author{
Zuguang Gu <z.gu@dkfz.de>
}
\examples{
data(cola_rh)
cola_rh
}
