# ==================================================================================================
#   Program:      JED Healthy Minds Survey Analysis    
#   Description:  Statistical Analysis of the Campus wide JED Healthy Minds Survey  
#   
#   Modification History:
#   
#   Date         Programmer      Description
# 09/22/20     Jake Morrison    env_mh analysis
# ==================================================================================================*/


library(tidyverse)
library(psych)
library(haven)
library(tidyr)      # data manipulation
library(dplyr)      # data manipulation
library(stringr)
library(purrr)
library(ggplot2)    # data visualization
library(data.table) # data loading speed
library(Hmisc)      # for %nin%
library(dummies)    # for creating dummy variables


rm(list = ls(all = TRUE)) # remove all environment items

setwd("N:/Projects/JED")

################
# Read in data #
################

jed <- read_dta(file= "EastWash.dta")

###########################################
# generating race and sexuality variables #
###########################################

jed <- jed %>% mutate (race = case_when(race_black == 1 ~ "Black"
                                        , race_ainaan == 1 ~ "American Indian or Alaskan native"
                                        , race_asian == 1 ~ "Asian American / Asian"
                                        , race_his == 1 ~ "Hispanic / Latino/a"
                                        , race_pi == 1 ~ "Native Hawaiian or Pacific Islander"
                                        , race_mides == 1 ~ "Middle Eastern, Arab, or Arab American"
                                        , race_white == 1 ~ "White"
                                        , race_other == 1 ~ "Other"
                                        , TRUE ~ ""))

jed <- jed %>% mutate(sexuality = case_when(sexual_h == 1 ~ "heterosexual"
                                            , sexual_l == 1 ~ "lesbian"
                                            , sexual_g == 1 ~ "gay"
                                            , sexual_bi == 1 ~ "bi"
                                            , sexual_other == 1 ~ "other"
                                            , sexual_queer == 1 ~ "queer"
                                            , sexual_quest == 1 ~ "quest"
                                            , TRUE ~ ""))

#############################
# selecting data for env_mh #
#############################

data_env_mh <- jed %>% select(env_mh,age,sex_birth,gender,sexual_h,sexual_l,sexual_g,sexual_bi,sexual_queer,sexual_quest,
                              sexual_other,relship,race_black,race_ainaan,race_asian,race_his,race_pi,race_mides,race_white,
                              race_other,enroll,gpa_sr,aca_impa,persist)

data_env_mh <- data_env_mh %>% mutate(sexuality = case_when(sexual_h == 1 ~ "heterosexual"
                                                            , sexual_l == 1 ~ "lesbian"
                                                            , sexual_g == 1 ~ "gay"
                                                            , sexual_bi == 1 ~ "bi"
                                                            , sexual_other == 1 ~ "other"
                                                            , sexual_queer == 1 ~ "queer"
                                                            , sexual_quest == 1 ~ "quest"
                                                            , TRUE ~ ""))

data_env_mh <- data_env_mh %>% mutate (lgbtq = case_when(sexuality == "heterosexual" ~ 0
                                                         , sexuality == "lesbian" ~ 1
                                                         , sexuality == "gay" ~ 1
                                                         , sexuality == "bi" ~ 1
                                                         , sexuality == "other" ~ 1
                                                         , sexuality == "queer" ~ 1
                                                         , sexuality == "quest" ~ 1
                                                         , TRUE ~ 2 ))

table(data_env_mh$lgbtq)

data_env_mh <- data_env_mh %>% mutate (race = case_when(race_black == 1 ~ "Black"
                                                        , race_ainaan == 1 ~ "American Indian or Alaskan native"
                                                        , race_asian == 1 ~ "Asian American / Asian"
                                                        , race_his == 1 ~ "Hispanic / Latino/a"
                                                        , race_pi == 1 ~ "Native Hawaiian or Pacific Islander"
                                                        , race_mides == 1 ~ "Middle Eastern, Arab, or Arab American"
                                                        , race_white == 1 ~ "White"
                                                        , race_other == 1 ~ "Other"
                                                        , TRUE ~ ""))


table(data_env_mh$race)

table(data_env_mh$sexuality,data$race)

table(data_env_mh$lgbtq,data_env_mh$env_mh)


