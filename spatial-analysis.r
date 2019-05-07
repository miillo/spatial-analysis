library(rworldmap)
library(dplyr)
library(purrr)

##### Data preprocessing #####
# Reading source data 
sourceData = read.fwf("CLIWOC21CORE.txt", widths = c(4,2,2,4,5,6,2,1,1,1,1,1,2,2,9,2,1,3,1,3,1,2,2,1,5,1,3,1,4,1,4,1,4,2,4,1,1,1,1,1,1,1,2,2,2,2,2,2), 
                                          col.names =  c("YR","MO","DY","HR","LAT","LON","IM","ATTC","TI","LI","DS","VS","NID","II","ID","C1","DI","D","WI","W","VI","VV","WW","W1","SLP","A","PPP","IT","AT","WBTI","WBT","DPTI","DPT","SI","SST","N","NH","CL","HI","H","CM","CH","WD","WP","WH","SD","SP","SH"))

# Normalizing longitude / latitude
source("coord-normalization.r")
sourceDataNorm <- transform(sourceData, LAT = latNorm(sourceData$LAT), LON = as.integer(map(sourceData$LON, longNorm)))

##### Presenting source data #####
map <- getMap(resolution = 'low')
plot(map)                                          

# drawing all routes on world map
points(sourceDataNorm$LON, sourceDataNorm$LAT, pch = 1,  col = "red", cex = .6)

# choosing routes by country 
spainRoutes <- sqldf::sqldf("SELECT LON,LAT,C1 from sourceData WHERE C1 == 'ES' AND LAT!='NA' AND LON!='NA'")
franceRoutes<-sqldf::sqldf("SELECT LON,LAT,C1 from sourceDataNorm  WHERE C1=='FR' AND LAT!='NA' AND LON!='NA'")
netherlandsRoutes<-sqldf::sqldf("SELECT LON,LAT,C1 from sourceDataNorm  WHERE C1=='NL' AND LAT!='NA' AND LON!='NA'")
englandRoutes<-sqldf::sqldf("SELECT LON,LAT,C1 from sourceDataNorm  WHERE C1=='UK' AND LAT!='NA' AND LON!='NA'")
sweedenRoutes<-sqldf::sqldf("SELECT LON,LAT,C1 from sourceDataNorm  WHERE C1=='SE' AND LAT!='NA' AND LON!='NA'")
usaRoutes<-sqldf::sqldf("SELECT LON,LAT,C1 from sourceDataNorm  WHERE C1=='US' AND LAT!='NA' AND LON!='NA'")
germanyRoutes<-sqldf::sqldf("SELECT LON,LAT,C1 from sourceDataNorm  WHERE C1=='DE' AND LAT!='NA' AND LON!='NA'")
denmarkRoutes<-sqldf::sqldf("SELECT LON,LAT,C1 from sourceDataNorm  WHERE C1=='DK' AND LAT!='NA' AND LON!='NA'")

# drawing chosen routes on world map
points(spainRoutes$LON, spainRoutes$LAT, col = "red", cex = .6)
points(franceRoutes$LON, franceRoutes$LAT, col = "green", cex = .6)
points(netherlandsRoutes$LON, netherlandsRoutes$LAT, col = "blue", cex = .6)
points(englandRoutes$LON, englandRoutes$LAT, col = "yellow", cex = .6)
points(sweedenRoutes$LON, sweedenRoutes$LAT, col = "pink", cex = .6)
points(usaRoutes$LON, usaRoutes$LAT, col = "purple", cex = .6)
points(germanyRoutes$LON, germanyRoutes$LAT, col = "orange", cex = .6)
points(denmarkRoutes$LON, denmarkRoutes$LAT, col = "brown", cex = .6)







