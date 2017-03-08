###Antet ####
#author: Sabina Rosca
#date: 29/03/2016
#This script runs bfastSpatial on L7 scenes acquired in Gabon (P185 R061)
#between 2000 and 2015 on a selected 10x10 km test area (Zone2) 
#### #### 

####Creating the extend and the forest masks
###Install packages ####
# install.packages("ggplot2")
# install.packages("maptools")
# install.packages("shapefiles")
# install_github('dutri001/bfastSpatial')
# install.packages("tiff")
# install.packages("utils")
# install.packages('dplyr')
# install.packages('zoo')
# install.packages('lubridate')
# install.packages("ggplot")
# install.packages("shiny")
#### ####

###Load the package ####
library(devtools)
library(bfastSpatial)
require(rgdal)
library(maptools)
require(raster)
library(ggplot2)
library(sp)
library(shapefiles)
library(tiff)
library(utils)
library(shiny)
library(zoo)
#### ####

# ####Generate (or extract, depending on whether the layer is already in the archive or not)
# ####the spectral index from the archives and apply Fmask ####
# # Set the location of output and intermediary directories (everything in tmpdir in that case)
# # We use dirname(rasterTmpFile()) instead of rasterOptions()$tmpdir to reduce verbose
# # tmp dir is for storing 'invisible' temporary files
# # We can use the tmp directory of the raster package
# tmpDir <- file.path(dirname(rasterTmpFile()), 'bfmspatial')
# # Move downloaded Landsat archive in the in folder
# inDir <- file.path("D:/Sabina-Internship/Project/Test_Peru/BFAST/in")
# ndmiDir <- file.path("D:/Sabina-Internship/Project/Test_Peru/BFAST/ndmi")
# # Check to see if the files are there
# list.files(inDir)
# # Get list of test data files
# list <- list.files(inDir, full.names=TRUE)
# list
# #processLandsatBatch(x = inDir, outdir = ndmiDir, srdir = tmpDir,
# #                      delete = TRUE, mask = 'fmask', vi = 'ndmi')
# # Visualize one of the layers produced
# head(list.files(ndmiDir))
# list <- list.files(ndmiDir, pattern=glob2rx('*.grd'), full.names=TRUE)
# r <- raster(list[3])
# plot(r)
# #### ####

###Set paths of the project ####
ndmiDir <- file.path("D:/Sabina-Internship/Project/Test_Peru/BFAST/ndmi")
path <- 'D:/Sabina-Internship/Project/Test_Peru/BFAST/z3/ndmi'
# StepDir is where we store intermediary outputs
stepDir <- file.path(path, 'step')
#ndmiCropped is where the individul cropped (with the extent of the test area)
#ndmi layers will be storred before being masked
ndmiCropDir <- file.path(stepDir, 'ndmi_croped')
#ndmiCropped is where the individul masked (with the forest mask and extent of the test area)
#ndmi layers will be storred before being stacked
ndmiMaskDir <- file.path(stepDir, 'ndmi_masked')
#ndmiSelected is where the individul masked (with the forest mask and extent of the test area)
#ndmi layers will be storred if they are valid
ndmiSelected <- file.path(stepDir, 'ndmi_selected')
# Ouput directory
outDir <- file.path(path, 'out')
#Create all the folders in the specified path
for (i in c(path,stepDir,ndmiCropDir,ndmiMaskDir,ndmiSelected, outDir)) {
  dir.create(i, showWarnings = TRUE)
}
### ####

###Load  extent for the Test data #### 
#The raster also represents a forest mask (value 1), masking the non-forest areas (value NA)
ForestMask <- raster("D:/Sabina-Internship/Project/Test_Peru/Forest_cover/Hansen/Hansen_F_cover_2010_z3.tif")
plot(ForestMask, main="Forest cover mask Peru zone3", legend=FALSE, col="black")
Hansen_def_after_2010 <- raster("D:/Sabina-Internship/Project/Test_Peru/Forest_cover/Hansen/Hansen_def_after_2010_z3.tif")
#### ####

####Pre-proccessing of the full scenes for applying BFAST on the interest zone ####
####Crop the Landsat L8 and L7 scenes to the same extent ####
# Get list of test data files
list <- list.files(ndmiDir,pattern=glob2rx('*.grd'), full.names=TRUE)
list
substr(list[1],start=51, stop=nchar(list[1]))
for (i in 1:length(list)) {crop(raster(list[i]),ForestMask,
                                filename=file.path(ndmiCropDir,(substr(list[i],start=51, stop=nchar(list[i])))))}
