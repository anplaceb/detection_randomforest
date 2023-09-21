# Predict damage on rasters. Raster past and raster present necessary.
# Input can be folder with rasters or single raster.
library(renv)
library(terra)
library(here)
library(ranger)
library(tidymodels)
library(dplyr)
#library(data.table)
source(local=TRUE, "scripts/my_functions.R")

# Env
#memory.limit(9999999999) # not supported anymore
terraOptions(tempdir=r"{Y:\Andrea\temp}")
terraOptions()
wopt_options <- list(gdal = c("NUM_THREADS = ALL_CPUS"))

# input 
# path to raster folder or path to one raster (choose one)
# path to model
# path to aoi (opt)
one_raster_prediction = ""
multiple_raster_prediction = "YES"
tuned_model <- readRDS(here("output", "model_rf_210923.Rdata"))

# one raster or list?
if(one_raster_prediction != "") {
  print("Your input is a single raster")
  path2raster_present <- r"{Y:\Andrea\wsf-sat\data\s2_mosaic_gee\s2_2019\ortho_gee_2019_2.tif}"
  path2raster_past <- r"{Y:\Andrea\wsf-sat\data\s2_mosaic_gee\s2_2018\ortho_gee_2018.tif}"
  
  list_rpresent <- list(path2raster_present)
  list_rpast <- list(path2raster_past)
  
  
} else if(multiple_raster_prediction !="") {
  print("Your input is a folder with files")
  
  path2folder_present <- r"{Y:\Andrea\wsf-sat\data\s2_mosaic_gee\s2_2019\tiles}"
  path2folder_past <- r"{Y:\Andrea\wsf-sat\data\s2_mosaic_gee\s2_2018\tiles}"
  
  list_rpresent <- list.files(path=path2folder_present, pattern="\\.tif$", full.names = TRUE)
  list_rpast <- list.files(path=path2folder_past, pattern="\\.tif$", full.names = TRUE)

}

for(n in c(1:length(list_rpast))){
  print(n)
  # Load bands of the rasters
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
  #names(raster2predict) <-  c("Sepal.Length", "Sepal.Width", "Petal.Length")
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
  writeRaster(pred_response, here('output', 'predictions', paste0('predictions_rf_gee_ni_2019_180923_', n, '.tif')), 
              filetype="GTiff", datatype='INT4S', overwrite=TRUE)

  

}


