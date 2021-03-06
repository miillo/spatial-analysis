#Detach all packages
 lapply(names(sessionInfo()$otherPkgs), function(pkgs) detach(paste0('package:',pkgs),character.only = T,unload = T,force=T))

library(rworldmap)
library(dplyr)
library(purrr)
library(gstat)
library(ggplot2)
library(lattice) # generating grid for kriging
library(tidyverse)
library(hexbin)
library(fMultivar)
library(grid)
library(sn)
library(tmaptools)
library(tmap)
library(tidyverse)
library(geoR)
library(sp)
library(raster)

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

################## Variograms ##################
# Data preprocessing
gerandus<-sqldf::sqldf("SELECT LON,LAT,W from sourceDataNorm  WHERE C1=='GER' OR C1 == 'US' AND LAT!='NA' AND LON!='NA' AND W != 'NA' AND W != 0")
gerandusGeoData <- as.geodata(obj = gerandus, coords.col = 1:2, data.col = 3)

# Experiment 1 - Cloud variogram
cloudVariogram <- variog(geodata = gerandusGeoData, option = "cloud", max.dist = 5)
plot(cloudVariogram, main = "Cloud variogram")

# Experiment 2 - Bin variogram
dists <- dist(gerandus[,1:2])
breaks = seq(0, 185, l = 25)
binVariogram <- variog(gerandusGeoData, breaks = breaks)
plot(binVariogram, main = "Bin variogram")

################## End of variograms analysis ##################

################## Kriging ################### 
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

################## End of kriging analysis ##################

################## Hexbin / fMultivar analysis ################### 

# Creating hexbin object
englandHexB<-hexbin(englandRoutes$LON,englandRoutes$LAT,shape = 0.5, xbins = 100, xbnds = range(englandRoutes$LON),ybnds = range(englandRoutes$LAT), xlab="LON",ylab = "LAT")
# Visualizing results
hexbinplot(englandRoutes$LAT ~ englandRoutes$LON, data=NULL, xbins = 100,xlab="LON",ylab="LAT",colramp = mycolorstographs, colorcut = seq(0, 1, length = 15))
hexbinplot(englandRoutes$LAT ~ englandRoutes$LON, data=NULL,shape=0.5, xbins = 100,xlab="LON",ylab="LAT",colramp = mycolorstographs, colorcut = seq(0, 1, length = 15))
hexbinplot(englandRoutes$LAT ~ englandRoutes$LON, data=NULL,shape=0.5, xbins = 100,xlab="LON",ylab="LAT", style="nested.centroids")

p<- plot(englandHexB, type="n", main="Trasy angielskich statkow")
pushHexport(p$plot.vp)
grid.hexagons(englandHexB,style="lattice", border = gray(.1), pen = gray(.6),minarea = .04, maxarea = 0.9)
popViewport()


#Eroded - leaving most attended routes
smbin<-smooth.hexbin(englandHexB)
erodebin <- erode.hexbin(smbin, cdfcut=.5)
hboxplot(erodebin, main = "Obraz przedstawiajacy najbardziej uczeszczane szlaki",border = c(2,4))

