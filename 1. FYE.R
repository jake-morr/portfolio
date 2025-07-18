#############################################
# TITLE: FYE Retention Study - Modeling
# AUTHOR: Jake Morrison
# DESCRIPTION: Linear, logistic, and random forest models 
#              to examine predictors of retention outcomes.
#############################################

# ---- Setup ----

setwd("N:/Projects/Retention Study/FYE")

# Load required packages
library(tidyr)         # data manipulation
library(dplyr)         # data manipulation
library(stringr)       # string operations
library(purrr)         # functional programming
library(ggplot2)       # plotting
library(data.table)    # fast data loading
library(Hmisc)         # extra functions like %nin%
library(dummies)       # dummy variable creation
library(class)         # classification tools
library(gmodels)       # crosstabs
library(e1071)         # naive Bayes and support vector machines
library(naivebayes)    # alternative naive Bayes package
library(miceadds)      # cluster-robust SEs via lm.cluster
library(car)           # diagnostics
library(randomForest)  # random forest modeling
library(pacman)        # package management
library(caret)         # machine learning workflows

# Clear environment
rm(list = ls())

# ---- Load & Prepare Data ----

# Load yearly datasets
d2015 <- read.csv("2015.csv")
d2016 <- read.csv("2016.csv")
d2017 <- read.csv("2017.csv")
d2018 <- read.csv("2018.csv")
d2019 <- read.csv("2019.csv")

# Add year field to each dataset
d2015$year <- 2015
d2016$year <- 2016
d2017$year <- 2017
d2018$year <- 2018
d2019$year <- 2019

# Combine all years into one dataset
data <- bind_rows(d2015, d2016, d2017, d2018, d2019)

# Clean up environment
rm(d2015, d2016, d2017, d2018, d2019)

# ---- Summarize Data ----

data <- data %>% mutate(n = 1)

# Total count by year
z <- data %>% group_by(year) %>% summarize(n = sum(n))

# Count by math readiness
y <- data %>% group_by(MATH_READY) %>% summarize(n = sum(n))

# FYE failure rate by year
x <- data %>%
  filter(!is.na(FAILED_FYE)) %>%
  group_by(year) %>%
  summarize(
    fail_rate = round(mean(FAILED_FYE) * 100, 2),
    fail_n = sum(FAILED_FYE),
    attempts = sum(FYE)
  )

# Retention by year
w <- data %>%
  group_by(year) %>%
  summarize(
    q1 = sum(RETAINED_1Q),
    q2 = sum(RETAINED_2Q),
    f2f = sum(YEAR_1_RETAINED)
  )

# ---- Convert Variables to Factors ----

data$RACE <- as.factor(data$RACE)
data$GENDER <- as.factor(data$GENDER)
data$FIRST_GEN <- as.factor(data$FIRST_GEN)

# ---- Linear Models: FYE and Retention ----

# FYE participation effect
a <- lm(YEAR_1_RETAINED ~ FYE + EOP + CUM_GPA + CREDITS + RUNNING_START + RACE +
          GENDER + DORM + MATH_READY + ENGLISH_READY + FIRST_GEN + factor(year) - 1, data = data)
summary(a)

a1 <- lm(RETAINED_1Q ~ FYE + EOP + CUM_GPA + CREDITS + RUNNING_START + RACE +
           GENDER + DORM + MATH_READY + ENGLISH_READY + FIRST_GEN + factor(year) - 1, data = data)
summary(a1)

# Clustered SEs by MAJOR
b <- lm.cluster(YEAR_1_RETAINED ~ FYE + EOP + CREDITS + RUNNING_START + RACE + 
                  GENDER + DORM + MATH_READY + ENGLISH_READY + FIRST_GEN + factor(year) - 1,
                cluster = "MAJOR", data = data)
summary(b)

b1 <- lm.cluster(RETAINED_1Q ~ FYE + EOP + CREDITS + RUNNING_START + RACE + 
                   GENDER + DORM + MATH_READY + ENGLISH_READY + FIRST_GEN + factor(year) - 1,
                 cluster = "MAJOR", data = data)
summary(b1)

# ---- Logistic Models: FYE and Retention ----

