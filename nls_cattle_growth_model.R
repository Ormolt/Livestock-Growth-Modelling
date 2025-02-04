# Livestock Growth Modelling Analysis
# Yusuf Omotosho
# 2024-05-23

# Set CRAN mirror
options(repos = c(CRAN = "https://cloud.r-project.org/"))

# Install and Load Required Packages
required_packages <- c("minpack.lm", "tidyverse", "readxl")

# Load libraries
library(nlme)
library(minpack.lm)
library(ggplot2)
library(dplyr)
library(readxl)
library(tidyr)
library(purrr)

# Load dataset
cattle_data <- read_excel("cattle_dataset.xlsx")

# Data Overview
print(head(cattle_data))
cat("\nStructure of the Data:\n")
str(cattle_data)

cat("\nSummary Statistics:\n")
print(summary(cattle_data))

# Breed type occurrences
breed_summary <- cattle_data %>% count(Breed_Group, name = "Occurrences")
print(breed_summary)

# Data Quality Checks
# Display any rows with non-finite values for diagnostic purposes
non_finite_rows <- cattle_data %>%
  filter(
    !is.finite(Age_Months) |  # Check for non-finite Age
    !is.finite(Weight_Kg) # Check for non-finite Weight
  )

if (nrow(non_finite_rows) > 0) {
  message("Non-finite values detected. Below are the rows with issues:")
  print(non_finite_rows)
} else {
  message("No non-finite values detected.")
}

# Check for missing values
cat("Missing Values:\n")
print(colSums(is.na(cattle_data)))

# Check for duplicate rows
cat("Duplicate Rows:\n")
print(nrow(cattle_data) - nrow(distinct(cattle_data)))

# Check for outliers using Z-score method
z_scores_Weight <- scale(cattle_data$Weight_Kg)
outliers_Weight <- which(abs(z_scores_Weight) > 3)
cat("Outliers Detected (Weight):\n")
print(outliers_Weight)

z_scores_age <- scale(cattle_data$Age_Months)
outliers_age <- which(abs(z_scores_age) > 3)
cat("Outliers Detected (Age):\n")
print(outliers_age)

# Growth Models
brody_model <- function(Age_Months, A, B, k) A * (1 - B * exp(-k * Age_Months))
vonB_model <- function(Age_Months, A, B, k) A * (1 - exp(-k * Age_Months))^B
log_model <- function(Age_Months, A, B, k) A / (1 + B * exp(-k * Age_Months))

# Model Fitting Function
fit_model <- function(model_func, data) {
  nlsLM(Weight_Kg ~ model_func(Age_Months, A, B, k), 
        data = data,
        start = list(A = 730, B = 0.5, k = 0.01),
        control = nls.lm.control(maxiter = 1000))
}

# Fit models per Breed Group
cattle_list <- split(cattle_data, cattle_data$Breed_Group)
fits <- lapply(cattle_list, function(df) {
  list(
    brody = fit_model(brody_model, df),
    vonB  = fit_model(vonB_model, df),
    log   = fit_model(log_model, df)
  )
})
names(fits) <- names(cattle_list)

# Print results
print(fits)

# Extract Parameters
# Function to extract coefficients from the fitted model
extract_params <- function(model) {
  as.data.frame(summary(model)$coefficients)  # Convert to a structured data frame
}

# Extract parameters for all models
params <- lapply(fits, function(models) {
  list(
    brody = extract_params(models$brody),
    vonB  = extract_params(models$vonB),
    log   = extract_params(models$log)
  )
})

# Convert list structure to a data frame
params_df <- do.call(rbind, lapply(names(params), function(name) {
  data.frame(
    Breed_Group  = name,
    brody_params = paste(capture.output(print(params[[name]]$brody)), collapse = " "),
    vonB_params  = paste(capture.output(print(params[[name]]$vonB)), collapse = " "),
    log_params   = paste(capture.output(print(params[[name]]$log)), collapse = " ")
  )
}))

# Print the formatted results
print(params_df)

# Model Comparison

