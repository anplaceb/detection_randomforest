# Create tiles from input image

library(renv)
library(terra)

input_image_path <- r"{Y:\Andrea\wsf-sat\data\s2_mosaic_gee\s2_2020\gee_2020_11bands.tif}"
output_image_path <- r"{Y:\Andrea\wsf-sat\data\s2_mosaic_gee\s2_2020\tiles\gee_2020_.tif}"
size_tile <- c(3000, 3000) # in meters

makeTiles(x=rast(input_image_path), 
          y=size_tile,
          filename=output_image_path, 
          na.rm=TRUE)
