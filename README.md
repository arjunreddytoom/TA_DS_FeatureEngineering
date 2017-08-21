# TA_DS_FeatureEngineering
Data Science - Feature Engineering Problem


## Load Libraries

```{r}
library(timeDate)
```

The "timeDate" library is soon going to help us identify if a given date is a Weekday or Weekend.

## Read Data 

```{r}
data <- read.csv("logs.csv")
```

----------------------------------------------------------------------------------------------------------------

## Data Exploration

Summary function helps us summarise a dataset with important information such as data distribution, a glimpse of the dataset, number of data points. 

```{r}
summary(data) # Summarising the Dataset 
```


Let's also check if their is need to impute values - if necessary:
```{r}
sapply(data, function(x) sum(is.na(x))) # Checking for missing values in the dataset
```


```{r}
dim(data)  # The dataset dimensions Rows x Columns
```
As it is a considerably large dataset, we need to be efficient with our functions and operations

```{r}
length(unique(data$uuid)) # Number of Unique Users
```
Are the total number of users in the dataset 


```{r}
length(data$uuid) # Total User Interactions
```
Are the number of user interactions 


```{r}
table(duplicated(data$uuid)) # User Activity 
```

One-time activity - FALSE and multiple-time activity - TRUE

----------------------------------------------------------------------------------------------------------------

## Data Preparation 

```{r}
# Create Date Column 
data$date <- as.factor(as.Date(data$ts))
```
Separating "date" part of the Timestamp completely, so that it can be used effectively in developing new features such as multiple-day activity. 


```{r}
# Create Time Column
timefun <- strptime(data$ts, "%Y-%m-%d %H:%M:%S")
data$time <- as.numeric(format(timefun, "%H%M%S"))
```
Separating "time"" part of the Timestamp completely, so that it can be used to define business hours and non-business hours in the development of weekday-business hour feature.

Also removing ":" in between "hours:minutes:seconds" makes it simple to classify numeric values

```{r}
# Ordering the date frame by date 
data <- data[with(data, order(date, time)),]
```
As the datset follows a time series, it is better to order it - to engineer new features. As the features are going to be used in Machine Learning models, **it becomes important to maintain the precedence of user activity which occurs before other activity or repeated activity, in chronological order.** 

----------------------------------------------------------------------------------------------------------------

## Creating Feature 1 - "multiple_days"

```{r}
# Create "multiple_days" column 
data$multiple_days <- (duplicated(data$uuid)) & !duplicated(data[, c("uuid","date")])
```


**Rule:**

**(duplicated(data$uuid))** - classify every repeated occurrence as TRUE, except for the first occurrence of the user.

**&**

**!duplicated(data[, c("uuid","date")])** - classify every repeated occurrence on a different day as TRUE

The rule spits out TRUE for every repeated occurrence of the uuid for a different combination of "uuid" and "date"


**_Explanation:_** As it is not known if the user is active for multiple days or not - at the time of their first entry(interaction), I have defined the rule such that every repeated activity(on a different day) by the user is classified as TRUE. Whereas the first interaction is counted as FALSE, in the case of a repeated activity on the same day as well, the feature is classified as FALSE. 

**_NOTE:_** In case if it is required to classify, both the first occurence of a user and the repeated occurence as TRUE, we can use the rule - 

```{r}
# (duplicated(data$uuid) | duplicated(data[nrow(data):1, "uuid"])[nrow(data):1]) & !duplicated(data[, c("uuid","date")])
```

In this case, though the first and every repeated occurrence on a different day gets classified as TRUE, every repeated occurrence on the same day gets classified as FALSE. But we are going to use the first rule. 

##### Number of user interactions repeating on multiple days
```{r}
table(data$multiple_days)
```

Now, once again let's look at the number of repeating user ids 

```{r}
table(duplicated(data$uuid)) # User Activity 
# One-time activity - FALSE and multiple-time activity - TRUE
```

This implies that majority of repeating user interactions happen on the same day, whereas only 83,589 interactions are from different days. 

