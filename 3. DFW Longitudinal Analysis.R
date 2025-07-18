##########################################
# TITLE: DFW Longitudinal Analysis
# AUTHOR: Jake Morrison
# DESCRIPTION: Tracks students who receive D, F, or W grades and analyzes their outcomes over time.
##########################################

# ---- Setup ----

setwd("N:/Projects/INSTITUTIONAL_ANALYSTICS_AND_PLANNING/DFW_LONGITUDINAL_ANALYSIS")

# Load libraries
library(tidyr)
library(dplyr)
library(stringr)
library(purrr)
library(ggplot2)
library(data.table)
library(Hmisc)
library(dummies)
library(doBy)
library(sqldf)

# Clear environment
rm(list = ls())

# ---- Load Data ----

data <- read.csv("export.csv", header = TRUE)
enrollment <- read.csv("enrollment.csv", header = TRUE)

# Preview unique student count for a course (e.g., ACCT251)
sqldf("SELECT COUNT(DISTINCT PERSON_UID) FROM data WHERE COURSE_IDENTIFICATION = 'ACCT251'")

# ---- Clean & Prepare Variables ----

# Standardize column names
data <- data %>%
  rename(
    person = PERSON_UID,
    course = COURSE_IDENTIFICATION,
    major_at_time = MAJOR_DESC,
    college_at_time = COLLEGE_DESC
  )

enrollment <- enrollment %>%
  rename(person = PERSON_UID)

# ---- Identify Repeaters ----

data <- data %>%
  group_by(person, course) %>%
  add_count(name = "repeats") %>%
  ungroup() %>%
  mutate(repeated_ind = ifelse(repeats > 1, 1, 0))  # 1 = repeated course

# ---- Filter Invalid or Non-graded Attempts ----

invalid_grades <- c("(0.7)", "(0.0)", "NC", "P", "XC", "XF", "Y")
data <- data %>% filter(!FINAL_GRADE %in% invalid_grades)

# ---- Convert Numeric Grades to Letter Grades ----

data <- data %>%
  mutate(FINAL_GRADE = case_when(
    FINAL_GRADE %in% c('4.0', '3.9') ~ "A",
    FINAL_GRADE %in% c('3.8', '3.7', '3.6') ~ "A-",
    FINAL_GRADE %in% c('3.5', '3.4', '3.3', '3.2') ~ "B+",
    FINAL_GRADE %in% c('3.1', '3.0', '2.9') ~ "B",
    FINAL_GRADE == '2.8' ~ "C+",
    FINAL_GRADE == '2.7' ~ "B-",
    FINAL_GRADE %in% c('2.6', '2.5', '2.4', '2.3') ~ "C+",
    FINAL_GRADE %in% c('2.2', '2.1', '2.0') ~ "C",
    FINAL_GRADE %in% c('1.9', '1.8', '1.7') ~ "C-",
    FINAL_GRADE %in% c('1.6', '1.5', '1.4', '1.3', '1.2') ~ "D+",
    FINAL_GRADE %in% c('1.1', '1.0', '0.9') ~ "D",
    FINAL_GRADE %in% c('0.8', '0.7') ~ "D-",
    FINAL_GRADE == '0.0' ~ "F",
    TRUE ~ FINAL_GRADE
  ))

# ---- Create Repeat Outcome Indicators ----

data <- data %>%
  group_by(person, course) %>%
  mutate(ranks = rank(ACADEMIC_PERIOD)) %>%
  ungroup()

# Mark final attempt grade for repeaters
data <- data %>%
  group_by(person, course) %>%
  mutate(
    repeated_grade = ifelse(ranks == max(ranks) & repeated_ind == 1, FINAL_GRADE, NA)
  ) %>%
  fill(repeated_grade, .direction = "downup") %>%
  ungroup()

# Label outcome for repeaters
data <- data %>%
  mutate(outcome = ifelse(repeated_ind == 1, "re-took class", NA))

# ---- Filter: DFWs and Repeaters Only ----

data <- data %>%
  filter(repeats >= 2 | FINAL_GRADE %in% c("D+", "D", "D-", "F", "W"))

# ---- Enrollment Gaps & Current Status ----

# Identify last enrolled term
enrollment_latest <- enrollment %>%
  group_by(person) %>%
  filter(ACADEMIC_PERIOD == max(ACADEMIC_PERIOD)) %>%
  ungroup()

# Merge enrollment with main data
data <- merge(data, enrollment_latest, by = "person", all.x = TRUE) %>%
  rename(
    latest_major = Major,
    current_period = ACADEMIC_PERIOD.x,
    last_period = ACADEMIC_PERIOD.y,
    last_college = college,
    GRADUATED_IND = MAX.AO.GRADUATED_IND.
  ) %>%
  mutate(difference = last_period - current_period)

# ---- Outcome Categories ----

# 1. Stopped out immediately
data <- data %>%
  mutate(outcome = ifelse(
    is.na(outcome) & difference == 0 & last_period <= '201940',
    "stopped out immediately",
    outcome
  ))

# 2. Changed Major
data <- data %>%
  mutate(
    changed_major = ifelse(major_at_time != latest_major, 1, 0),
    outcome = ifelse(is.na(outcome) & changed_major == 1, "changed major", outcome)
  )

# 3. Changed College
data <- data %>%
  mutate(
    changed_college_ind = ifelse(college_at_time != last_college, 1, 0)
  )

# 4. Stopped out
data <- data %>%
  mutate(outcome = ifelse(
    is.na(outcome) & last_period <= '201940' & GRADUATED_IND != 'Y',
    "stopped out",
    outcome
  ))

# 5. Graduated without retaking course
data <- data %>%
  mutate(outcome = ifelse(
    is.na(outcome) & GRADUATED_IND == 'Y',
    "graduated without course",
    outcome
  ))

# ---- Sub-outcome Classification ----

data <- data %>%
  mutate(sub_outcome = case_when(
    outcome == "re-took class" & GRADUATED_IND == 'Y' & major_at_time == latest_major ~ "re-took & graduated in major",
    outcome == "re-took class" & GRADUATED_IND == 'Y' & major_at_time != latest_major ~ "re-took & graduated in new major",
    outcome == "changed major" & GRADUATED_IND == 'Y' ~ "changed major & graduated",
    last_period == '202020' & GRADUATED_IND != 'Y' ~ "still at University",
    TRUE ~ NA_character_
  ))

# Fill main outcome if still at university
data <- data %>%
  mutate(outcome = ifelse(sub_outcome == "still at University" & is.na(outcome), "still at University", outcome))

# ---- Outcome Indicator Variables ----

data <- data %>%
  mutate(
    stopped_out_ind = ifelse(last_period <= '201940' & GRADUATED_IND != 'Y', 1, 0),
    GRADUATED_IND_IND = ifelse(GRADUATED_IND == 'Y', 1, 0),
    persisting = ifelse(last_period > '201940' & GRADUATED_IND != 'Y', 1, 0),
    changed_major_ind = ifelse(major_at_time != latest_major, 1, 0),
    changed_major_grad = ifelse(GRADUATED_IND_IND == 1 & changed_major_ind == 1, 1, 0)
  )

# ---- Validation Output ----

# Table of stop-outs
stop_outs <- data %>% filter(outcome %in% c("stopped out", "stopped out immediately"))
