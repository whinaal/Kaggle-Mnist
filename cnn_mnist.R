#Set Path Data
pathData = 'D:/Dattabot/Kaggle/mnist'
setwd(pathData)

#Install Packages
install.packages("drat", repos="https://cran.rstudio.com")
drat:::addRepo("dmlc")
install.packages("mxnet")
install_version("DiagrammeR", version = "0.8.1", repos = "http://cran.us.r-project.org")
library(mxnet)

#Load train and test dataset 
Data = read.csv('train.csv')
Datest = read.csv('test.csv')

#setup train and test dataset
train <- data.matrix(Data)
test <- data.matrix(Datest)

#normalization setup
train.x <- train[,-1]
test.x <- t(test/255)
train.x <- t(train.x/255)
output_training <- train[,1]

#Define network architecture via symbolic API
data <- mx.symbol.Variable("data")

# first convolutional NN
conv1 <- mx.symbol.Convolution(data=data, kernel=c(5,5), num_filter=20)
tanh1 <- mx.symbol.Activation(data=conv1, act_type="relu")
pool1 <- mx.symbol.Pooling(data=tanh1, pool_type="max",kernel=c(2,2), stride=c(2,2))

# second convolutional NN
conv2 <- mx.symbol.Convolution(data=pool1, kernel=c(5,5), num_filter=50)
tanh2 <- mx.symbol.Activation(data=conv2, act_type="relu")
pool2 <- mx.symbol.Pooling(data=tanh2, pool_type="max",kernel=c(2,2), stride=c(2,2))

# first fully connected layer
flatten <- mx.symbol.Flatten(data=pool2)
fc1 <- mx.symbol.FullyConnected(data=flatten, num_hidden=500)
tanh3 <- mx.symbol.Activation(data=fc1, act_type="relu")

# second fully connected layer 
fc2 <- mx.symbol.FullyConnected(data=tanh3, num_hidden=10)

# softmax loss
lenet <- mx.symbol.SoftmaxOutput(data=fc2)

#creating array
train.array <- train.x
dim(train.array) <- c(28,28,1,ncol(train.x))
test.array <- test.x
dim(test.array) <- c(28,28,1, ncol(test.x))
mx.set.seed(0)
tic <- proc.time()

#opsi 1 : train on cpu 
devices <- mx.cpu()

#opsi 2 : train on gpu 
n.gpu <- 1
devices <- lapply(0:(n.gpu-1), function(i) {mx.gpu(i)})

#Fit CNN model (LeNet Architecture)
model <- mx.model.FeedForward.create(lenet,
                                     X = train.array,
                                     y = output_training,
                                     ctx = devices,
                                     num.round = 15,
                                     array.batch.size = 40,
                                     learning.rate = 0.01,
                                     momentum = 0.9,
                                     eval.metric = mx.metric.accuracy,
                                     epoch.end.callback = mx.callback.log.train.metric(100))
#print running time
print(proc.time() - tic)

#do prediction
preds <- predict(model, test.array)
pred.label <- max.col(t(preds)) - 1

#write
write.csv(pred.label,'cnnmnist3.csv')