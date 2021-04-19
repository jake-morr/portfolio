setwd("N:/Projects/Retention Study/FYE")

#install.packages("pacman")

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
library(miceadds)
library(car)
library(randomForest)
library(pacman)
library(caret)



rm(list = ls()) # remove all enviornment items

# Prep Data #

d2016 <- read.csv("2016.csv", header=T, sep =",")
d2017 <- read.csv("2017.csv", header=T, sep =",")
d2018 <- read.csv("2018.csv", header=T, sep =",")
d2015 <- read.csv("2015.csv", header=T, sep =",")
d2019 <- read.csv("2019.csv", header=T, sep =",")

d2016 <- d2016 %>% mutate(year = 2016)
d2017 <- d2017 %>% mutate(year = 2017)
d2018 <- d2018 %>% mutate(year = 2018)
d2015 <- d2015 %>% mutate(year = 2015)
d2019 <- d2019 %>% mutate(year = 2019)

data <- rbind(d2016,d2017,d2018,d2015,d2019)

rm(d2016,d2017,d2018,d2015,d2019)

# summarize data #

data <- data %>% mutate(n = 1)

z <- data %>% group_by(year) %>% 
  summarize(n = sum(n)
  )

y <- data %>% group_by(MATH_READY) %>% 
  summarize(n = sum(n)
  )

x <- data %>% filter(!is.na(FAILED_FYE)) %>%
  group_by(year) %>% 
  summarize(fail_rate = round((mean(FAILED_FYE))*100,2)
            , fail_n = sum(FAILED_FYE)
            , attempts = sum(FYE)
  )

w <- data %>% group_by(year) %>% 
  summarize(q1 = sum(RETAINED_1Q)
            , q2 = sum(RETAINED_2Q)
            , f2f = sum(YEAR_1_RETAINED)
  )

# generate factor variables #

data$RACE <- as.factor(data$RACE)
data$GENDER <- as.factor(data$GENDER)
data$FIRST_GEN <- as.factor(data$FIRST_GEN)

# taking fye on 1 year and 1 quarter retention rate #

a <- lm(data = data, YEAR_1_RETAINED ~ FYE + EOP + CUM_GPA + CREDITS + RUNNING_START + RACE +
                GENDER +  DORM + MATH_READY + ENGLISH_READY
                + FIRST_GEN + factor(year) - 1)

summary(a)

a1 <- lm(data = data, RETAINED_1Q ~ FYE + EOP + CUM_GPA + CREDITS + RUNNING_START + RACE +
          GENDER +  DORM + MATH_READY + ENGLISH_READY
        + FIRST_GEN + factor(year) - 1)

summary(a1)

###################
# Columns 1 and 2 #
###################

b <- lm.cluster(data = data, YEAR_1_RETAINED ~ FYE + EOP + CREDITS + RUNNING_START + RACE 
        + GENDER + DORM + MATH_READY + ENGLISH_READY
        + FIRST_GEN + factor(year) - 1, cluster = "MAJOR")

summary(b)

b1 <- lm.cluster(data = data, RETAINED_1Q ~ FYE + EOP + CREDITS + RUNNING_START + RACE 
                + GENDER + DORM + MATH_READY + ENGLISH_READY
                + FIRST_GEN + factor(year) - 1, cluster = "MAJOR")

summary(b1)

###### break ######

c <- glm(data = data, YEAR_1_RETAINED ~ FYE + CUM_GPA + CREDITS + RUNNING_START + RACE 
        + GENDER + DORM + MATH_READY + ENGLISH_READY
        + FIRST_GEN + factor(year) - 1, family = 'binomial')

summary(c)

c1 <- glm(data = data, RETAINED_1Q ~ FYE + CUM_GPA + CREDITS + RUNNING_START + RACE 
         + GENDER + DORM + MATH_READY + ENGLISH_READY
         + FIRST_GEN + factor(year) - 1, family = 'binomial')

summary(c1)

# failing fye on 1 year and 1 quarter retention rate #

d <- lm(data = data, YEAR_1_RETAINED ~ FAILED_FYE + EOP + CREDITS + RUNNING_START + RACE +
          GENDER +  DORM + MATH_READY + ENGLISH_READY
        + FIRST_GEN + factor(year) - 1)

summary(d)

g <- lm(data = data, RETAINED_1Q ~ FAILED_FYE + EOP + CREDITS + RUNNING_START + RACE +
          GENDER +  DORM + MATH_READY + ENGLISH_READY
        + FIRST_GEN + factor(year) - 1)

summary(g)

###################
# Column 3 and 4  #
###################

e <- lm.cluster(data = data, YEAR_1_RETAINED ~ FAILED_FYE + EOP + CREDITS + RUNNING_START + RACE 
                + GENDER + DORM + MATH_READY + ENGLISH_READY
                + FIRST_GEN + factor(year) - 1, cluster = "MAJOR")

summary(e)

h <- lm.cluster(data = data, RETAINED_1Q ~ FAILED_FYE + EOP + CREDITS + RUNNING_START + RACE 
                + GENDER + DORM + MATH_READY + ENGLISH_READY
                + FIRST_GEN + factor(year) - 1, cluster = "MAJOR")

summary(h)

###### break #####

############
# Column 5 #
############

h1 <- lm.cluster(data = data, RETAINED_1Q ~ GRADE + EOP + CREDITS + RUNNING_START + RACE 
                + GENDER + DORM + MATH_READY + ENGLISH_READY
                + FIRST_GEN + factor(year) - 1, cluster = "MAJOR")

summary(h1)

##### break #####

h2 <- lm.cluster(data = data, YEAR_1_RETAINED ~ GRADE + EOP + CREDITS + RUNNING_START + RACE 
                 + GENDER + DORM + MATH_READY + ENGLISH_READY
                 + FIRST_GEN + factor(year) - 1, cluster = "MAJOR")

summary(h2)

##### break #####

f <- glm(data = data, RETAINED_1Q ~ GRADE + EOP + CREDITS + RUNNING_START + RACE 
         + GENDER + DORM + MATH_READY + ENGLISH_READY
         + FIRST_GEN + factor(year) - 1, family = 'binomial')

summary(f)

i <- glm(data = data, RETAINED_1Q ~ FAILED_FYE + EOP + CUM_GPA + CREDITS + RUNNING_START + RACE 
         + GENDER + DORM + MATH_READY + ENGLISH_READY
         + FIRST_GEN + factor(year) - 1, family = 'binomial')

summary(i)

# Random forest survival model #

data$YEAR_1_RETAINED <- as.factor(data$YEAR_1_RETAINED)

data <- data %>% select(-c('MAJOR','RETAINED_1Q','RETAINED_2Q','PERSON_UID'))

set.seed(49)
train <- data %>% sample_frac(.70)
test <- data %>% anti_join(train)

control <- trainControl(method = "repeatedcv",
                        number = 10,
                        repeats = 3,
                        search = "random")

rf <- train(YEAR_1_RETAINED ~ ., data = train,
            method = "rf",
            metric = "Accuracy",
            trControl = control)

rf$finalModel

# ret_pred <- rf$finalModel %>% 
#    predict(newdata = test)

ret_pred <- predict.train(rf,newdata = test)


table(
  actualclass = test$YEAR_1_RETAINED,
  predictedclass = ret_pred
) %>% 
  confusionMatrix() %>% 
  print()

varImpPlot(rf$finalModel)
