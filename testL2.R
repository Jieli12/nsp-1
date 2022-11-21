setwd(dirname(rstudioapi::getSourceEditorContext()$path))
rm(list = ls())
source("NSP_for_Github_v7L2.R", chdir = TRUE)
set.seed(1)
f <- c(1:100, 100:1, 1:100)
y <- f + stats::rnorm(300) * 15
x <- matrix(0, 300, 2)
x[,1] <- 1
x[,2] <- seq(from = 0, to = 1, length = 300)
result_1 <- nsp::nsp(y, x, 100, 15 * nsp::thresh_kab(300, .1))

result_2 <- nsp(y, x, 100, 15 * thresh_kab(300, .1))
result_1
result_2

# test for weight least square
M <- 100
n <- 300
M <- min(M, (n - 1) * n / 2)

ind0 <- grid_intervals_sorted(n, M)
ads.array <- all_dyadic_scans_array(cbind(y,x))
s <- ind0[1]
e <- indo[2]
n <- e-s+1
indices <- ((ads.array$shifts + 1) <= (n / 2))
    
    ads.array$res <- ads.array$res[1:300, , indices, drop = F]
    
    ads.array$shifts <- ads.array$shifts[indices]
    
    M <- min(M, (n - 1) * n / 2)
    
    ind <- grid_intervals_sorted(n, M)
    
    M <- dim(ind)[2]
    
    res <- matrix(0, M, 3)
    
    res[, 1:2] <- t(ind)
    
    zero.check <- TRUE
    j <- 1
    
    while (zero.check && (j <= M)) {
        res[j, 3] <- check_interval_array(res[j, 1:2], ads.array, thresh)
        zero.check <- (res[j, 3] == 0)
        j <- j + 1
    }
    