data_env_mh_lgbtq <- data_env_mh %>% filter(lgbtq == 1)
data_env_mh_non_lgbtq <- data_env_mh %>% filter(lgbtq == 0)
data_env_mh_male <- data_env_mh %>% filter(gender == 1)
data_env_mh_female <- data_env_mh %>% filter(gender == 2)
data_env_mh_black <- data_env_mh %>% filter (race_black == 1)
data_env_mh_americanindian_alaskannative <- data_env_mh%>% filter (race_ainaan == 1)
data_env_mh_asian <- data_env_mh%>% filter (race_asian == 1)
data_env_mh_pacific_islander <- data_env_mh %>% filter (race_pi == 1)
data_env_mh_middle_eastern <- data_env_mh %>% filter (race_mides == 1)
data_env_mh_white <- data_env_mh %>% filter (race_white == 1)
data_env_mh_other<- data_env_mh %>% filter (race_other == 1)
data_env_mh_hispanic <- data_env_mh%>% filter (race_his == 1)
data_env_mh_non_white <- data_env_mh %>% filter(race_white == 0)

data_env_mh_bi <- data_env_mh %>% filter(sexual_bi == 1)
data_env_mh_gay <- data_env_mh %>% filter(sexual_g == 1)
data_env_mh_heterosexual <- data_env_mh %>% filter(sexual_h == 1)
data_env_mh_lesbian <- data_env_mh %>% filter(sexual_l == 1)
data_env_mh_other <- data_env_mh %>% filter(sexual_other == 1)
data_env_mh_queer <- data_env_mh %>% filter(sexual_queer == 1)
data_env_mh_quest <- data_env_mh %>% filter(sexual_quest == 1)

data_env_mh_hispanic_male <- data_env_mh_hispanic %>% filter(gender == 1)
data_env_mh_hispanic_female <- data_env_mh_hispanic %>% filter(gender == 2)
data_env_mh_white_male <- data_env_mh_white %>% filter(gender == 1)
data_env_mh_white_female <- data_env_mh_white %>% filter(gender == 2)

data_env_mh_white_male_lgbtq <- data_env_mh_white_male %>% filter(lgbtq == 1)
data_env_mh_white_male_non_lgbtq <- data_env_mh_white_male %>% filter(lgbtq == 0)
data_env_mh_white_female_lgbtq <- data_env_mh_white_female %>% filter(lgbtq == 1)
data_env_mh_white_female_non_lgbtq <- data_env_mh_white_female %>% filter(lgbtq == 0)


###################
# env_mh analysis #
###################


# mean(data_env_mh_americanindian_alaskannative$env_mh, na.rm = TRUE)
# mean(data_env_mh_asian$env_mh, na.rm = TRUE)
# mean(data_env_mh_black$env_mh, na.rm = TRUE)
# mean(data_env_mh_hispanic$env_mh, na.rm = TRUE)
# mean(data_env_mh_middle_eastern$env_mh, na.rm = TRUE)
# mean(data_env_mh_pacific_islander$env_mh, na.rm = TRUE)
# mean(data_env_mh_white$env_mh, na.rm = TRUE)
# mean(data_env_mh_lgbtq$env_mh, na.rm = TRUE)
# mean(data_env_mh_non_lgbtq$env_mh, na.rm = TRUE)
# mean(data_env_mh_male$env_mh, na.rm = TRUE)
# mean(data_env_mh_female$env_mh, na.rm = TRUE)
# describe(data_env_mh_black$env_mh)

describe(data_env_mh_americanindian_alaskannative$env_mh)
describe(data_env_mh_asian$env_mh)
describe(data_env_mh_black$env_mh)
describe(data_env_mh_hispanic$env_mh)
describe(data_env_mh_middle_eastern$env_mh)
describe(data_env_mh_pacific_islander$env_mh)
describe(data_env_mh_other$env_mh)
describe(data_env_mh_white$env_mh)
table(jed$env_mh, useNA = "always")

describe(data_env_mh_bi$env_mh)
describe(data_env_mh_gay$env_mh)
describe(data_env_mh_heterosexual$env_mh)
describe(data_env_mh_lesbian$env_mh)
describe(data_env_mh_other$env_mh)
describe(data_env_mh_queer$env_mh)
describe(data_env_mh_quest$env_mh)
describe(data_env_mh_bi$env_mh)

describe(data_env_mh_non_lgbtq$env_mh)
describe(data_env_mh_lgbtq$env_mh)

