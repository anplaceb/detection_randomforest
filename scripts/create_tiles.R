library(renv)
library(terra)

makeTiles(x=rast(r"{Y:\Andrea\wsf-sat\data\s2_mosaic_gee\s2_2019\ortho_gee_2019_11bands.tif}"), 
          y=c(3000, 3000),
          filename=r"{Y:\Andrea\wsf-sat\data\s2_mosaic_gee\s2_2019\tiles_extend\ortho_gee_2019_.tif}", 
          na.rm=TRUE, extend=TRUE)


