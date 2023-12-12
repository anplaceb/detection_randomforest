## Packages, seed and data
library(tidyverse)
library(tidymodels)
library(caret)
library(here)
library(data.table)
library(vip)

set.seed(123)

# Load input tables to train the model
d1 <- fread(here("input", "reference_Friedericke_2018_clean.csv"), dec = ",")
d2 <- fread(here("input", "reference_Harz_2021_clean.csv"), dec = ",")

name_model <- "model_rf_lokal_10000_181023_12var.Rdata" # under which name the model is saved

d2$ID <- d2$ID + max(d1$ID) # to ensure an unique ID for each polygon after merging dataframes

# merging dataframes
df <- rbind(d1,d2)

# Sample by group damage / no damage
df <- df %>%
  group_by(damage_class) %>%
  sample_n(10000)  %>%
  ungroup

# Prepare data frame, select columns, mutate column types
df <- 
  df %>% 
  select(-year, -damage_type) %>% 
  mutate_all(~as.numeric(.)) %>% 
  mutate(damage_class = as.factor(damage_class))

## Modelisation
# Initial split taking in account the ID polygon, all pixels of a polygon are 
# either train or test
df_split <- group_initial_split(df[complete.cases(df),], ID)
df_train <- training(df_split)
df_test <- testing(df_split)

# Define model random forest from ranger
model_rf <- 
  rand_forest(mtry = tune(), trees = tune(), min_n = tune()) %>% 
  set_engine("ranger", importance = "impurity", num.threads = parallel::detectCores()) %>% 
  set_mode("classification")

# Grid of hyperparameters for tuning
grid_rf <- 
  grid_max_entropy(        
    mtry(range = c(2, 3)), 
    trees(range = c(500, 1000)),
    min_n(range = c(2, 4)),
    size = 10) 

# Define Workflow and formula
wkfl_rf <- 
  workflow() %>% 
  add_formula(damage_class ~ nbr_diff + satvi_past  +  swir1_diff ) %>% 
  add_model(model_rf)

# Cross validation method again taking into account the ID of the polygon for
# the grouping
cv_folds <- group_vfold_cv(df_train, v = 5, group = ID)
cv_folds

# Define metrics for tuning
my_metrics <- metric_set(accuracy)
# other: roc_auc, accuracy, sens, spec, f_meas

# Tune hyperparameters
rf_fit <- tune_grid(
  wkfl_rf,
  resamples = cv_folds,
  grid = grid_rf,
  metrics = my_metrics,
  control = control_grid(verbose = TRUE) # don't save prediction (imho)
)

# Show and plot results
rf_fit
collect_metrics(rf_fit)
autoplot(rf_fit, metric = "accuracy")
show_best(rf_fit, metric = "accuracy")
select_best(rf_fit, metric = "accuracy")

# Show the importance of the variables
wkfl_rf %>% 
  finalize_workflow(select_best(rf_fit, metric = "accuracy")) %>% 
  fit(data = df_train)  %>% 
  extract_fit_parsnip() %>% 
  vip(num_features = 3)

# Select the best model
tuned_model <-  
  wkfl_rf %>%
  finalize_workflow(select_best(rf_fit, metric = "accuracy")) %>% 
  fit(data = df_train)  %>% 
  extract_fit_parsnip()

# Save model  
saveRDS(tuned_model, file=here("models", name_model))

# Make prediction on test data and create confusion matrix
df_test$prediction <- predict(tuned_model, df_test)[[1]]
pred <- df_test[,c("damage_class", "prediction")]
confusionMatrix(pred$prediction, pred$damage_class )