**We can say that, the company needs to take measures to drive behaviors such that users interact with the system more often.**

----------------------------------------------------------------------------------------------------------------

## Creating Feature 2 - "weekday_biz"
```{r}
# Create "weekday_biz" column
data$weekday_biz <- (isWeekday(data$date) & ifelse(data$time>=090000 & data$time<=170000, TRUE, FALSE))
```

**_Assumption:_** Business Hours is 9AM - 5PM inclusive

**_Rule:_**

**isWeekday(data$date)** - Classify it as TRUE, if it is a Weekday and FALSE, if it is a Weekend

**&**

**ifelse(data\$time>=090000 & data\$time<=170000, TRUE, FALSE)** - Classify it as TRUE, if the time falls between 9AM and 5PM inclusive, else FALSE.


```{r}
table(data$weekday_biz)
```

**This helps us identify how users are interacting with the system during weekday business hours and other times.**

----------------------------------------------------------------------------------------------------------------


## Creating Feature 3 - "multiple_locations"
**Feature selection:** 
Identifying users who are active while traveling or interacting with the system on the move helps make important decisions about behaviors - while at home and when traveling. 

For this feature we will be using the IP Address variable in association with User ID. Though there are number of different factors under which IP addresses change, for simplicity we can say that when the user is at home, he/she will use the network IP and when they are on the move, their IP address changes. This simple fact can provide us some important information and help make assumptions about user behaviors - which can feed the machine learning model with more knowledge. 

```{r}
# Create "multiple_locations" column 
data$multiple_locations <- (duplicated(data$uuid)) & !duplicated(data[, c("uuid","ip")])
```

**Rule:**

**(duplicated(data$uuid))** - Classify every repeated occurence of a user ID as TRUE 

**&**

**!duplicated(data[, c("uuid","ip")])** - Classify every non-repeating combination of "uuid" and "ip" as TRUE

_At the intersection of both the rules is - User IDs which are repeating AND who interact with the system from different ip addresses._

```{r}
table(data$multiple_locations)
```

We can see that, from a dataset so large - only 37,823 interactions are happening from locations different from the user's primary location. 

## Further developments: 

**Data Analysis perspective:**
We can say that, there is a lot of scope - such that sending push notifications on mobile devices to increase app interactions, sending newsletters or other measures to drive traffic when users are on the go - by looking at users who are active on multiple days and by targetting users logging in from devices other than their primary device- by collaborating with Data Scientist to analyze/develop features from "useragent" variable.

**Data Science perspective:**
Further, this information can also be combined with the "weekday_biz" feature to extract information such as "users who travel during weekday business hours" and "users who travel during non weekday-business hours" and are interacting with the system. More stratified the data variables - better the information/knowledge we achieve(Simpson's Rule)

----------------------------------------------------------------------------------------------------------------

## Retaining the required columns - Output 
```{r}
output <- data[,c("uuid","multiple_days","weekday_biz", "multiple_locations")]

```
Finally, we can retain the columns which are to be included as a part of the output.csv file. i.e., "uuid","multiple_days","weekday_biz", "multiple_locations"

## Writing to a CSV 
```{r}
# write.csv(data, "output.csv", row.names=FALSE)
```

----------------------------------------------------------------------------------------------------------------

## Simple Reference to  Feature 1 and Feature 3 Rules

**Example Data Frame**

Replicating the problem 

```{r}
df <- data.frame(id = as.factor(c(1:4,1,5,6,4,2,1,1,1,1,2,2)), day = c(rep("x", 5), rep("y", 5),"x","y","z","y","z"))

```

The rule we used produces an outcome similar to

```{r}
df$feature <- (duplicated(df$id)) & !duplicated(df[, c("id","day")]) 
df
```

In case we want the first occurrence and the repeating occurrences on different days to be classified as TRUE, while classifying same day occurrence as FALSE  - 

```{r}
df$feature <- (duplicated(df$id) | duplicated(df[nrow(df):1, "id"])[nrow(df):1]) & !duplicated(df[, c("id","day")])
df
```

----------------------------------------------------------------------------------------------------------------
