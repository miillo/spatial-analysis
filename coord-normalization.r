longNorm <- function(y) {
  if (!is.na(y) && y > 18000) {
    (y - 36000) / 100
  } else {
    y / 100  
  }
}

latNorm <- function(x) {
  x / 100
}

wNorm <- function(x) {
  x / 10
}