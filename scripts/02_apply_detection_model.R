# Detect damage on rasters using trained model.
# Mosaic from previous year and from current year of detection are necessary.

# Set input folder present and past where the tile images of the present and past year are
# Set output folder
# Set year of prediction
# Set name_model
# Set output_type of the model output: prob for probability or class for direct prediction

library(renv)
library(terra)
library(here)
library(ranger)
library(tidymodels)
library(dplyr)
source(local=TRUE, "scripts/my_functions.R")

# Parameter
# Input folders to present and past image tiles
input_folder_present <- r"{Y:\Andrea\wsf-sat\data\s2_mosaic_gee\s2_2023\tiles}"
input_folder_past <- r"{Y:\Andrea\wsf-sat\data\s2_mosaic_gee\s2_2022\tiles}"

# Output
output_folder <- r"{output\predictions}"  
# if output_folder doesn't exist is created in the project directory
if (!dir.exists(here(output_folder))) {dir.create(here(output_folder), recursive=TRUE)}

year_of_prediction = '2023'
name_model <- "model_rf_lokal_10000_181023_3var.Rdata" # must be located in the output folder of this project
output_type = "prob" # prob or class

# Env options
terraOptions(tempdir=r"{Y:\Andrea\temp}")
terraOptions()
wopt_options <- list(gdal = c("NUM_THREADS = ALL_CPUS"))

# List input files
list_rpresent <- list.files(path=input_folder_present, pattern="\\.tif$", full.names = TRUE)
list_rpast <- list.files(path=input_folder_past, pattern="\\.tif$", full.names = TRUE)

# Load model
rf_model <- readRDS(here("output", name_model))

# Define and if not existing, create output folder for detection
prediction_output_folder <- here(output_folder, paste0(gsub("\\..*", "", name_model), "_", output_type)
                                 , year_of_prediction, 'tiles')
if (!dir.exists(prediction_output_folder)) {dir.create(prediction_output_folder, recursive=TRUE)}

# Define output data type of raster depending on output type
if(output_type == "prob") {output_data_type <- 'FLT4S'} else if(output_type == "class") {output_data_type <- 'INT4S'}

# Prediction 
for(n in c(1:length(list_rpast))){
  print(n)
  # Load needed bands of the rasters
  rpresent <- im2list(list_rpresent[n])
  rpast <- im2list(list_rpast[n])
  
  # Calculate predictors nbr_diff + satvi_past  +  swir1_diff lokal
  
  # nbr_diff
  indices_rpresent <- calculate_indices(rpresent)
  indices_rpast <- calculate_indices(rpast)
  nbr_diff <- indices_rpresent$nbr - indices_rpast$nbr
  
  # satvi_past
  satvi_past <- indices_rpast$satvi
  
  # swir1_diff
  swir1_diff <- rpresent$swir1 - rpast$swir1

  # Create raster to predict and write and read to convert from numeric to int
  # to avoid error in predict
  raster2predict <- c(nbr_diff, satvi_past, swir1_diff)
  names(raster2predict) <- c("nbr_diff", "satvi_past", "swir1_diff")
  
  # Remove not necessary layers
  #rm(rpresent, rpast, indices_rpresent, indices_rpast, nbr_diff, satvi_past, swir1_diff)
  
  
  
  # Predict
  pred_response <- terra::predict(object= raster2predict, 
                                  model = rf_model,
                                  fun = fun,
                                  type = output_type, # class or prob
                                  na.rm=TRUE, 
                                  wopt= wopt_options)
  # pred response -1 to change output from 1 2 to 0 1 
  writeRaster(pred_response-1, here('output', 'predictions', 'model_rf_lokal_10000_181023_3var_prob', year_of_prediction, 'tiles', 
                                    paste0('predictions_rf_gee_ni_', year_of_prediction, '_', n, '.tif')), 
              filetype="GTiff", datatype='FLT4S', overwrite=TRUE)
  
  
  output_file_name <- paste0('predictions_rf_gee_ni_', year_of_prediction, '_', n, '.tif')
  writeRaster(x=pred_response-1, 
              filename=paste(prediction_output_folder, output_file_name, sep="\\"), 
              filetype="GTiff", datatype=output_data_type, overwrite=TRUE)
  

}


