##### Data preprocessing #####
# dla porzadku mozna nazwac kolumny

sourceData = read.fwf("CLIWOC21CORE.txt", widths = c(4,2,2,4,5,6,2,1,1,1,1,1,2,2,9,2,1,3,1,3,1,2,2,1,5,1,3,1,4,1,4,1,4,2,4,1,1,1,1,1,1,1,2,2,2,2,2,2))
                                          select(d,1,2,3,4,5,6,14,15,16,18,19,20,25,28,29,35)

#####  #####
