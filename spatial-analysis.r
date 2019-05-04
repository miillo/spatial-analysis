library(rworldmap)

##### Data preprocessing #####
# Reading source data 
sourceData = read.fwf("CLIWOC21CORE.txt", widths = c(4,2,2,4,5,6,2,1,1,1,1,1,2,2,9,2,1,3,1,3,1,2,2,1,5,1,3,1,4,1,4,1,4,2,4,1,1,1,1,1,1,1,2,2,2,2,2,2), 
                                          col.names =  c("YR","MO","DY","HR","LAT","LON","IM","ATTC","TI","LI","DS","VS","NID","II","ID","C1","DI","D","WI","W","VI","VV","WW","W1","SLP","A","PPP","IT","AT","WBTI","WBT","DPTI","DPT","SI","SST","N","NH","CL","HI","H","CM","CH","WD","WP","WH","SD","SP","SH"))

# Normalizing longitude / latitude
source("coord-normalization.r")

sourceData <- transform(sourceData, LAT = latNorm(sourceData$LAT))
sourceData <- transform(sourceData, LON = longNorm(sourceData$LON))

#####  #####
map <- getMap(resolution = 'low')
# tutaj sa zakresy wspolrzednych mapy swiata rysowanej przez rworldmap
map@bbox
plot(map)                                          

# naniesienie punktow na mape swiata
points(sourceData$LON, sourceData$LAT, col = "red", cex = .6)