#fMultivardata:image/png;base64,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pZRSSimllFJKKaWUUkoppZRSSimllFJKKaVUsf0XWAnsBlYAIxMbnYSrgt0ny4GdwGJgYEJjlDyuARYC+9AhP8B2AvY68CfwGzAisdFJGnqcFKTXFX96D1Jx0xdoA9QHegNrgBMSGaEEqw08DmQCTYDLsCfaQYmMVJIYApwKvIzeqACeBT4BGmPPo+3uvbLT46Qgva7403uQKhWNgR+BKxIdkSSzDDgz0ZFIIv9Fb1TpwA7gaE/YOPdSlh4n0el1paBKcQ/SwSlL133AOmzKOABMSmx0kkoz7NPDNwmOh0oubYCawCJP2CKgc0JifeedHwAAAp9JREFUo8obva7kV6nuQWmJjkAFdz/wJHAUcDg261xBVeA14BnguwTHRSWXWu7de65sRQfXU4XT60pBleoepDk08TECEPea7QnfDqzCVnCsAVxf5jFLHL99kg5MBNZjKzlWNn77RVk73Ls3AVOXCn4hViVW2a8rfirVPUgTNPHxFGDc6xifZQzQrqwilAQi7ZM07IllgPOA3ITELLFiOVYqs1+wrVW6ecK6A98mJDaqPNDrSmwq/D1IEzSlozZwNdAWaAAMBS4APk5kpBIsFds6oz52X6QC1dx7ZZdGaF8E90tlLQ7ehy02uINQ64wzgRcTGakkocdJQXpdiUzvQSpuagLvARuBXcBS4KqExijx2hAqavG+rk1gnJLFPRTcLw8kNEaJVRt4A9sPzWq0H5ogPU4KaoNeVyLRe5BSSimllFJKKaWUUkoppZRSSimllFJKKaWUUkoppZRSSimllFJKKaWUUkoppZRSSimllFJKKaWUUkoppZRSSimllFJKKaWUUkoppZRSSimllFJKKaWUUkoppZRSSimllFJKKaWUUkoppZRSSimllFJKKaWUUkoppZRSSlVa7YFNQE833QJYDxyTqAgppZRSShXHJcBSoAbwPvBQYqOjlEp2JtERUEopH28BbQEBDgf2JDY6SimllFJFdyo2MXNJoiOilFJKKVUctYDlwDjgd6BBYqOjlFJKKVV0zwFvuM/PABMTGBellFJKqSI7jfy5MrWAn4DzEhYjpZRSSimllFJKKaWUUkoppZRSSimllFJKKaWUUkoppZRSSimllFJKKaWUUkoppZRSSimllFJKKaWUUkoppZRSSimllFJKKaWUUkoppZRSSimllFJKKaWUUkoppZRSSimllFJKKaWUUkopVVH9Pw1b4ijd+a9PAAAAAElFTkSuQmCC
englangfMultivar<-hexBinning(englandRoutes$LON,englandRoutes$LAT, bins = 100)

densityEngland<-density2d(englandRoutes$LON,englandRoutes$LAT,n=300,h=NULL,limits=c(range(englandRoutes$LON),range(englandRoutes$LAT)))
plot(densityEngland)
image(densityEngland,xlab = "LON",ylab="LAT")
contour(densityEngland,add=TRUE)

################## End of Hexbin / fMultivar analysis ################### 

################## Point patterns analysis ################### 
plot(map)
points(franceRoutes$LON,franceRoutes$LAT, col='red', cex=0.5,pch='+')
LONfranceRoutes<-franceRoutes<-sqldf::sqldf("SELECT LON from sourceDataNorm  WHERE C1=='FR' AND LAT!='NA' AND LON!='NA'")
LATfranceRoutes<-franceRoutes<-sqldf::sqldf("SELECT LAT from sourceDataNorm  WHERE C1=='FR' AND LAT!='NA' AND LON!='NA'")
xy<-cbind(LONfranceRoutes,LATfranceRoutes)
xy.sp<-SpatialPoints(xy)
xyCO<-coordinates(xy.sp)
dim(xyCO)
xyCO<-unique(xyCO)
mc<-apply(xyCO, 2, mean)
sd <- sqrt(sum((xyCO[,1] - mc[1])^2 + (xyCO[,2] - mc[2])^2) / nrow(xyCO))
plot(map, col='light blue')
points(xy.sp, cex=.5)
points(cbind(mc[1], mc[2]), pch='*', col='red', cex=5)
# make a circle
bearing <- 1:360 * pi/180
cx <- mc[1] + sd * cos(bearing)
cy <- mc[2] + sd * sin(bearing)
circle <- cbind(cx, cy)
lines(circle, col='red', lwd=2)

