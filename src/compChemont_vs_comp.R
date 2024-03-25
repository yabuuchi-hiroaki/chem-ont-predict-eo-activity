
library(caret)
library("pROC")

ft <- read.table("out/eocls_t")
ft$label <- as.factor(ft$label)
levels(ft$label) <- c("nega", "posi")
fp <- read.table("out/eocls_p")
fp$label <- as.factor(fp$label)
levels(fp$label) <- c("nega", "posi")

ft_c <- ft[, c("label", colnames(ft)[grep("C", colnames(ft))])]
fp_c <- fp[, c("label", colnames(ft)[grep("C", colnames(ft))])]

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
  return( list( auc(r)[1], auc05, auc02, auc01, max(m[[4]]$ROC) ) )
}

iter <- 10
AUCs <- matrix(0, nrow=10, ncol=iter)
rownames(AUCs) <- c("AUC(CO+C)", "AUC(C)",
  "AUC05(CO+C)", "AUC05(C)", "AUC02(CO+C)", "AUC02(C)",
  "AUC01(CO+C)", "AUC01(C)", "AUCtr(CO+C)", "AUCtr(C)")

for( it in 1:iter ){
  res_ch <- get_auc(ft, fp, it)
  AUCs[1,it] <- res_ch[[1]]
  AUCs[3,it] <- res_ch[[2]]
  AUCs[5,it] <- res_ch[[3]]
  AUCs[7,it] <- res_ch[[4]]
  AUCs[9,it] <- res_ch[[5]]
  res_c <- get_auc(ft_c, fp_c, it)
  AUCs[2,it] <- res_c[[1]]
  AUCs[4,it] <- res_c[[2]]
  AUCs[6,it] <- res_c[[3]]
  AUCs[8,it] <- res_c[[4]]
  AUCs[10,it] <- res_c[[5]]
}

### compare AUC and partial AUCs
apply(AUCs, 1, ave)[1,]
# apply(AUCs, 1, sd)
# t.test(as.numeric(AUCs[1,]), as.numeric(AUCs[2,]), paired=T)
# t.test(as.numeric(AUCs[3,]), as.numeric(AUCs[4,]), paired=T)
# t.test(as.numeric(AUCs[5,]), as.numeric(AUCs[6,]), paired=T)
# t.test(as.numeric(AUCs[7,]), as.numeric(AUCs[8,]), paired=T)
