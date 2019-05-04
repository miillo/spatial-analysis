longNorm <- function(y) {
  ((y - 0) * (180 - -180)) / (36000 - 0) + -180
}

latNorm <- function(x) {
  ((x - -7200) * (83 - -90)) / (8100 - -7200) + -90
}