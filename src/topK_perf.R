library(caret)
library("pROC")

n_sel <- c(4, 8, 16, 32, 64, 128, 256)
iter <- 10

ft <- read.table("out/eocls_t")
ft$label <- as.factor(ft$label)
levels(ft$label) <- c("nega", "posi")
fp <- read.table("out/eocls_p")
fp$label <- as.factor(fp$label)
levels(fp$label) <- c("nega", "posi")

fs1 <- read.table("out/hic", sep="\t", header=T)

ft_c0 <- ft[, colnames(ft)[grep("C", colnames(ft))]]
fp_c0 <- fp[, colnames(ft)[grep("C", colnames(ft))]]
ft_c1 <- ft_c0[, apply(ft_c0, 2, var) !=0]
fp_c1 <- fp_c0[, apply(ft_c0, 2, var) !=0]

pca_t <- prcomp(ft_c1, scale=F)
#pca_t <- prcomp(ft_c1, scale=T)
pca_p <- predict(pca_t, fp_c1)

ft_c<- data.frame(ft$label, pca_t$x)
fp_c<- data.frame(fp$label, pca_p)
colnames(ft_c)[1] <- "label"
colnames(fp_c)[1] <- "label"

get_auc <- function (dat_t, dat_p, ns){
  sr <- c("gini", "extratrees")
  if( ncol(dat_t) <= 3 ){
    gr <- expand.grid(mtry=2, min.node.size=1, splitrule=sr)
  }else if( ncol(dat_t) <= 5 ){
    gr <- expand.grid(mtry=c(2,4), min.node.size=1, splitrule=sr)
  }else if( ncol(dat_t) <= 9 ){
    gr <- expand.grid(mtry=c(2,4,8), min.node.size=1, splitrule=sr)
  }else if( ncol(dat_t) <= 17 ){
    gr <- expand.grid(mtry=c(2,4,8,16), min.node.size=1, splitrule=sr)
  }else{
    gr <- expand.grid(mtry=c(2,4,8,16,32), min.node.size=1, splitrule=sr)
  }
  ctrl <- trainControl(method="cv",
    summaryFunction = twoClassSummary, classProbs = TRUE)
  set.seed(ns)
  m <- train(data = dat_t, label ~ ., method = "ranger", tuneGrid=gr,
    metric="ROC", trControl = ctrl)
  p <- predict(m, newdata = dat_p, type="prob")
  r <- roc(dat_p$label ~ p$posi)
  p <- predict(m, newdata = dat_p)
  t <- table(dat_p$label, p)
  auc01 <- auc(r, partial.auc=c(1,0.9))[1]
  auc02 <- auc(r, partial.auc=c(1,0.8))[1]
  auc05 <- auc(r, partial.auc=c(1,0.5))[1]
  return( list( auc(r)[1], auc01, auc02, auc05, max(m[[4]]$ROC)) )
}

AUCs <- matrix(0, nrow=length(n_sel), ncol=iter)
colnames(AUCs) <- 1:iter
rownames(AUCs) <- n_sel
AUC01s <- AUCs
AUC02s <- AUCs 
AUC05s <- AUCs 
AUCtr <- AUCs 
PC_AUCs <- AUCs
PC_AUC01s <- AUCs
PC_AUC02s <- AUCs
PC_AUC05s <- AUCs
PC_AUCtr <- AUCs

for ( ns in 1:length(n_sel) ){
  dat_t1 <- ft[, c("label", fs1[1:n_sel[ns], 2 ]) ]
  dat_p1 <- fp[, c("label", fs1[1:n_sel[ns], 2 ]) ]
  for ( it in 1:iter ){
    res <- get_auc(dat_t1, dat_p1, it)
    AUCs[ns,it] <- res[[1]]
    AUC01s[ns,it] <- res[[2]]
    AUC02s[ns,it] <- res[[3]]
    AUC05s[ns,it] <- res[[4]]
    AUCtr[ns,it] <- res[[5]]
  }
  dat_t2 <- ft_c[, 1:(n_sel[ns]+1) ]
  dat_p2 <- fp_c[, 1:(n_sel[ns]+1) ]
  for ( it in 1:iter ){
    res <- get_auc(dat_t2, dat_p2, it)
    PC_AUCs[ns,it] <- res[[1]]
    PC_AUC01s[ns,it] <- res[[2]]
    PC_AUC02s[ns,it] <- res[[3]]
    PC_AUC05s[ns,it] <- res[[4]]
    PC_AUCtr[ns,it] <- res[[5]]
  }
}

cols <- c("blue", "lightblue", "gray")
par( mfrow=c(2,2) )
plot(n_sel, n_sel, col=1, ylim=c(0.5,0.8), xlab="top K", ylab="AUC", las=1)
par(new=T)
plot(n_sel, apply(AUCs, 1, ave)[1,],
  type="b", col=cols[1], ylim=c(0.5, 0.8), xlab="", ylab="",
  lwd=2, las=1, pch=c(19,17,15)[1], lty=c(1,2)[1] )
