# plot ROC curve 
# plot prob. for comp+hier selected by HIC vs. comp 
# 

library(caret)
library("pROC")

n_sel <- 32
iter <- 10

ft <- read.table("out/eocls_t")
ft$label <- as.factor(ft$label)
levels(ft$label) <- c("nega", "posi")
fp <- read.table("out/eocls_p")
fp$label <- as.factor(fp$label)
levels(fp$label) <- c("nega", "posi")

fs1 <- read.table("out/hic", sep="\t", header=T)

dat_t1 <- ft[, c("label", fs1[1:n_sel, 2 ]) ]
dat_p1 <- fp[, c("label", fs1[1:n_sel, 2 ]) ]

ft_c <- ft[, c("label", colnames(ft)[grep("C", colnames(ft))])]
fp_c <- fp[, c("label", colnames(ft)[grep("C", colnames(ft))])]

fr3 <- read.table("out/eocls_assay")
fr3$label <- as.factor(fr3$label)
levels(fr3$label) <- c("nega", "posi")
dat_r3 <- fr3[, c("label", fs1[1:n_sel, 2 ]) ]
fr3_c <- fr3[, c("label", colnames(ft)[grep("C", colnames(ft))])]

sr <- c("gini", "extratrees")
gr <- expand.grid(mtry=c(2,4,8), min.node.size=1, splitrule=sr)
ctrl <- trainControl(method="cv", summaryFunction = twoClassSummary, 
	classProbs = TRUE)

p0_it <- matrix(0, nrow=nrow(fp), ncol=iter)
p1_it <- matrix(0, nrow=nrow(fp), ncol=iter)
p2_it <- matrix(0, nrow=nrow(fp), ncol=iter)
r0_it <- matrix(0, nrow=nrow(fr3), ncol=iter)
r1_it <- matrix(0, nrow=nrow(fr3), ncol=iter)
r2_it <- matrix(0, nrow=nrow(fr3), ncol=iter)

for( it in 1:iter ){
    ### train & predict by comp+hier selected by HIC
    set.seed(it)
    m1 <- train(data = dat_t1, label ~ ., method = "ranger", tuneGrid=gr,
    metric="ROC", trControl = ctrl)
    p1 <- predict(m1, newdata = dat_p1, type="prob")
    r1 <- predict(m1, newdata = dat_r3, type="prob")
    p1_it[, it] <- p1$posi
    r1_it[, it] <- r1$posi	
    ### train & predict by comp
    set.seed(it)
    m2 <- train(data = ft_c, label ~ ., method = "ranger", tuneGrid=gr,
    metric="ROC", trControl = ctrl)
    p2 <- predict(m2, newdata = fp_c, type="prob")
    r2 <- predict(m2, newdata = fr3_c, type="prob")
    p2_it[, it] <- p2$posi
    r2_it[, it] <- r2$posi
}

roc1 <- roc(fp$label ~ apply(p1_it, 1, ave)[1,], direction = "<")
roc2 <- roc(fp_c$label ~ apply(p2_it, 1, ave)[1,], direction = "<")

roc1r <- roc(fr3$label ~ apply(r1_it, 1, ave)[1,], direction = "<")
roc2r <- roc(fr3$label ~ apply(r2_it, 1, ave)[1,], direction = "<")

plot(roc1, col="blue", lty=1, lwd=2, las=1)
par(new=T)
plot(roc2, col="lightblue", lty=2, lwd=2, las=1)

plot(roc1r, col="blue", lty=1, lwd=2, las=1)
par(new=T)
plot(roc2r, col="lightblue", lty=2, lwd=2, las=1)
