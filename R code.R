##########################################
# TITLE: retention analysis
# AUTHOR: Jake Morrison
# DATE:               DETAIL:
# 12/07/20            created program
##########################################
#install.packages("naivebayes")

# setup #

setwd("N:/Projects/Retention Study/GPA Deviation")


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


rm(list = ls()) # remove all enviornment items

# Prep Data #

d2016 <- read.csv("2016.csv", header=T, sep =",")
d2017 <- read.csv("2017.csv", header=T, sep =",")
d2018 <- read.csv("2018.csv", header=T, sep =",")
d2019 <- read.csv("2019.csv", header=T, sep =",")

d2016 <- d2016 %>% mutate(year = 2016)
d2017 <- d2017 %>% mutate(year = 2017)
d2018 <- d2018 %>% mutate(year = 2018)
d2019 <- d2019 %>% mutate(year = 2019)

data <- rbind(d2016,d2017,d2018,d2019)

rm(d2016,d2017,d2018,d2019)

data <- data %>% filter(!is.na(HS_GPA))

# 2 qtr retention #

ret <- data %>% filter(RETAINED_2Q == 1)
n_ret <- data %>% filter(RETAINED_2Q == 0)

summary(ret$TERM1_DEVIATION)
summary(n_ret$TERM1_DEVIATION)

# 1 year retention #

ret <- data %>% filter(YEAR_1_RETAINED == 1)
n_ret <- data %>% filter(YEAR_1_RETAINED == 0)

summary(ret$TERM3_CUM_DEVIATION, na.rm = TRUE)
summary(n_ret$TERM3_CUM_DEVIATION, na.rm = TRUE)

# generate factor variables #

data$RACE <- as.factor(data$RACE)
data$GENDER <- as.factor(data$GENDER)
data$FIRST_GEN <- as.factor(data$FIRST_GEN)
data$FYE <- as.factor(data$FYE)

# put unmet need in thousands #

data <- data %>% mutate(UNMET_NEED = (UNMET_NEED/1000))

data <- data %>% filter(-TERM2_CUM_DEVIATION != HS_GPA)

data <- data %>% filter(RETAINED_1Q == 1)

# simple lpm #

simp <- data %>% select(YEAR_1_RETAINED,RETAINED_2Q,TERM1_CUM_DEVIATION,TERM2_CUM_DEVIATION
                        ,TERM3_CUM_DEVIATION,CREDITS,RUNNING_START,RACE,GENDER,FIRST_GEN,FYE,UNMET_NEED,year,MAJOR)

a <- lm.cluster(data = simp, RETAINED_2Q ~ TERM2_CUM_DEVIATION + UNMET_NEED + CREDITS + RUNNING_START + RACE + GENDER
        + FIRST_GEN + FYE + year - 1, cluster = "MAJOR")

summary(a)

b <- lm(data = simp, YEAR_1_RETAINED ~ TERM3_CUM_DEVIATION + UNMET_NEED + CREDITS + RUNNING_START
                + RACE + GENDER + FIRST_GEN + FYE + year - 1)

summary(b)

b <- lm.cluster(data = simp, YEAR_1_RETAINED ~ TERM3_CUM_DEVIATION + UNMET_NEED + CREDITS + RUNNING_START 
        + RACE + GENDER + FIRST_GEN + FYE + year - 1 + interact, cluster = "MAJOR")

summary(b)

# Graphing #

d <- lm(data = simp, YEAR_1_RETAINED ~ TERM3_CUM_DEVIATION + UNMET_NEED + CREDITS + RUNNING_START
        + RACE + GENDER + FIRST_GEN + FYE + year - 1)

summary(d)

simp$predicted <- predict(d, newdata = simp, type = 'response')

simp <- simp %>% mutate(predicted = case_when(predicted > 1 ~ 1
                                              , predicted < 0 ~ 0
                                              , TRUE ~ predicted))

ggplot(data = simp, aes(x=TERM3_CUM_DEVIATION , y=predicted)) + 
  stat_smooth(method = "glm", 
              method.args = list(family = "binomial")) + ylab("Probability of Persistance") +
  xlab("GPA Deviation") +
  labs(title = "Students likelihood of Persisting based on GPA Deviations")

## simple logistic ##


# convert to factor #

simp$RUNNING_START <- as.factor(simp$RUNNING_START)
simp$RETAINED_2Q <- as.factor(simp$RETAINED_2Q)

c <- glm(data = simp, RETAINED_2Q ~ TERM2_CUM_DEVIATION + UNMET_NEED + CREDITS + RUNNING_START + RACE + GENDER + FIRST_GEN + FYE, family = "binomial")

summary(c)

# add predicted values #

simp$predicted <- predict(m, newdata = simp, type = 'response')

# reorder #

simp <- simp %>% arrange(desc(RETAINED_2Q))

# scatter plot #

ggplot(data = simp, aes(x=TERM3_CUM_DEVIATION , y=predicted)) + 
  stat_smooth(method = "glm", 
                             method.args = list(family = "binomial"))

ggplot(data = simp, aes(x=TERM2_CUM_DEVIATION , y=predicted)) + 
  geom_smooth()

ggplot(data = simp, aes(x=UNMET_NEED , y=predicted)) + 
 geom_smooth(method="gam")



# split data to non-retained students #

simp_n_ret <- simp %>% filter(RETAINED_2Q == 0)

simp_n_ret$predicted <- predict(m, newdata = simp_n_ret, type = 'response')

ggplot(data = simp_n_ret, aes(x=TERM2_CUM_DEVIATION , y=predicted)) + 
  geom_point() + geom_smooth()

# confidence interval

confint(d)



