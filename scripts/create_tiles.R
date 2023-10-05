library(renv)
library(terra)

makeTiles(x=rast(r"{Y:\Andrea\wsf-sat\data\s2_mosaic_gee\s2_2023\gee_2023_11bands.tif}"), 
          y=c(3000, 3000),
          filename=r"{Y:\Andrea\wsf-sat\data\s2_mosaic_gee\s2_2023\tiles\gee_2023_.tif}", 
          na.rm=TRUE)


