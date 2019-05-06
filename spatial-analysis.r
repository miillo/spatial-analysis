library(rworldmap)

##### Data preprocessing #####
# Reading source data 

## core
sourceData = read.fwf("CLIWOC21CORE.txt", widths = c(4,2,2,4,5,6,2,1,1,1,1,1,2,2,9,2,1,3,1,3,1,2,2,1,5,1,3,1,4,1,4,1,4,2,4,1,1,1,1,1,1,1,2,2,2,2,2,2), 
                                          col.names =  c("YR","MO","DY","HR","LAT","LON","IM","ATTC","TI","LI","DS","VS","NID","II","ID","C1","DI","D","WI","W","VI","VV","WW","W1","SLP","A","PPP","IT","AT","WBTI","WBT","DPTI","DPT","SI","SST","N","NH","CL","HI","H","CM","CH","WD","WP","WH","SD","SP","SH"))

# Normalizing longitude / latitude
source("coord-normalization.r")

sourceDataNorm <- transform(sourceData, LAT = latNorm(sourceData$LAT), LON = map(sourceData$LON, longNorm))

#####  #####
map <- getMap(resolution = 'low')
plot(map)                                          

# naniesienie punktow na mape swiata
points(sourceDataNorm$LON, sourceDataNorm$LAT, col = "red", cex = .1)