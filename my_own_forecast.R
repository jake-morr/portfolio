

setwd("N:/Projects/hsi_proportion_forecast")


library(tidyr)      # data manipulation
library(dplyr)      # data manipulation
library(stringr)
library(purrr)
library(ggplot2)    # data visualization
library(data.table) # data loading speed
library(Hmisc)      # for %nin%
library(dummies)# for creating dummy variables
library(doBy)
library(forecast)


rm(list = ls()) # remove all enviornment items

enr <- read.csv("enr.csv")

# enr <- enr %>% mutate(PERIOD = case_when(substr(as.character(PERIOD),1,6) == '201535' ~ '201540',
#                                          substr(as.character(PERIOD),1,6) == '201615' ~ '201610',
#                                          substr(as.character(PERIOD),1,6) == '201625' ~ '201630',
#                                          substr(as.character(PERIOD),1,6) == '201635' ~ '201640',
#                                          substr(as.character(PERIOD),1,6) == '201715' ~ '201710',
#                                          substr(as.character(PERIOD),1,6) == '201725' ~ '201730',
#                                          substr(as.character(PERIOD),1,6) == '201735' ~ '201740',
#                                          substr(as.character(PERIOD),1,6) == '201815' ~ '201810',
#                                          substr(as.character(PERIOD),1,6) == '201825' ~ '201830',
#                                          substr(as.character(PERIOD),1,6) == '201835' ~ '201840',
#                                          substr(as.character(PERIOD),1,6) == '201915' ~ '201910',
#                                          substr(as.character(PERIOD),1,6) == '201925' ~ '201930',
#                                          substr(as.character(PERIOD),1,6) == '201935' ~ '201940',
#                                          substr(as.character(PERIOD),1,6) == '202015' ~ '202010',
#                                          TRUE ~ as.character(PERIOD)))

enr <- enr %>% group_by(PERIOD) %>% mutate(total_students = sum(STUDENTS)) %>% ungroup

enr <- enr %>% mutate(proportion = ((STUDENTS/total_students)*100))

# enr <- enr %>%
#   group_by(PERIOD, ETHNICITY) %>%
#   summarise(combined = sum(proportion))
# 
# enr <- enr %>% rename(proportion = combined)

enr$proportion <- round(enr$proportion, digits = 2)

enr <- enr %>% filter(substr(as.character(PERIOD),6,6) != '5')

enr <- enr %>% filter(ETHNICITY =="Hispanic/Latino")

ggplot(data = enr,aes(x = PERIOD, y = proportion)) +
  geom_point() +
  geom_line()

enr$PERIOD <- as.factor(enr$PERIOD)

enr$proportion <- log(enr$proportion)

tsdata <-ts(enr$proportion,frequency = 4,start=c(2006,4))

# 
# #######################################
# 
# 
# train <- window(tsdata,start = c(2006,4) , end = c(2016,3), frequency = 4) # 80 - 20 split # the training set goes to 201630
# 
# (fit.arima <- auto.arima(train))
# checkresiduals(fit.arima)
# 
# (fit.ets <- ets(train))
# checkresiduals(fit.ets)
# 
# a1 <- fit.arima %>% forecast(h = 30) %>%
#    accuracy(tsdata)
# # 
# # a1$mean<-exp(a1$mean)
# # a1$upper<-exp(a1$upper)
# # a1$lower<-exp(a1$lower)
# # a1$x<-exp(a1$x)
# # 
# # a1
# 
# a1[,c("RMSE","MAE","MAPE","MASE")]
# 
# a2 <- fit.ets %>% forecast(h = 30) %>%
#   accuracy(tsdata)
# a2[,c("RMSE","MAE","MAPE","MASE")]
# 
# forecast3 <- tsdata %>% auto.arima() %>% forecast(h=30)
# 
# forecast3$mean<-exp(forecast3$mean)
# forecast3$upper<-exp(forecast3$upper)
# forecast3$lower<-exp(forecast3$lower)
# forecast3$x<-exp(forecast3$x)
# 
# forecast3
# 
# ################################
 # 
 # hw <- hw(tsdata, seasonal = "additive", h = 35)
 # 
 # hw$mean<-exp(hw$mean)
 # hw$upper<-exp(hw$upper)
 # hw$lower<-exp(hw$lower)
 # hw$x<-exp(hw$x)
 # 
 # hw

plot(tsdata)

autoarima1 <- auto.arima(tsdata)

forecast1 <- forecast(autoarima1, h=35)

forecast1$mean<-exp(forecast1$mean)
forecast1$upper<-exp(forecast1$upper)
forecast1$lower<-exp(forecast1$lower)
forecast1$x<-exp(forecast1$x)

forecast1


plot (forecast1)

plot(forecast1$residuals)


gg <- forecast1 %>% autoplot() + geom_hline(yintercept = 25, linetype = "dashed", lwd = 1) + 
  theme_bw() + ggtitle("Forecasted Full Time Undergraduate Hispanic Student Proportion") + ylab("Proportion")

qqnorm(forecast1$residuals)

pacf(forecast1$residuals)

summary(autoarima1)

accuracy(autoarima1)

plot (gg)
