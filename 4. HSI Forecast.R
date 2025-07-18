##########################################
# TITLE: HSI Proportion Forecast
# AUTHOR: Jake Morrison
# DESCRIPTION: Forecasts the proportion of Hispanic/Latino students
#              to support HSI (Hispanic-Serving Institution) status tracking.
##########################################

# ---- Setup ----

setwd("N:/Projects/hsi_proportion_forecast")

# Load required packages
library(tidyr)
library(dplyr)
library(stringr)
library(purrr)
library(ggplot2)
library(data.table)
library(Hmisc)
library(dummies)
library(doBy)
library(forecast)

# Clear environment
rm(list = ls())

# ---- Load Data ----

enr <- read.csv("enr.csv")  # Contains student enrollment by term and ethnicity

# ---- Calculate Proportions ----

# Calculate total students per period
enr <- enr %>%
  group_by(PERIOD) %>%
  mutate(total_students = sum(STUDENTS)) %>%
  ungroup()

# Calculate percent of each ethnic group
enr <- enr %>%
  mutate(proportion = round((STUDENTS / total_students) * 100, 2))

# ---- Filter for Forecast Analysis ----

# Remove summer terms (terms ending in '5')
enr <- enr %>% filter(substr(as.character(PERIOD), 6, 6) != '5')

# Keep only Hispanic/Latino group
enr <- enr %>% filter(ETHNICITY == "Hispanic/Latino")

# ---- Visualization: Raw Time Series ----

ggplot(enr, aes(x = PERIOD, y = proportion)) +
  geom_point() +
  geom_line() +
  labs(title = "Hispanic Student Proportion by Term", y = "Proportion (%)", x = "Term")

# ---- Transform & Convert to Time Series ----

# Convert PERIOD to factor and log-transform proportions
enr$PERIOD <- as.factor(enr$PERIOD)
enr$proportion <- log(enr$proportion)

# Create time series object: Quarterly frequency starting from Fall 2006 (assumed 2006.4)
tsdata <- ts(enr$proportion, frequency = 4, start = c(2006, 4))

# ---- Forecast with ARIMA ----

# Automatically fit ARIMA model
autoarima1 <- auto.arima(tsdata)

# Forecast next 35 periods (approximately 9 years)
forecast1 <- forecast(autoarima1, h = 35)

# Reverse log transformation
forecast1$mean <- exp(forecast1$mean)
forecast1$upper <- exp(forecast1$upper)
forecast1$lower <- exp(forecast1$lower)
forecast1$x <- exp(forecast1$x)

# ---- Visualizations ----

# Plot forecast with horizontal line for 25% HSI threshold
gg <- autoplot(forecast1) +
  geom_hline(yintercept = 25, linetype = "dashed", lwd = 1) +
  theme_bw() +
  labs(
    title = "Forecasted Full-Time Undergraduate Hispanic Student Proportion",
    y = "Proportion (%)",
    x = "Term"
  )

# Display forecast and residual diagnostics
plot(forecast1)
plot(forecast1$residuals)

# Forecast plot with threshold
plot(gg)

# ---- Model Diagnostics ----

# Residual normality check
qqnorm(forecast1$residuals)
qqline(forecast1$residuals)

# Check autocorrelation of residuals
pacf(forecast1$residuals)

# Model summary and accuracy
summary(autoarima1)
accuracy(autoarima1)
