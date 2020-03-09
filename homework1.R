rm(list=ls())
#set working directory to source file location, only for RStudio
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

library(readxl)
library(tidyverse)
library(pmml)
library(rpart)

# 1)	Read the csv file
wv_data <- read_csv("data/WV_US.csv")

# 2)	Dichotomize V23 where 0 is assigned for values 1-6 and 1 is assigned for values 7-10.  
# 0 represents an unsatisfactory score and 1 represents a satisfactory score.

#Check out the column
head(wv_data$V23)
summary(wv_data$V23)

#create a copy of the wanted column
wv_data$V23_New = wv_data$V23
str(wv_data$V23_New)

#Change values to 0 or 1
index <- wv_data$V23_New <=6 & wv_data$V23_New >=1
wv_data$V23_New[index] <- 0

index <- wv_data$V23_New <=10 & wv_data$V23_New >=7
wv_data$V23_New[index] <- 1

index <- wv_data$V23_New == -99
wv_data$V23_New[index] <- NA

# 3)	There are too many variables eligible as predictors, luckily, your boss has narrowed 
# those to V55, V56, V59, V102 and V152.
keeps <- c("V23_New", "V55", "V56", "V59", "V102",  "V152")
df <- wv_data[keeps]
head(df)

# 4)	Create simple statistics for the dependent and independent variables
summary(df)

# 5)	Be careful of missing data which is coded like values such as -99 or -1.  They might need to be 
# recoded.  When there is a missing value for V23, that record can not be used for modelling purposes.
df$V55[df$V55 == -99] <- NA
df$V56[df$V56 == -99] <- NA
df$V59[df$V59 == -99] <- NA
df$V102[df$V102 == -99] <- NA
df$V152[df$V152 == -99] <- NA

# 6)	Use a random number seed so that the results can replicated
set.seed(142539241)
randIndex <- sample(1:nrow(df))
head(randIndex)
min(randIndex)
max(randIndex)

# 7)	Partition the data into 2/3 training and 1/3 testing
cutoff <- floor(nrow(df)*0.66)
inTrain <- randIndex[1:cutoff]

trainData <- df[inTrain,]
testData <- df[-inTrain,]

# 8)	Use a decision tree for the binary response of the recoded V23
satisfaction_model <- rpart(V23_New~ V55 + V56 + V59 + V102 + V152, 
                    data=trainData, method="class")
plot(satisfaction_model)
text(satisfaction_model, cex=.75)

# 9)	For the model, create a PMML file
satisfaction_PMML <- pmml(satisfaction_model)
saveXML(satisfaction_PMML, "satisfaction.pmml")
# 10)	Create a confusion matrix based on the test data.

# Predictions
pred <- predict(satisfaction_model, testData, type="class")
table(pred)
# Confusion Matrix
table(pred, testData$V23_New)
proportion_matrix = prop.table(table(pred, testData$V23_New))   
print(proportion_matrix)

#Tell me if the model substantially outperforms a naïve model. Why or Why not?
naive_accuracy = (nrow(subset(df, V23_New=="1")))/(nrow(df))
accuracy = proportion_matrix[1,1] + proportion_matrix[2,2]
paste("The Naive Accuracy is ", round(naive_accuracy, digits=2) , " and the model's accuracy is ", round(accuracy, digits=2), sep="")