c <- glm(YEAR_1_RETAINED ~ FYE + CUM_GPA + CREDITS + RUNNING_START + RACE + 
           GENDER + DORM + MATH_READY + ENGLISH_READY + FIRST_GEN + factor(year) - 1,
         data = data, family = 'binomial')
summary(c)

c1 <- glm(RETAINED_1Q ~ FYE + CUM_GPA + CREDITS + RUNNING_START + RACE + 
            GENDER + DORM + MATH_READY + ENGLISH_READY + FIRST_GEN + factor(year) - 1,
          data = data, family = 'binomial')
summary(c1)

# ---- Impact of Failing FYE ----

# OLS models
d <- lm(YEAR_1_RETAINED ~ FAILED_FYE + EOP + CREDITS + RUNNING_START + RACE + 
          GENDER + DORM + MATH_READY + ENGLISH_READY + FIRST_GEN + factor(year) - 1, data = data)
summary(d)

g <- lm(RETAINED_1Q ~ FAILED_FYE + EOP + CREDITS + RUNNING_START + RACE + 
          GENDER + DORM + MATH_READY + ENGLISH_READY + FIRST_GEN + factor(year) - 1, data = data)
summary(g)

# Clustered SEs
e <- lm.cluster(YEAR_1_RETAINED ~ FAILED_FYE + EOP + CREDITS + RUNNING_START + RACE + 
                  GENDER + DORM + MATH_READY + ENGLISH_READY + FIRST_GEN + factor(year) - 1,
                cluster = "MAJOR", data = data)
summary(e)

h <- lm.cluster(RETAINED_1Q ~ FAILED_FYE + EOP + CREDITS + RUNNING_START + RACE + 
                  GENDER + DORM + MATH_READY + ENGLISH_READY + FIRST_GEN + factor(year) - 1,
                cluster = "MAJOR", data = data)
summary(h)

# ---- Effect of FYE Grade ----

h1 <- lm.cluster(RETAINED_1Q ~ GRADE + EOP + CREDITS + RUNNING_START + RACE + 
                   GENDER + DORM + MATH_READY + ENGLISH_READY + FIRST_GEN + factor(year) - 1,
                 cluster = "MAJOR", data = data)
summary(h1)

h2 <- lm.cluster(YEAR_1_RETAINED ~ GRADE + EOP + CREDITS + RUNNING_START + RACE + 
                   GENDER + DORM + MATH_READY + ENGLISH_READY + FIRST_GEN + factor(year) - 1,
                 cluster = "MAJOR", data = data)
summary(h2)

# Logistic regression with FYE grade
f <- glm(RETAINED_1Q ~ GRADE + EOP + CREDITS + RUNNING_START + RACE + 
           GENDER + DORM + MATH_READY + ENGLISH_READY + FIRST_GEN + factor(year) - 1,
         family = 'binomial', data = data)
summary(f)

# Logistic model: Failed FYE with cumulative GPA
i <- glm(RETAINED_1Q ~ FAILED_FYE + EOP + CUM_GPA + CREDITS + RUNNING_START + RACE + 
           GENDER + DORM + MATH_READY + ENGLISH_READY + FIRST_GEN + factor(year) - 1,
         family = 'binomial', data = data)
summary(i)

# ---- Random Forest Model for Retention Prediction ----

# Convert outcome to factor
data$YEAR_1_RETAINED <- as.factor(data$YEAR_1_RETAINED)

# Drop ID and other known retention columns
data <- data %>% select(-c(MAJOR, RETAINED_1Q, RETAINED_2Q, PERSON_UID))

# Split into train/test
set.seed(49)
train <- data %>% sample_frac(0.70)
test <- data %>% anti_join(train)

# Set up training control
control <- trainControl(method = "repeatedcv",
                        number = 10,
                        repeats = 3,
                        search = "random")

# Train random forest
rf <- train(YEAR_1_RETAINED ~ ., data = train,
            method = "rf",
            metric = "Accuracy",
            trControl = control)

# Display final model summary
print(rf$finalModel)

# Predict retention on test set
ret_pred <- predict.train(rf, newdata = test)

# Confusion matrix
confusionMatrix(
  data = ret_pred,
  reference = test$YEAR_1_RETAINED
) %>% print()

# Variable importance plot
varImpPlot(rf$finalModel)
