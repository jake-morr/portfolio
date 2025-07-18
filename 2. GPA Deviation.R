##########################################
# TITLE: Retention Analysis using GPA Deviation
# AUTHOR: Jake Morrison
# DATE: 12/07/20
# DESCRIPTION: Analyze the impact of GPA deviation, unmet need,
#              and other variables on student retention.
##########################################

# ---- Setup ----

setwd("N:/Projects/Retention Study/GPA Deviation")

# Load required packages
library(tidyr)
library(dplyr)
library(stringr)
library(purrr)
library(ggplot2)
library(data.table)
library(Hmisc)
library(dummies)
library(class)
library(gmodels)
library(e1071)
library(naivebayes)
library(miceadds)
library(car)

# Clear environment
rm(list = ls())

# ---- Load & Combine Data ----

# Read cohort data
d2016 <- read.csv("2016.csv")
d2017 <- read.csv("2017.csv")
d2018 <- read.csv("2018.csv")
d2019 <- read.csv("2019.csv")

# Add cohort year
d2016$year <- 2016
d2017$year <- 2017
d2018$year <- 2018
d2019$year <- 2019

# Combine datasets
data <- bind_rows(d2016, d2017, d2018, d2019)

# Remove originals to save memory
rm(d2016, d2017, d2018, d2019)

# ---- Data Filtering & Transformation ----

# Keep only students with high school GPA
data <- data %>% filter(!is.na(HS_GPA))

# Compare GPA deviation by 2nd quarter retention
summary(data %>% filter(RETAINED_2Q == 1) %>% pull(TERM1_DEVIATION))
summary(data %>% filter(RETAINED_2Q == 0) %>% pull(TERM1_DEVIATION))

# Compare GPA deviation by 1st year retention
summary(data %>% filter(YEAR_1_RETAINED == 1) %>% pull(TERM3_CUM_DEVIATION), na.rm = TRUE)
summary(data %>% filter(YEAR_1_RETAINED == 0) %>% pull(TERM3_CUM_DEVIATION), na.rm = TRUE)

# Convert relevant variables to factors
data <- data %>%
  mutate(
    RACE = as.factor(RACE),
    GENDER = as.factor(GENDER),
    FIRST_GEN = as.factor(FIRST_GEN),
    FYE = as.factor(FYE),
    UNMET_NEED = UNMET_NEED / 1000  # Convert unmet need to thousands
  )

# Data cleaning: remove unusual rows
data <- data %>% filter(-TERM2_CUM_DEVIATION != HS_GPA)

# Only include students who were retained through 1st quarter
data <- data %>% filter(RETAINED_1Q == 1)

# ---- Linear Probability Models ----

# Select relevant variables
simp <- data %>% select(
  YEAR_1_RETAINED, RETAINED_2Q, TERM1_CUM_DEVIATION, TERM2_CUM_DEVIATION,
  TERM3_CUM_DEVIATION, CREDITS, RUNNING_START, RACE, GENDER,
  FIRST_GEN, FYE, UNMET_NEED, year, MAJOR
)

# Model 1: LPM for 2nd quarter retention
lpm_q2 <- lm.cluster(
  data = simp,
  RETAINED_2Q ~ TERM2_CUM_DEVIATION + UNMET_NEED + CREDITS + RUNNING_START + RACE +
    GENDER + FIRST_GEN + FYE + year - 1,
  cluster = "MAJOR"
)
summary(lpm_q2)

# Model 2: LPM for 1st year retention
lpm_y1 <- lm(
  data = simp,
  YEAR_1_RETAINED ~ TERM3_CUM_DEVIATION + UNMET_NEED + CREDITS + RUNNING_START +
    RACE + GENDER + FIRST_GEN + FYE + year - 1
)
summary(lpm_y1)

# With cluster-robust SEs
lpm_y1_robust <- lm.cluster(
  data = simp,
  YEAR_1_RETAINED ~ TERM3_CUM_DEVIATION + UNMET_NEED + CREDITS + RUNNING_START +
    RACE + GENDER + FIRST_GEN + FYE + year - 1,
  cluster = "MAJOR"
)
summary(lpm_y1_robust)

# ---- Visualization: Predicted Probability vs GPA Deviation ----

# Refit model for predictions
pred_model <- lm(
  data = simp,
  YEAR_1_RETAINED ~ TERM3_CUM_DEVIATION + UNMET_NEED + CREDITS + RUNNING_START +
    RACE + GENDER + FIRST_GEN + FYE + year - 1
)

# Predict and clamp values between 0 and 1
simp$predicted <- predict(pred_model, newdata = simp)
simp <- simp %>% mutate(predicted = pmin(pmax(predicted, 0), 1))

# Plot predicted retention vs GPA deviation
ggplot(simp, aes(x = TERM3_CUM_DEVIATION, y = predicted)) +
  stat_smooth(method = "glm", method.args = list(family = "binomial")) +
  labs(
    title = "Students' Likelihood of Persisting Based on GPA Deviations",
    x = "GPA Deviation",
    y = "Probability of Persistence"
  )

# ---- Logistic Regression ----

# Convert to factors for logistic modeling
simp <- simp %>%
  mutate(
    RUNNING_START = as.factor(RUNNING_START),
    RETAINED_2Q = as.factor(RETAINED_2Q)
  )

# Logistic model: predicting 2Q retention
log_model <- glm(
  data = simp,
  RETAINED_2Q ~ TERM2_CUM_DEVIATION + UNMET_NEED + CREDITS + RUNNING_START +
    RACE + GENDER + FIRST_GEN + FYE,
  family = "binomial"
)
summary(log_model)

# Predict from logistic model
simp$predicted <- predict(log_model, newdata = simp, type = "response")

# Sort by predicted retention
simp <- simp %>% arrange(desc(RETAINED_2Q))

# ---- Visualization ----

# GPA Deviation vs Prediction
ggplot(simp, aes(x = TERM3_CUM_DEVIATION, y = predicted)) +
  stat_smooth(method = "glm", method.args = list(family = "binomial"))

# TERM2 GPA Deviation vs Prediction
ggplot(simp, aes(x = TERM2_CUM_DEVIATION, y = predicted)) +
  geom_smooth()

# UNMET_NEED vs Prediction
ggplot(simp, aes(x = UNMET_NEED, y = predicted)) +
  geom_smooth(method = "gam")

# ---- Subgroup: Non-Retained Students ----

# Filter to non-retained
simp_n_ret <- simp %>% filter(RETAINED_2Q == 0)

# Predict again
simp_n_ret$predicted <- predict(log_model, newdata = simp_n_ret, type = "response")

# Scatter plot of GPA deviation vs predicted for non-retained
ggplot(simp_n_ret, aes(x = TERM2_CUM_DEVIATION, y = predicted)) +
  geom_point() +
  geom_smooth()

# ---- Confidence Intervals ----
confint(pred_model)
