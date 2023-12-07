library(terra)
library(renv)

# Convert probability values to detection 
# Set input raster
# Set outpt file name
# Set threshold value to clamp input raster
input_raster <- r"{D:\wsf-sat\methods\scripts\detection_randomforest\output\predictions\model_rf_lokal_10000_181023_3var_prob\2023\rf_prob_prediction_2023.tif}"
output_file_name <- r"{D:\wsf-sat\methods\postprocessing\rf_postprocessing\model_rf_lokal_10000_181023_3var_prob\detection_input_for_postprocessing\2023.tif}"
threshold_value <- -1

# Env options
terraOptions(tempdir=r"{Y:\Andrea}")
terraOptions()
wopt_options <- list(gdal = c("NUM_THREADS = ALL_CPUS"))

# Load raster
r <- rast(input_raster)

# Clamp values of the raster to a maximal value 
# Multiply with -1 to convert to 1
r_clamp <- clamp(r, upper=threshold_value, value=FALSE) * -1
writeRaster(x=r_clamp, filename=output_file_name, 
            filetype="COG", datatype='INT4S', overwrite=TRUE, wopt=wopt_options)