describe(data_env_mh_male$env_mh)
describe(data_env_mh_female$env_mh)

describe(data_env_mh_hispanic_male$env_mh)
describe(data_env_mh_hispanic_female$env_mh)
describe(data_env_mh_white_male$env_mh)
describe(data_env_mh_white_female$env_mh)
describe(data_env_mh_white_male_non_lgbtq$env_mh)
describe(data_env_mh_white_male_lgbtq$env_mh)


# statistical testing #

# lgbtq #

t.test(data_env_mh_lgbtq$env_mh, data_env_mh_non_lgbtq$env_mh)

var.test(data_env_mh_lgbtq$env_mh, data_env_mh_non_lgbtq$env_mh)

# gender #

t.test(data_env_mh_female$env_mh, data_env_mh_male$env_mh)

var.test(data_env_mh_female$env_mh, data_env_mh_male$env_mh)

# race #
# white #

# Ameircan Indian Alaskan native

t.test(data_env_mh_white$env_mh, data_env_mh_americanindian_alaskannative$env_mh)

var.test(data_env_mh_white$env_mh, data_env_mh_americanindian_alaskannative$env_mh)

# Asian 

t.test(data_env_mh_white$env_mh, data_env_mh_asian$env_mh)

var.test(data_env_mh_white$env_mh, data_env_mh_asian$env_mh)

# Black

t.test(data_env_mh_white$env_mh, data_env_mh_black$env_mh)

var.test(data_env_mh_white$env_mh, data_env_mh_black$env_mh)

# Hispanic Latino/A
# Var-test **
# closest to significant

t.test(data_env_mh_white$env_mh, data_env_mh_hispanic$env_mh)

var.test(data_env_mh_white$env_mh, data_env_mh_hispanic$env_mh)

# Middle Eastern, Arab, or Arab American

t.test(data_env_mh_white$env_mh, data_env_mh_middle_eastern$env_mh)

var.test(data_env_mh_white$env_mh, data_env_mh_middle_eastern$env_mh)

# Native Hawaiian or Pacific Islander

t.test(data_env_mh_white$env_mh, data_env_mh_pacific_islander$env_mh)

var.test(data_env_mh_white$env_mh, data_env_mh_pacific_islander$env_mh)

# Other
# T-test *

t.test(data_env_mh_white$env_mh, data_env_mh_other$env_mh)

var.test(data_env_mh_white$env_mh, data_env_mh_other$env_mh)

# Sexuality #


# heterosexual #

# bi
# T-Test *

t.test(data_env_mh_heterosexual$env_mh, data_env_mh_bi$env_mh)

var.test(data_env_mh_heterosexual$env_mh, data_env_mh_bi$env_mh)

# Gay

t.test(data_env_mh_heterosexual$env_mh, data_env_mh_gay$env_mh)

var.test(data_env_mh_heterosexual$env_mh, data_env_mh_gay$env_mh)

# lesbian

t.test(data_env_mh_heterosexual$env_mh, data_env_mh_lesbian$env_mh)

var.test(data_env_mh_heterosexual$env_mh, data_env_mh_lesbian$env_mh)

# other

t.test(data_env_mh_heterosexual$env_mh, data_env_mh_other$env_mh)

var.test(data_env_mh_heterosexual$env_mh, data_env_mh_other$env_mh)

# queer

t.test(data_env_mh_heterosexual$env_mh, data_env_mh_queer$env_mh)

var.test(data_env_mh_heterosexual$env_mh, data_env_mh_queer$env_mh)

# quest

t.test(data_env_mh_heterosexual$env_mh, data_env_mh_quest$env_mh)

var.test(data_env_mh_heterosexual$env_mh, data_env_mh_quest$env_mh)



# gender and race #

t.test(data_env_mh_white_male_lgbtq$env_mh, data_env_mh_white_male_non_lgbtq$env_mh)

var.test(data_env_mh_white_male_lgbtq$env_mh, data_env_mh_white_male_non_lgbtq$env_mh)

t.test(data_env_mh_white_female_lgbtq$env_mh, data_env_mh_white_female_non_lgbtq$env_mh)

var.test(data_env_mh_white_female_lgbtq$env_mh, data_env_mh_white_female_non_lgbtq$env_mh)



#write.csv(jed, file = 'EastWash.csv', row.names =  FALSE)


