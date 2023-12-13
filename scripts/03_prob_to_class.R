library(terra)
library(renv)

# Convert probability values to detection 
# Set input raster
# Set outpt file name
# Set threshold value to clamp input raster
input_raster <- r"{P:\WSF-SAT\Permanent\Methoden\Software\RandomForest\detection_randomforest\output\predictions\model_rf_lokal_10000_181023_3var_prob\2022\rf_prob_prediction_2022.tif}"
output_file_name <- r"{P:\WSF-SAT\Permanent\Methoden\Software\RandomForest\detection_randomforest\output\predictions\model_rf_lokal_10000_181023_3var_prob\2022\rf_prob_prediction_2022_class.tif}"
threshold_value <- 1 # probability of being no damage

# Env options
terraOptions(tempdir=r"{Y:\Andrea}")
terraOptions()
wopt_options <- list(gdal = c("NUM_THREADS = ALL_CPUS"))

# Load raster
r <- rast(input_raster)
# Clamp values of the raster to a maximal value 
r_clamp <- clamp(r, lower=threshold_value, value=FALSE) 
writeRaster(x=r_clamp, filename=output_file_name, 
            filetype="COG", datatype='INT4S', overwrite=TRUE, wopt=wopt_options)

