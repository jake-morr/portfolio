##########################################
# TITLE: REGISTRATION_ANALYSIS_CLEANING
# AUTHOR: Jake Morrison
# DESCRIPTION: Identifies undergraduate students who have not yet registered 
#              and flags those registering late, including hold status.
##########################################

# ---- Setup ----

# Load necessary libraries
library(tidyr)
library(dplyr)
library(stringr)
library(purrr)
library(ggplot2)
library(data.table)
library(Hmisc)
library(dummies)
library(doBy)
# library(ROracle) # Uncomment if ROracle is configured for DB access

# Set working directory
setwd("N:/Projects/INSTITUTIONAL_ANALYSTICS_AND_PLANNING/REGISTRATION_TIME")

# Clear environment
rm(list = ls())

# ---- Load Data ----

today <- read.csv("today.csv")
registration <- read.csv("clean.csv")
holds <- read.csv("holds.csv")

# ---- Prepare and Clean Today's Data ----

# Convert registration date to proper format
today <- today %>%
  mutate(registration_date = as.Date(registration_date, "%d-%b-%y"))

# Standardize column names
registration <- registration %>% rename(Major = major)
data <- bind_rows(registration, today)

# Remove placeholder variables and re-add as needed
data <- data %>%
  select(-observations) %>%
  mutate(
    observations = NA,
    registration_date_able = NA,
    days_dif = NA,
    count = NA,
    remove = NA,
    days_diff_avg = NA
  )

# ---- Student Registration Status ----

# Count number of registration records per student
data <- data %>%
  group_by(ID) %>%
  add_count(name = "observations") %>%
  ungroup()

# Keep only students who have not yet registered this term
data <- data %>% filter(observations < 2)

# ---- Assign Registration Eligibility Dates ----

data <- data %>%
  mutate(
    registration_date_able = case_when(
      credits >= 180 & academic_period == 202020 & level == 'UG' ~ '05-19-20',
      between(credits, 150, 179.9999) & academic_period == 202020 & level == 'UG' ~ '05-20-20',
      between(credits, 120, 149.9) & academic_period == 202020 & level == 'UG' ~ '05-21-20',
      between(credits, 90, 119.9) & academic_period == 202020 & level == 'UG' ~ '05-22-20',
      between(credits, 60, 89.9) & academic_period == 202020 & level == 'UG' ~ '05-26-20',
      between(credits, 30, 59.9) & academic_period == 202020 & level == 'UG' ~ '05-27-20',
      between(credits, 0, 29.9) & academic_period == 202020 & level == 'UG' ~ '05-28-20',
      academic_period == 202020 & level %in% c('GR', 'PB') ~ '05-18-20',
      TRUE ~ NA_character_
    ),
    registration_date_able = as.Date(registration_date_able, "%m-%d-%y"),
    registration_date = Sys.Date()
  )

# Calculate days past eligible registration date
data <- data %>%
  mutate(
    days_dif = as.numeric(difftime(registration_date, registration_date_able, units = "days"))
  )

# ---- Late Registration Flags ----

# Use difference from average to flag late registrations
data <- data %>%
  mutate(
    late_flag = ifelse(days_dif > as.numeric(days_diff_avg), 'Y', 'N'),
    late_20_flag = ifelse(days_dif > (as.numeric(days_diff_avg) + 20), 'Y', 'N')
  )

# ---- Merge with Holds ----

# Limit to undergraduate students
data <- data %>%
  filter(level %in% c('UG', 'US')) %>%
  mutate(days_past = as.numeric(Sys.Date() - registration_date_able))

# Keep only active holds
holds <- holds %>% filter(active.indicator == 'Y')

# Merge hold data
combined_hold <- merge(data, holds, by = "ID", all.x = TRUE)

# Remove rows missing eligibility dates
combined_hold <- combined_hold %>% filter(!is.na(registration_date_able))

# ---- Final Output Prep ----

output <- combined_hold %>%
  select(
    name, ID, credits, level, class_standing, advisor_type, advisor,
    HOLD_DESC, active.indicator, registration_hold,
    registration_date_able, days_diff_avg, days_past,
    late_flag, late_20_flag
  ) %>%
  mutate(across(where(is.character), ~ ifelse(is.na(.), "", .))) %>%
  rename(hold_description = HOLD_DESC)

# ---- Write Output ----

write.csv(output, file = "today_analysis.csv", row.names = FALSE)
