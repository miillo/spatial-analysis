library(rworldmap)
library(dplyr)
library(purrr)
library(gstat)
library(ggplot2)
library(lattice) # generating grid for kriging
library(tidyverse)

##### Data preprocessing #####
# Reading source data 
sourceData = read.fwf("CLIWOC21CORE.txt", widths = c(4,2,2,4,5,6,2,1,1,1,1,1,2,2,9,2,1,3,1,3,1,2,2,1,5,1,3,1,4,1,4,1,4,2,4,1,1,1,1,1,1,1,2,2,2,2,2,2), 
                                          col.names =  c("YR","MO","DY","HR","LAT","LON","IM","ATTC","TI","LI","DS","VS","NID","II","ID","C1","DI","D","WI","W","VI","VV","WW","W1","SLP","A","PPP","IT","AT","WBTI","WBT","DPTI","DPT","SI","SST","N","NH","CL","HI","H","CM","CH","WD","WP","WH","SD","SP","SH"))

# Normalizing longitude / latitude
source("coord-normalization.r")
sourceDataNorm <- transform(sourceData, LAT = latNorm(sourceData$LAT),
                            LON = as.double(map(sourceData$LON, longNorm)), 
                            W = as.double(map(sourceData$W, wNorm)))

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
germanyRoutes<-sqldf::sqldf("SELECT LON,LAT,C1,W from sourceDataNorm  WHERE C1=='DE' AND LAT!='NA' AND LON!='NA' AND W != 'NA' AND W != 0")
denmarkRoutes<-sqldf::sqldf("SELECT LON,LAT,C1 from sourceDataNorm  WHERE C1=='DK' AND LAT!='NA' AND LON!='NA'")

# choosing Bay of Biscay routes
bayOfBiscay <- sqldf::sqldf("SELECT LON,LAT,C1,W from sourceDataNorm WHERE C1 == 'FR' AND LAT > 43.27 AND LAT < 47.98 AND 
                            LON > -7.89 AND LON < -0.14 AND LAT!='NA' AND LON!='NA' AND W != 'NA' AND W != 0")

# drawing chosen routes on world map
points(spainRoutes$LON, spainRoutes$LAT, col = "red", cex = .6)
points(franceRoutes$LON, franceRoutes$LAT, col = "green", cex = .6)
points(netherlandsRoutes$LON, netherlandsRoutes$LAT, col = "blue", cex = .6)
points(englandRoutes$LON, englandRoutes$LAT, col = "yellow", cex = .6)
points(sweedenRoutes$LON, sweedenRoutes$LAT, col = "pink", cex = .6)
points(usaRoutes$LON, usaRoutes$LAT, col = "purple", cex = .6)
points(germanyRoutes$LON, germanyRoutes$LAT, col = "orange", cex = .6)
points(denmarkRoutes$LON, denmarkRoutes$LAT, col = "brown", cex = .6)
points(bayOfBiscay$LON, bayOfBiscay$LAT, col = "green", cex = .6)

##### Data analysis #####

# Kriging
# Experiment I - Germany routes 

# Setting coordinates for spatial object
coordinates(germanyRoutes) <- ~ LAT + LON

# Calculating variogram based on W(wind speed) variable
lzn.vgmger <- variogram(log(W)~1, germanyRoutes)

# Fiting variogram to chosen model
lzn.fitger <- fit.variogram(lzn.vgmger, model = vgm("Sph"))
plot(lzn.vgmger, lzn.fitger)

# Generating grid for kriging
lon <- seq(-40,10,by=1)
lat <- seq(-40,40,by=1)
grid <- expand.grid(lat = lat, lon = lon)
coordinates(grid) <-  ~ lat + lon

# Computing kriging
lzn.krigedger <- krige(log(W)~1, germanyRoutes, grid, model = lzn.fitger)
spplot(lzn.krigedger,"var1.pred",asp=1,col.regions=bpy.colors(64),xlim=c(-40,40),ylim=c(-40,10),main="Kriging Prediction by Sph Model of wind speed in germany ships routes")

## end od Experiment I

# Experiment II - Bay of Biscay routes

# Choosing representatives
bayOfBiscayT <- head(bayOfBiscay, 300)

# Setting coordinates for spatial object
coordinates(bayOfBiscayT) <- ~ LAT + LON

# Calculating variogram based on W(wind speed) variable
lzn.vgmbob <- variogram(log(W)~1, bayOfBiscayT, cutoff=7)

# Fiting variogram to chosen model
lzn.fitbob <- fit.variogram(lzn.vgmbob, model = vgm(psill = max(lzn.vgmbob$gamma)*0.5, 
                                                    model = "Sph", range = max(lzn.vgmbob$dist)/2,
                                                    nugget = mean(lzn.vgmbob$gamma)/4))
plot(lzn.vgmbob, lzn.fitbob)

# Generating grid for kriging
lon <- seq(-10,0,by=0.01)
lat <- seq(40,48.0,by=0.01)
grid <- expand.grid(lat = lat, lon = lon)
coordinates(grid) <-  ~ lat + lon

# Deleting duplicates
bayOfBiscayTUni <- bayOfBiscayT[-zerodist(bayOfBiscayT)[,1],]

# Computing kriging - takes some time
lzn.krigedbob <- krige(log(W)~1, bayOfBiscayTUni, grid, model = lzn.fitbob)
spplot(lzn.krigedbob,"var1.pred",asp=1,col.regions=bpy.colors(64),xlim=c(42,48),ylim=c(-11,5),main="Kriging Prediction by Sph Model of wind speed in Bay of Biscay france routes")
# end of Experiment II

# end of Kriging analysis

