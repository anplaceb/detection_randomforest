
im2list <- function (image, indices){
  # Loads the bands of an image into a list of rasters
  # Input can be either the raster object or the path to it
  # indices: the indices to swir1 and nbr
  
  if(is.character(image) == 1 ){image <- rast(image)} # if path is given, load
  # as image
  return(c('swir1' = image[[indices[1]]], 
           'nbr' = image[[indices[2]]]
  )
  )
  
}

# The problem is that a model produced by the parsnip package always returns a 
# tibble when the prediction type is type="class". terra,predict expects a
# matrix to be returned. You can get around this by providing a function to 
# raster.predict that converts the returned parsnip::predicted model to a matrix.
fun<-function(...){
  p<-predict(...)
  return(as.matrix(as.numeric(p[, 1, drop=T]))) 
}