# Function to compare models and extract AIC, BIC, and R²
compare_models <- function(model) {
  # Handle errors and non-converged models safely
  result <- tryCatch({
    if (!model$convInfo$isConv) return(c(AIC = NA, BIC = NA, R2 = NA))
    
    residuals <- model$m$resid()
    fitted <- model$m$fitted()
    actuals <- fitted + residuals
    
    AIC_val <- AIC(model)
    BIC_val <- BIC(model)
    R2_val <- 1 - sum(residuals^2) / sum((actuals - mean(actuals))^2)
    
    return(c(AIC = AIC_val, BIC = BIC_val, R2 = R2_val))
  }, error = function(e) {
    return(c(AIC = NA, BIC = NA, R2 = NA))
  })
  
  return(result)
}

# Apply `compare_models()` to each model in `fits`
model_metrics <- do.call(rbind, lapply(names(fits), function(name) {
  data.frame(
    Breed_Group   = name,
    brody_AIC     = compare_models(fits[[name]]$brody)["AIC"],
    brody_BIC     = compare_models(fits[[name]]$brody)["BIC"],
    brody_R2      = compare_models(fits[[name]]$brody)["R2"],
    vonB_AIC      = compare_models(fits[[name]]$vonB)["AIC"],
    vonB_BIC      = compare_models(fits[[name]]$vonB)["BIC"],
    vonB_R2       = compare_models(fits[[name]]$vonB)["R2"],
    log_AIC       = compare_models(fits[[name]]$log)["AIC"],
    log_BIC       = compare_models(fits[[name]]$log)["BIC"],
    log_R2        = compare_models(fits[[name]]$log)["R2"]
  )
}))

# Convert to a clean data frame
model_metrics <- as.data.frame(model_metrics)

# Print results
print(model_metrics)

# Convergence Check
check_convergence <- function(model) {
  conv_info <- tryCatch(model$convInfo, error = function(e) NULL)
  if (is.null(conv_info)) return(data.frame(Status = "Error: No convergence info"))
  data.frame(Status = if (conv_info$isConv) "Converged" else "Not Converged", Iterations = conv_info$finIter)
}

convergence_results <- map_dfr(names(fits), function(name) {
  data.frame(
    Breed_Group  = name,
    Brody_Status = check_convergence(fits[[name]]$brody)$Status,
    VonB_Status  = check_convergence(fits[[name]]$vonB)$Status,
    Log_Status   = check_convergence(fits[[name]]$log)$Status
  )
})
print(convergence_results)

# Visualization

# Function to plot all three models together for each breed
plot_growth_comparison <- function(fit, data, breed) {
  # Filter observed data for the specific breed
  observed_data <- data %>%
    filter(Breed_Group == breed)

  pred_data <- data.frame(Age_Months = seq(min(observed_data$Age_Months), max(observed_data$Age_Months), length.out = 100))
  
  # Generate predictions for each model
  pred_data$Brody <- predict(fit$brody, newdata = pred_data)
  pred_data$VonB <- predict(fit$vonB, newdata = pred_data)
  pred_data$Log <- predict(fit$log, newdata = pred_data)

  # Convert to long format for ggplot
  pred_data_long <- pred_data %>%
    pivot_longer(cols = c(Brody, VonB, Log), names_to = "Model", values_to = "Weight_Kg")

  # Create plot
  ggplot() +
    # Observed Data (Filtered to the Specific Breed)
    geom_point(data = observed_data, aes(x = Age_Months, y = Weight_Kg), size = 2, alpha = 0.5, color = "grey") +
    
    # Model Predictions
    geom_line(data = pred_data_long, aes(x = Age_Months, y = Weight_Kg, color = Model, linetype = Model), linewidth = 1) +
    
    scale_color_manual(values = c("red", "green", "blue")) +
    scale_linetype_manual(values = c("dotdash", "solid", "dashed")) +
    labs(
      title = paste(breed, "- Growth Model Comparison"),
      subtitle = "Illustrating Model Fit: Log Model Performs Best",
      x = "Age (months)", y = "Weight (kg)",
      color = "Model",
      linetype = "Model"
    ) +
    theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold"),
      plot.subtitle = element_text(hjust = 0.5),
      legend.position = "bottom",
      panel.grid = element_blank()
    )
}

