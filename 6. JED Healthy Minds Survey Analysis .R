# ============================================================================================
# Program:      JED Healthy Minds Survey Analysis    
# Description:  Statistical Analysis of the Campus-wide JED Healthy Minds Survey  
# Author:       Jake Morrison
# ============================================================================================

# Load required libraries
library(tidyverse)    # includes dplyr, tidyr, ggplot2, purrr
library(psych)        # for descriptive statistics
library(haven)        # to read Stata .dta files
library(data.table)   # faster data reading
library(Hmisc)        # for %nin% and other tools
library(dummies)      # to create dummy variables

# Clear environment and set working directory
rm(list = ls(all = TRUE))
setwd("N:/Projects/JED")

# Load survey data
jed <- read_dta(file = "EastWash.dta")

# --------------------------------------------------------------------------------------------
# Generate simplified race and sexuality variables
# --------------------------------------------------------------------------------------------

jed <- jed %>%
  mutate(
    race = case_when(
      race_black == 1 ~ "Black",
      race_ainaan == 1 ~ "American Indian or Alaskan native",
      race_asian == 1 ~ "Asian American / Asian",
      race_his == 1 ~ "Hispanic / Latino/a",
      race_pi == 1 ~ "Native Hawaiian or Pacific Islander",
      race_mides == 1 ~ "Middle Eastern, Arab, or Arab American",
      race_white == 1 ~ "White",
      race_other == 1 ~ "Other",
      TRUE ~ ""
    ),
    sexuality = case_when(
      sexual_h == 1 ~ "heterosexual",
      sexual_l == 1 ~ "lesbian",
      sexual_g == 1 ~ "gay",
      sexual_bi == 1 ~ "bi",
      sexual_other == 1 ~ "other",
      sexual_queer == 1 ~ "queer",
      sexual_quest == 1 ~ "quest",
      TRUE ~ ""
    )
  )

# --------------------------------------------------------------------------------------------
# Subset data for mental health environment analysis
# --------------------------------------------------------------------------------------------

data_env_mh <- jed %>%
  select(
    env_mh, age, sex_birth, gender,
    sexual_h, sexual_l, sexual_g, sexual_bi, sexual_queer, sexual_quest, sexual_other,
    relship, race_black, race_ainaan, race_asian, race_his, race_pi,
    race_mides, race_white, race_other, enroll, gpa_sr, aca_impa, persist
  ) %>%
  mutate(
    sexuality = case_when(
      sexual_h == 1 ~ "heterosexual",
      sexual_l == 1 ~ "lesbian",
      sexual_g == 1 ~ "gay",
      sexual_bi == 1 ~ "bi",
      sexual_other == 1 ~ "other",
      sexual_queer == 1 ~ "queer",
      sexual_quest == 1 ~ "quest",
      TRUE ~ ""
    ),
    lgbtq = case_when(
      sexuality == "heterosexual" ~ 0,
      sexuality %in% c("lesbian", "gay", "bi", "other", "queer", "quest") ~ 1,
      TRUE ~ 2
    ),
    race = case_when(
      race_black == 1 ~ "Black",
      race_ainaan == 1 ~ "American Indian or Alaskan native",
      race_asian == 1 ~ "Asian American / Asian",
      race_his == 1 ~ "Hispanic / Latino/a",
      race_pi == 1 ~ "Native Hawaiian or Pacific Islander",
      race_mides == 1 ~ "Middle Eastern, Arab, or Arab American",
      race_white == 1 ~ "White",
      race_other == 1 ~ "Other",
      TRUE ~ ""
    )
  )

# --------------------------------------------------------------------------------------------
# Descriptive subgroup filters (used later in analysis)
# --------------------------------------------------------------------------------------------

# Identity-based subgroups
subgroups <- list(
  lgbtq = filter(data_env_mh, lgbtq == 1),
  non_lgbtq = filter(data_env_mh, lgbtq == 0),
  male = filter(data_env_mh, gender == 1),
  female = filter(data_env_mh, gender == 2),
  bi = filter(data_env_mh, sexual_bi == 1),
  gay = filter(data_env_mh, sexual_g == 1),
  lesbian = filter(data_env_mh, sexual_l == 1),
  heterosexual = filter(data_env_mh, sexual_h == 1),
  other = filter(data_env_mh, sexual_other == 1),
  queer = filter(data_env_mh, sexual_queer == 1),
  quest = filter(data_env_mh, sexual_quest == 1)
)

# Race and intersectional subgroups
race_codes <- c("black", "ainaan", "asian", "pi", "mides", "white", "his", "other")
for (race in race_codes) {
  subgroups[[race]] <- filter(data_env_mh, !!sym(paste0("race_", race)) == 1)
}
subgroups[["non_white"]] <- filter(data_env_mh, race_white == 0)

# Intersectional gender + race + lgbtq subgroups
subgroups[["hispanic_male"]] <- filter(subgroups[["his"]], gender == 1)
subgroups[["white_female_lgbtq"]] <- filter(filter(subgroups[["white"]], gender == 2), lgbtq == 1)

# --------------------------------------------------------------------------------------------
# Descriptive Statistics for env_mh by Group
# --------------------------------------------------------------------------------------------

# Run describe across defined subgroups
env_mh_descriptives <- lapply(subgroups, function(group) {
  describe(group$env_mh)
})

# Optional: Print a few examples
print(env_mh_descriptives[["white"]])
print(env_mh_descriptives[["lgbtq"]])

# --------------------------------------------------------------------------------------------
# Inferential Statistics - t-tests and variance tests
# --------------------------------------------------------------------------------------------

# LGBTQ vs Non-LGBTQ
t.test(subgroups$lgbtq$env_mh, subgroups$non_lgbtq$env_mh)
var.test(subgroups$lgbtq$env_mh, subgroups$non_lgbtq$env_mh)

# Female vs Male
t.test(subgroups$female$env_mh, subgroups$male$env_mh)
var.test(subgroups$female$env_mh, subgroups$male$env_mh)

# White vs Other Racial Groups
compare_to_white <- function(group_name) {
  if (group_name %in% names(subgroups)) {
    message("T-test vs. White: ", group_name)
    print(t.test(subgroups$white$env_mh, subgroups[[group_name]]$env_mh))
    print(var.test(subgroups$white$env_mh, subgroups[[group_name]]$env_mh))
  }
}
lapply(setdiff(race_codes, "white"), compare_to_white)

# Heterosexual vs Other Sexual Identities
sexual_ids <- c("bi", "gay", "lesbian", "other", "queer", "quest")
for (id in sexual_ids) {
  message("T-test vs. Heterosexual: ", id)
  print(t.test(subgroups$heterosexual$env_mh, subgroups[[id]]$env_mh))
  print(var.test(subgroups$heterosexual$env_mh, subgroups[[id]]$env_mh))
}

# Intersectional analysis: white male/female by LGBTQ status
t.test(subgroups$white_male_lgbtq$env_mh, subgroups$white_male_non_lgbtq$env_mh)
var.test(subgroups$white_male_lgbtq$env_mh, subgroups$white_male_non_lgbtq$env_mh)

t.test(subgroups$white_female_lgbtq$env_mh, subgroups$white_female_non_lgbtq$env_mh)
var.test(subgroups$white_female_lgbtq$env_mh, subgroups$white_female_non_lgbtq$env_mh)
