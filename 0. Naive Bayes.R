##########################################
# TITLE: Retention Analysis
# AUTHOR: Jake Morrison
# DESCRIPTION: This script performs a Naive Bayes classification 
# to predict student retention using historical student data.
##########################################

# ---- Setup ----

# Set working directory
setwd("N:/Projects/Retention Study/warning")

# Load necessary libraries
library(tidyr)       # for data tidying
library(dplyr)       # for data manipulation
library(stringr)     # for string operations
library(purrr)       # for functional programming
library(ggplot2)     # for data visualization
library(data.table)  # for fast data reading
library(Hmisc)       # for utility functions (e.g., %nin%)
library(dummies)     # for creating dummy variables
library(class)       # for classification functions
library(gmodels)     # for crosstabs
library(e1071)       # includes naiveBayes implementation
library(naivebayes)  # alternative naive Bayes implementation

# Clear environment
rm(list = ls())      

# ---- Load and Combine Data ----

# Read CSV files for four years of student cohorts
c17 <- read.csv("2017.csv", header = TRUE, sep = ",")
c18 <- read.csv("2018.csv", header = TRUE, sep = ",")
c19 <- read.csv("2019.csv", header = TRUE, sep = ",")
c20 <- read.csv("2020.csv", header = TRUE, sep = ",")

# Add year identifier to each dataset
c17 <- c17 %>% mutate(year = 2017)
c18 <- c18 %>% mutate(year = 2018)
c19 <- c19 %>% mutate(year = 2019)
c20 <- c20 %>% mutate(year = 2020)

# Combine datasets into a single dataframe
data_b <- rbind(c17, c18, c19, c20)

# Recode 'RETAINED_YE' as a factor with specific labels
data_b$RETAINED_YE <- factor(data_b$RETAINED_YE, 
                             levels = c("retained", "stopped-out"),
                             labels = c("retained", "stopped-out"))

# Filter to keep only students who were retained in the 2nd quarter
data_b <- data_b %>% filter(RETAINED_2Q == 1)

# Exclude 2020 data from training/testing (used later for prediction)
data_b <- data_b %>% filter(year != 2020)

# Drop 'year' column
data_b <- data_b %>% select(-year)

# ---- Create Training and Testing Sets ----

# Define sample size (75% for training)
smp_size <- floor(0.75 * nrow(data_b))

# Set seed for reproducibility
set.seed(123)

# Create random training indices
train_ind <- sample(seq_len(nrow(data_b)), size = smp_size)

# Split into training and testing datasets
train <- data_b[train_ind, ]
test <- data_b[-train_ind, ]

# Extract labels (RETAINED_YE column)
train_labels <- train[, 21]
test_labels  <- test[, 21]

# Drop label and identifier columns from training/testing sets
train <- train[, -c(1, 21:23)]  # remove PIDM and retention fields
test  <- test[, -c(1, 21:23)]

# ---- Train Naive Bayes Model ----

# Train the model with Laplace smoothing
m <- naiveBayes(train, train_labels, laplace = 200)

# Predict retention outcomes on test set
retain_test_pred <- predict(m, test)

# Create a confusion matrix of predicted vs actual
CrossTable(x = test_labels, y = retain_test_pred, prop.chisq = FALSE)

# ---- Apply Model to 2020 Cohort ----

# Filter 2020 data to only include students retained in 2nd quarter
c20 <- c20 %>% filter(RETAINED_2Q == 1)

# Predict retention outcome using trained model
c20$predicted <- predict(m, newdata = c20, type = 'class')

# Extract UIDs of students predicted to stop out
nbpred <- c20 %>% filter(predicted == 'stopped-out') %>% select(PERSON_UID)

# Write prediction results to CSV
write.csv(nbpred, file = 'nbpred_202120.csv', row.names = FALSE)
write.csv(c20, file = 'nbpred_202120_1.csv', row.names = FALSE)
