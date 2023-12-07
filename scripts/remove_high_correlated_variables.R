library(dplyr)
library(corrplot)
library(data.table)
library(here)
library(caret)

# Looks for high correlated variables

# Load data from Friedericke 2018 and Harz 2021
Friedericke2018_data <- fread(here("output", "reference_Friedericke_2018_clean.csv"), dec = ",")
Harz2021_data <- fread(here("output", "reference_Harz_2021_clean.csv"), dec = ",")

# Merge both datasets
# Each geometry has to have a unique ID before merging
Harz2021_data$ID <- Harz2021_data$ID + max(Friedericke2018_data$ID)
reference_data <- rbind(Friedericke2018_data, Harz2021_data)

# Remove highly correlated variables
# The variables in the vector are ordered by the biggest ratio. Add the ones 
# with the biggest ratio (mean sd analyse detection from index_analysis) and add
#only a variable if the correlation to all other variables is max 0.80

variables <- c( "nbr2_diff"  ,   "ndvi_diff" ,   "i6_diff"     ,  "i3_diff"     ,  "gndvi_diff",    "satvi_past"   , "swir2_diff"  ,  "i1_diff"    ,  
                "swir1_past"  ,  "swir1_diff" ,   "re2_past"    ,  "red_diff"    ,  "nir2_past"  ,   "nir_past"   ,   "re3_past"    ,  "i1_present"  ,  "i4_present"   ,
                "mcari_present", "blue_diff"   ,  "ndvi_present" , "satvi_diff"   , "i5_past" ,      "mcari_diff"  ,  "swir2_past"   , "i5_present" ,   "i6_present"   ,
                "nbr_present"  , "gndvi_present", "re1_diff"     , "nbr2_present",  "i2_past"  ,     "savi_present",  "green_diff"   , "i3_past"     ,  "re1_past"     ,
                "green_past" ,   "savi_past"  ,   "i2_diff"   ,   "red_present"  , "re3_present" ,  "i4_past"    ,   "savi_diff"   ,  "nir_present" ,  "i4_diff"      ,
                "nir2_present" , "blue_past"  ,   "re2_present" ,  "swir2_present" , "satvi_present", "blue_present" , "red_past"  ,    "i3_present" ,   "re1_present" , 
                "i2_present" ,   "green_present" ,"mcari_past" ,   "nbr2_past"   ,  "nbr_past" ,     "swir1_present" ,"i1_past"   ,    "re2_diff"  ,    "gndvi_past",   
                "i5_diff"    ,   "nir2_diff"  ,   "nir_diff"   ,   "i6_past"   ,    "re3_diff" ,     "ndvi_past")    
select_vec <- c("nbr_diff")

for (var in variables){
  # add column names to the select vector
  select_vec <- c(select_vec, var)
  # select data with column names
  data2cor <- reference_data %>% select(all_of(select_vec))
  
  # calculate correlation matrix
  correlation_matrix <- cor(data2cor, use="complete.obs")
  
  # check if adding new variables brings correlations above 0.79
  condition <- which(abs(correlation_matrix)>0.79 & correlation_matrix<1)
  
  # if condition not fullfilled i.e. it does not add high correlation, do nothing
  if(length(condition)==0 ){
    print(paste0(var, " added ", sep=" "))
  }
  else{
    print(paste0(var, " adds too much correlation, drop ", sep=" "))
    # if it does, remove added variable from the columns to select 
    select_vec <- select_vec [!select_vec %in% var] 
    #data2cor <- reference_data %>% select(-var)
  }
} 
select_vec

# confusion matrix with the selected variables
data2cor <- reference_data %>% select(all_of(select_vec))

corrplot(cor(na.omit(data2cor)), method="number")
correlation_matrix <- cor(data2cor, use="complete.obs")
