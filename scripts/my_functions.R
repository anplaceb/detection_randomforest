# Functions

# Function to load an image into a list with band names to access the bands
im2list <- function (image){
  # Loads the bands of an image into a list of rasters
  # Input can be either the already loaded raster object or the path to it
  # if path is given, load it as image first
  if(is.character(image) == 1 ){image <- rast(image)}
  return(c('blue' = image[[1]], 
           'green' = image[[2]],
           'red' = image[[3]], 
           're1' = image[[4]],
           're2' = image[[5]], 
           're3' = image[[6]],
           'nir' = image[[7]], 
           'nir2' = image[[8]],
           'swir1' = image[[9]], 
           'swir2' = image[[10]]
  )
  )
}

# Function to make prediction with terra on raster compatible with model 
# produced with the parsnip package
# The problem is that a model produced by the parsnip package always returns a 
# tibble when the prediction type is type="class". terra,predict expects a
# matrix to be returned. You can get around this by providing a function to 
# raster.predict that converts the returned parsnip::predicted model to a matrix.
fun<-function(...){
  p<-predict(...)
  return(as.matrix(as.numeric(p[, 1, drop=T]))) 
}

# Functions to calculate indices
norm_diff <- function(x,y){round((x-y)/(x+y)*100 + 100)}
satvi_index <- function(x, y, z)  {round(((x - y) / (x + y + 5000)) * (15000) - (z/ 2))}

calculate_indices <- function(image){
  bands <- im2list(image)
  return(c('satvi'= lapp(x = c(bands$swir1, bands$red, bands$swir2), fun=satvi_index),
           'nbr' = lapp(x = c(bands$nir, bands$swir2), fun=norm_diff)
  ))
}

calculate_nbr <- function(image){
  bands <- im2list(image)
  return(c('nbr' = lapp(x = c(bands$nir, bands$swir2), fun=norm_diff)
  ))
}