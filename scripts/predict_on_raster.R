# Predict damage on rasters using trained model.
# Here are raster past and raster present necessary for the used model.
# Input can be folder with rasters or single raster.

# Define year of prediction, choose one_raster_prediction or 
# multiple_raster_prediction and set path2folder_present, path2folder_past

library(renv)
library(terra)
library(here)
library(ranger)
library(tidymodels)
library(dplyr)
source(local=TRUE, "scripts/my_functions.R")

# input parameter
year = '2019'
tuned_model <- readRDS(here("output", "model_rf_10000_210923.RData"))

# path to raster folder or path to one raster (choose one and set "YES")
one_raster_prediction = ""
multiple_raster_prediction = "YES"

# Env
terraOptions(tempdir=r"{Y:\Andrea\temp}")
terraOptions()
wopt_options <- list(gdal = c("NUM_THREADS = ALL_CPUS"))

# input set to one raster or list of rasters in a folder
if(one_raster_prediction != "") {
  print("Your input is a single raster")
  path2raster_present <- r"{Y:\Andrea\wsf-sat\data\s2_mosaic_gee\s2_2017\ortho_gee_2017_7bands.tif}"
  path2raster_past <- r"{Y:\Andrea\wsf-sat\data\s2_mosaic_gee\s2_2018\ortho_gee_2018_7bands.tif}"
  
  list_rpresent <- path2raster_present
  list_rpast <- path2raster_past
  
} else if(multiple_raster_prediction !="") {
  print("Your input is a folder with files")
  
  path2folder_present <- r"{Y:\Andrea\wsf-sat\data\s2_mosaic_gee\s2_2019\tiles}"
  path2folder_past <- r"{Y:\Andrea\wsf-sat\data\s2_mosaic_gee\s2_2018\tiles}"
  
  list_rpresent <- list.files(path=path2folder_present, pattern="\\.tif$", full.names = TRUE)
  list_rpast <- list.files(path=path2folder_past, pattern="\\.tif$", full.names = TRUE)
}

# Prediction 
for(n in c(1:length(list_rpast))){
  print(n)
  # Load needed bands of the rasters, in this case swir1 and nbr band
  # for mosaic 2017 and 2018 swir1 and nbr are 5 and 7
  # for the rest of the years are 9 and 11
  rpresent <- im2list(list_rpresent[n], indices= c(9,11))
  rpast <- im2list(list_rpast[n], indices= c(5,7))

  # Calculate predictors
  nbr_diff <- rpresent$nbr - rpast$nbr
  swir1_diff <- rpresent$swir1 - rpast$swir1
  
  # Create raster to predict and write and read to convert from numeric to int
  # to avoid error in predict
  raster2predict <- c(nbr_diff, swir1_diff, rpast$swir1)
 
  #writeRaster(raster2predict, filename=here("output", paste0("myraster2predict_", n, ".tif")), 
  #            filetype="GTiff", datatype='INT4S', overwrite=TRUE)
  #raster2predict <- rast(here("output", paste0("raster2predict_", n, ".tif")))
  
  names(raster2predict) <- c("nbr_diff", "swir1_diff", "swir1_past")

  # Remove not necessary layers
  rm(rpresent, rpast, nbr_diff, swir1_diff)
  
  fun<-function(...){
    p<-predict(...)
    return(as.matrix(as.numeric(p[, 1, drop=T]))) 
  }
 
  # Predict
  pred_response <- terra::predict(object= raster2predict, 
                                  model = tuned_model,
                                  fun = fun,
                                  type = "class", # class or prob
                                  na.rm=TRUE, 
                                  wopt= wopt_options)
  # pred response -1 to change output from 1 2 to 0 1 
  writeRaster(pred_response-1, here('output', 'predictions', year, 
                                  paste0('predictions_rf_gee_ni_', year, '_', n, '.tif')), 
              filetype="GTiff", datatype='INT4S', overwrite=TRUE)

  

}