# Function to plot residuals for each model
plot_residuals <- function(fit, data, breed) {
  # Filter observed data for the specific breed
  observed_data <- data %>%
    filter(Breed_Group == breed)

  # Compute residuals for each model
  observed_data$Residual_Brody <- observed_data$Weight_Kg - predict(fit$brody, newdata = observed_data)
  observed_data$Residual_VonB <- observed_data$Weight_Kg - predict(fit$vonB, newdata = observed_data)
  observed_data$Residual_Log <- observed_data$Weight_Kg - predict(fit$log, newdata = observed_data)

  # Convert to long format
  residuals_long <- observed_data %>%
    pivot_longer(cols = starts_with("Residual_"), names_to = "Model", values_to = "Residuals") %>%
    mutate(Model = gsub("Residual_", "", Model))

  # Create residual plot
  ggplot(residuals_long, aes(x = Age_Months, y = Residuals, color = Model)) +
    geom_point(alpha = 0.5) +
    geom_hline(yintercept = 0, linetype = "dashed") +
    facet_wrap(~Model) +
    labs(
      title = paste(breed, "- Residual Plot for Growth Models"),
      subtitle = "Log Model Has the Smallest Residuals, Indicating the Best Fit",
      x = "Age (months)", y = "Residuals (Kg)"
    ) +
    theme_minimal() +
    theme(panel.grid = element_blank())
}

# --- FUNCTION TO PLOT COMBINED GROWTH MODELS ACROSS BREEDS --- #
plot_combined_growth_models <- function(fits, data) {
  combined_data <- map_dfr(names(fits), function(breed) {
    pred_data <- data.frame(Age_Months = seq(min(data$Age_Months), max(data$Age_Months), length.out = 100))
    pred_data$Brody <- predict(fits[[breed]]$brody, newdata = pred_data)
    pred_data$VonB <- predict(fits[[breed]]$vonB, newdata = pred_data)
    pred_data$Log <- predict(fits[[breed]]$log, newdata = pred_data)
    pred_data$Breed <- breed
    
    pred_data %>%
      pivot_longer(cols = c(Brody, VonB, Log), names_to = "Model", values_to = "Weight_Kg")
  })

  # Create observed data subset with renamed breed group
  observed_data <- data %>%
    mutate(Breed = Breed_Group) %>%
    group_by(Breed)

  # Create combined plot
  ggplot() +
    # Model Predictions (colored lines)
    geom_line(data = combined_data, aes(x = Age_Months, y = Weight_Kg, color = Model, linetype = Model), linewidth = 1) +
    
    # Observed Data (black points for comparison)
    geom_point(data = observed_data, aes(x = Age_Months, y = Weight_Kg), size = 2, alpha = 0.5, color = "grey") +

    # Facet structure with 2 columns for better layout
    facet_wrap(~Breed, ncol = 2) +

    # Customize appearance
    scale_color_manual(values = c("red", "green", "blue")) +
    scale_linetype_manual(values = c("dotdash", "solid", "dashed")) +
    labs(
      title = "Growth Model Comparison for Hybrid and Pure Breed Cattle",
      subtitle = "Illustrating the Fit of Brody, Von Bertalanffy, and Log Models",
      x = "Age (months)", y = "Weight (kg)",
      color = "Model",
      linetype = "Model"
    ) +
    
    theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold"),
      plot.subtitle = element_text(hjust = 0.5),
      legend.position = "bottom",
      panel.grid = element_blank()
    )
}

# Generate and print plots for each breed group
walk(names(fits), function(breed) {
  print(plot_growth_comparison(fits[[breed]], cattle_data, breed))
  print(plot_residuals(fits[[breed]], cattle_data, breed))
})

# Generate and print the optimized combined growth model plot
print(plot_combined_growth_models(fits, cattle_data))