#for (i in 1:length(list)) {plot(raster(list[i]))}
#### ####

####Mask the cropped Landsat scenes with the Forest mask (all areas with no forest in 2010 will be masked) ####
list <- list.files(ndmiCropDir, pattern=glob2rx('*.grd'), full.names=TRUE)
substr(list[1],start=71, stop=nchar(list[1]))
for (i in 1:length(list)) {mask(raster(list[i]),ForestMask,
                                filename=file.path(ndmiMaskDir,(substr(list[i],start=71, stop=nchar(list[i])))))}
#for (i in 1:length(list)) {plot(raster(list[i]))}
list <- list.files(ndmiMaskDir, pattern=glob2rx('*.grd'), full.names=TRUE)
a <- raster(list[124])
plot(a)
#### ####


####Assess if each cropped and masked Landsat scene is valid ####
#1. Select only the scenes that also have values different than NA
emptyRlist <- c()
for (i in list) {
  a <- freq(is.na(raster(i)))
  if (a[,2]== 111556){
    emptyRlist=c(emptyRlist,i)
  }}
emptyRlist
ValidRlist <- c()
for (i in list){
  if (!(i %in% emptyRlist)){
    ValidRlist=c(ValidRlist,i)
  }}
length(ValidRlist)
#2. Select only the scenes that also have values of positive ndmi
ValidRlist2 <- c()
for (i in ValidRlist){
  q <- cellStats(raster(i),stat="mean",na.rm=TRUE)
  if (q>0){
    ValidRlist2 <- c(ValidRlist2,i)
  }
}
length(ValidRlist2)
# Copy all the valid rasters in a separate folder 
substr(ValidRlist2[1],start=71, stop=nchar(ValidRlist2[1]))
for (i in 1:length(ValidRlist2)){
  raster1 <- raster(ValidRlist2[i])
  writeRaster(raster1, filename=file.path(ndmiSelected,(substr(ValidRlist2[i],start=71, stop=nchar(ValidRlist2[i])))))}
list <- list.files(ndmiSelected, pattern=glob2rx('*.grd'), full.names=TRUE)
#### ####

####Create the ndmi rasterBrik ####
ndmiStack <- timeStack(x = ndmiSelected, pattern = glob2rx('*.grd'),
                       filename = file.path(path, 'ndmi_stack_z3.grd'),
                       datatype = 'INT2S',overwrite=TRUE)

ndmiStack <- brick("D:/Workspace/SIRS/Test_Peru/BFAST/z3/ndmi/ndmi_stack_z3.grd")
names(ndmiStack)
#### ####

####Data Inventory - Assessing the timeseries Stack for the 10x10 km test area ####
plot(ndmiStack[[10]])
bfm <- bfmPixel(ndmiStack, start=c(2010,1), cell=79940)
plot(bfm$bfm)
####bfmApp ####
# Sample regular points over the extent of the data
sp <- sampleRegular(ndmiStack, size = 100, sp = TRUE)
plot(sp,add=TRUE)
sp[[1]]

# Extract the time-series corresponding to the locations of the sample points
# and store the multiple time-series object in the stepDir of the project
zooTs <- zooExtract(x = ndmiStack, sample = sp,
                    file = file.path(stepDir, 'zooTs.rds'))
zooTs[1]
runGitHub('dutri001/bfmApp')
#### ####
#No of avaiable scenes per year ####
s <- getSceneinfo(names(ndmiStack))
s
s$year <- as.numeric(substr(s$date, 1, 4))
hist(s$year, breaks=c(2000:2016), main="p185r61: Scenes per Year",
     xlab="year", ylab="# of scenes")
