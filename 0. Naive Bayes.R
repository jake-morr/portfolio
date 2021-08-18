##########################################
# TITLE: retention analysis
# AUTHOR: Jake Morrison
# DATE:               DETAIL:
# 12/07/20            created program
##########################################
#install.packages("naivebayes")

# setup #

setwd("N:/Projects/Retention Study/warning")


library(tidyr)      # data manipulation
library(dplyr)      # data manipulation
library(stringr)
library(purrr)
library(ggplot2)    # data visualization
library(data.table) # data loading speed
library(Hmisc)      # for %nin%
library(dummies)    # for creating dummy variables
library(class)
library(gmodels)
library(e1071)
library(naivebayes)


rm(list = ls()) # remove all enviornment items


c17 <- read.csv("2017.csv", header=T, sep =",")
c18 <- read.csv("2018.csv", header=T, sep =",")
c19 <- read.csv("2019.csv", header=T, sep =",")
c20 <- read.csv("2020.csv", header=T, sep =",")

c17 <- c17 %>% mutate(year = 2017)
c18 <- c18 %>% mutate(year = 2018)
c19 <- c19 %>% mutate(year = 2019)
c20 <- c20 %>% mutate(year = 2020)

data_b <- rbind(c17,c18,c19,c20)

data_b$RETAINED_YE <- factor(data_b$RETAINED_YE, levels = c("retained","stopped-out"),
                        labels = c("retained","stopped-out"))

data_b <- data_b %>% filter(RETAINED_2Q == 1)

data_b <- data_b %>% filter(year != 2020)

data_b <- data_b %>% select(-year)

smp_size <- floor(0.75 * nrow(data_b))



set.seed(123)

train_ind <- sample(seq_len(nrow(data_b)),size = smp_size)

train <- data_b[train_ind,]
test <- data_b[-train_ind,]

train_labels <- train[,21]
test_labels <- test[,21]

# train_labels <- factor(train_lebels, levels = c("1","0"),
#                         labels = c("retained","stop-out"))
# 
# test_labels <- factor(test_labels, levels = c("1","0"),
#                       labels = c("retained","stop-out"))

train <- train[,-(21:23)] # remove retained fields
test <- test[,-(21:23)]
train <- train[,-1] # remove PIDM
test <- test[,-1]
# train <- train[,-8] # remove age admitted
# test <- test[,-8]
# train <- train[,-5] # remove dorm
# test <- test[,-5]
# train <- train[,-5] # remove declared
# test <- test[,-5]
# train <- train[,-12] # remove days diff
# test <- test[,-12]
# train <- train[,-6] # remove entering credits
# test <- test[,-6]


m <- naiveBayes(train,train_labels,laplace = 200)

retain_test_pred <- predict(m,test)

CrossTable(x = test_labels, y = retain_test_pred,
           prop.chisq = FALSE)
# prediction #

c20 <- c20 %>% filter(RETAINED_2Q == 1)

c20$predicted <- predict(m, newdata = c20, type = 'class')

nbpred <- c20 %>% filter(predicted == 'stopped-out') %>% select(PERSON_UID) 

write.csv(nbpred, file = 'nbpred_202120.csv', row.names = FALSE)

write.csv(c20, file = 'nbpred_202120_1.csv', row.names = FALSE)