par(new=T)
plot(n_sel, apply(PC_AUCs, 1, ave)[1,],
  type="b", col=cols[2], ylim=c(0.5, 0.8), xlab="", ylab="",
  lwd=2, las=1, pch=c(19,17,15)[2], lty=c(1,2)[2] )
abline(h=0.5, lty=3, col="gray", lwd=2)
legend("bottomright", legend = c("HIC", "PCA", "random"),
  col = cols, pch = c(19,17), lty = c(1,2,3), bg="white")

plot(n_sel, n_sel, col=1, ylim=c(0.1,0.32), xlab="top K",
  ylab=expression(AUC[0.5]), las=1)
par(new=T)
plot(n_sel, apply(AUC05s, 1, ave)[1,],
  type="b", col=cols[1], ylim=c(0.1, 0.32), xlab="", ylab="",
  lwd=2, las=1, pch=c(19,17,15)[1], lty=c(1,2)[1] )
par(new=T)
plot(n_sel, apply(PC_AUC05s, 1, ave)[1,],
  type="b", col=cols[2], ylim=c(0.1, 0.32), xlab="", ylab="",
  lwd=2, las=1, pch=c(19,17,15)[2], lty=c(1,2)[2] )
abline(h=0.125, lty=3, col="gray", lwd=2)
legend("bottomright", legend = c("HIC", "PCA", "random"),
  col = cols, pch = c(19,17), lty = c(1,2,3), bg="white")

plot(n_sel, n_sel, col=1, ylim=c(0,0.08), xlab="top K",
  ylab=expression(AUC[0.2]), las=1)
par(new=T)
plot(n_sel, apply(AUC02s, 1, ave)[1,],
  type="b", col=cols[1], ylim=c(0, 0.08), xlab="", ylab="",
  lwd=2, las=1, pch=c(19,17,15)[1], lty=c(1,2)[1] )
par(new=T)
plot(n_sel, apply(PC_AUC02s, 1, ave)[1,],
  type="b", col=cols[2], ylim=c(0, 0.08), xlab="", ylab="",
  lwd=2, las=1, pch=c(19,17,15)[2], lty=c(1,2)[2] )
abline(h=0.02, lty=3, col="gray", lwd=2)
legend("bottomright", legend = c("HIC", "PCA", "random"),
  col = cols, pch = c(19,17), lty = c(1,2,3), bg="white")

plot(n_sel, n_sel, col=1, ylim=c(0,0.03), xlab="top K",
  ylab=expression(AUC[0.1]), las=1)
par(new=T)
plot(n_sel, apply(AUC01s, 1, ave)[1,],
  type="b", col=cols[1], ylim=c(0, 0.03), xlab="", ylab="",
  lwd=2, las=1, pch=c(19,17,15)[1], lty=c(1,2)[1] )
par(new=T)
plot(n_sel, apply(PC_AUC01s, 1, ave)[1,],
  type="b", col=cols[2], ylim=c(0, 0.03), xlab="", ylab="",
  lwd=2, las=1, pch=c(19,17,15)[2], lty=c(1,2)[2] )
abline(h=0.005, lty=3, col="gray", lwd=2)
legend("bottomright", legend = c("HIC", "PCA", "random"),
  col = cols, pch = c(19,17), lty = c(1,2,3), bg="white")

plot(n_sel, n_sel, col=1, ylim=c(0.5,0.8), xlab="top K",ylab="AUCtr", las=1)
par(new=T)
plot(n_sel, apply(AUCtr, 1, ave)[1,],
  type="b", col=cols[1], ylim=c(0.5, 0.8), xlab="", ylab="",
  lwd=2, las=1, pch=c(19,17,15)[1], lty=c(1,2)[1] )
par(new=T)
plot(n_sel, apply(PC_AUCtr, 1, ave)[1,],
  type="b", col=cols[2], ylim=c(0.5, 0.8), xlab="", ylab="",
  lwd=2, las=1, pch=c(19,17,15)[2], lty=c(1,2)[2] )
legend("bottomright", legend = c("HIC", "PCA", "random"),
  col = cols, pch = c(19,17), lty = c(1,2,3), bg="white")

# summary(pca_t)$importance[,1:32]
k <- c(2,4,8,16,32,64,128,256)
plot(k, 100 * summary(pca_t)$importance[3,k], type="b", pch=17, lwd=2,
  col="lightblue", las=1, xlab="#Principal components",
  ylab="%Cumulative variance explained", ylim=c(0,100))

# apply(AUCs, 1, ave)[1,]
# apply(AUCs, 1, sd)

# apply(PC_AUCs, 1, ave)[1,]
# apply(PC_AUCs, 1, sd)