table(s$year)
#No of viable (!NA) observations per pixel
obs <- countObs(ndmiStack)
brks <- c(1,10,30,40,50,70,90,105,120,150)
brks <- c(40,45,50,60,65,70,80,90,150)
plot(obs,breaks=brks,col=rainbow(length(brks)),main="No. of observations per pixel 2000-2015")
summary(obs)
freq(obs)
obs_after_2010 <- countObsPeriods3(ndmiStack, startyear = 2010)
plot(obs_after_2010,breaks=brks,col=rainbow(length(brks)),main="No. of observations per pixel 2010-2015")
summary(obs_after_2010)
freq(obs_after_2010)
obs_before_2010 <- countObsPeriods2(ndmiStack,endyear = 2010)
plot(obs_before_2010,breaks=brks,col=rainbow(length(brks)),main="No. of observations per pixel 2000-2010", add=FALSE)
summary(obs_before_2010)
freq(obs_before_2010)
#Plot all viable scenes
brks <- 5:-5*2000
op <- par(mfrow=c(1,1))
for (i in 1:length(s[,1])){
  plot(ndmiStack[[i]],breaks=brks,col=rainbow(length(brks)), main=s$date[i])
}
cols=rainbow(length(brks))
legend("bottomright", legend=brks, cex=0.8, fill=cols, ncol=1)
#### ####

#### ####
# #Mask the pixels that have less than 15 observations in total and less than 6 observations in the hystory period
# mask <- raster(list[1])
# mask[!is.na(mask)]=1
# mask[is.na(mask)]=1
# mask[obs[]<15]=NA
# freq(mask)
# mask[obs_before_2010[]<6]=NA
# plot(mask)
#### ####

####Apply BFAST ####
#for all valid scenes
out <- file.path(outDir, "bfmSpatial_ndmi_z3.grd")
time_z3_ndmi <- system.time(bfmSpatial(ndmiStack, start = c(2010, 1),formula = response~harmon,
                                       order = 1, history = c(2000, 1), filename = out)) 
bfm_ndmi <- brick(out)
time_z3_ndmi

#Look at the Layers ####

#Change
change <- raster(bfm_ndmi,1)
plot(change, col=rainbow(7),breaks=c(2010:2016), main="Detecting change after 2005 using L8+L7 ndmi 2000-2015")
plot(change, col="red", main="Detecting change after 2005 using L8+L7 ndmi 2000-2015")
#Magnitude
magnitude <- raster(bfm_ndmi,2)
magn_bkp <- magnitude
magn_bkp[is.na(change)] <- NA
plot(magn_bkp,breaks=c(-5:5*1000),col=rainbow(length(c(-5:5*1000))))
plot(magnitude, breaks=c(-5:5*1000),col=rainbow(length(c(-5:5*1000))))
#Error
error <- raster(bfm_ndmi,3)
plot(error)
#Detect deforestation
def_ndmi <- magn_bkp
def_ndmi[def_ndmi>0]=NA
plot(def_ndmi)
plot(def_ndmi,col="black", main="NDMI_deforestation")
plot(def_ndmi,col="red", main="NDMI_deforestation", legend=FALSE, add=TRUE)
plot(def_ndmi,breaks=breacks_magn,col=rainbow(length(breacks_magn)),main="Deforestation with 0 Treshold", add=TRUE)
breacks_magn <- c(0,-100,-200,-300,-400,-500,-650, -800,-1000,-1200,-1600,-2200,-4000)
click(def_ndmi,n=5,xy=TRUE, cell=TRUE, id=TRUE)
writeRaster(def_ndmi,filename = file.path("D:/Sabina-Internship/Project/Test_Peru/Forest_cover/Bfast_deforestation/Def_magn_0_ndmi_z3.tif"))
click(def_ndmi,n=1)

def_years <- change
def_years[is.na(def_ndmi)]=NA
def_2015 <- def_years
def_2015[(def_2015<2015)]=NA
def_2015[(def_2015>2016)]=NA
plot(def_2015, col="black")
click(def_years,n=2,xy=TRUE, cell=TRUE, id=TRUE)
years <- c(2010,2011,2012,2013,2014,2015,2016,2017)
plot(def_years, col=rainbow(length(years)),breaks=years, main="Detecting change after 2005 using L8+L7 ndmi 2000-2015")
plot(def_years, main="Detecting change after 2005 using L8+L7 ndmi 2000-2015")
writeRaster(def_years,filename = file.path("D:/Sabina-Internship/Project/Test_Peru/Forest_cover/Bfast_deforestation/Def_years_0_ndmi_z3.tif"))
#Compare with Global Forest Watch
plot(Hansen_def_after_2010, col="black", add=TRUE)
plot(Hansen_def_after_2010, col="black")
#### ####

def_years[72551]

