#!/usr/bin/env Rscript



# Load Libraries ----------------------------------------------------------

if (!require("timeDate")) {
  install.packages("timeDate", repos="http://cran.rstudio.com/")
  library(timeDate)
}




# Read Data ---------------------------------------------------------------

data <- read.csv("logs.csv")




# Data Exploration --------------------------------------------------------

summary(data) # Summarising the Dataset 

sapply(data, function(x) sum(is.na(x))) # Checking for missing values in the dataset

dim(data)  # The dataset dimensions Rows x Columns

length(unique(data$uuid)) # 257354 Unique Users

length(data$uuid) # 669491 Total User Interactions

table(duplicated(data$uuid)) # one-time activity - FALSE and multiple-times activity - TRUE 




# Data Preparation --------------------------------------------------------

# Create Date Column 

data$date <- as.factor(as.Date(data$ts))

# Create Time Column

timefun <- strptime(data$ts, "%Y-%m-%d %H:%M:%S")
data$time <- as.numeric(format(timefun, "%H%M%S"))

# Ordering the date frame by date 

data <- data[with(data, order(date, time)),]



# Creating Feature 1 ------------------------------------------------------

# Create "multiple_days" column 
data$multiple_days <- (duplicated(data$uuid)) & !duplicated(data[, c("uuid","date")])

# To classify first and repeated occurrence as TRUE,we can use the following rule:
# data$multiple_days <- (duplicated(data$uuid) | duplicated(data[nrow(data):1, "uuid"])[nrow(data):1]) & !duplicated(data[, c("uuid","date")])


table(data$multiple_days)




# Creating Feature 2 ------------------------------------------------------

# Create "weekday_biz" column
data$weekday_biz <- (isWeekday(data$date) & ifelse(data$time>=090000 & data$time<=170000, TRUE, FALSE))

table(data$weekday_biz)




# Creating Feature 3 ------------------------------------------------------

# Create "multiple_locations" column 

data$multiple_locations <- (duplicated(data$uuid)) & !duplicated(data[, c("uuid","ip")])

table(data$multiple_locations)




# Retaining the required features - Output --------------------------------

output <- data[,c("uuid","multiple_days","weekday_biz", "multiple_locations")]



# Writing to a CSV --------------------------------------------------------

write.csv(output, "output.csv", row.names=FALSE)
