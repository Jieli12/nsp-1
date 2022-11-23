setwd(dirname(rstudioapi::getSourceEditorContext()$path))
rm(list = ls())
source("NSP_for_Github_v7L2OLS.R", chdir = TRUE)
set.seed(1)
f <- c(1:100, 100:1, 1:100)
y <- f + stats::rnorm(300) * 15
x <- matrix(0, 300, 2)
x[,1] <- 1
x[,2] <- seq(from = 0, to = 1, length = 300)
result_1 <- nsp::nsp(y, x, 100, 15 * nsp::thresh_kab(300, .01))

result_2 <- nsp(y, x, 100, 15 * thresh_kab(300, .01))
result_1
result_2

# test for weight least square: dxyadic
M <- 100
n <- 300
M <- min(M, (n - 1) * n / 2)

ind0 <- grid_intervals_sorted(n, M)
ads.array <- all_dyadic_scans_array(cbind(y,x))
s <- ind0[1]
e <- ind0[2]
n <- e-s+1
indices <- ((ads.array$shifts + 1) <= (n / 2))

ads.array$res <- ads.array$res[s:e, , indices, drop = F]

ads.array$shifts <- ads.array$shifts[indices]

dm <- dim(ads.array$res)

f.con.rhs.core <- matrix(0, 0, dm[2])

scales <- length(ads.array$shifts)

for (i in 1:scales) {
    shift <- ads.array$shifts[i]
    f.con.rhs.current <- ads.array$res[1:(n - shift), , i]
    f.con.rhs.core <- rbind(f.con.rhs.core, f.con.rhs.current)
    if (i == 1) {
        freq <- rep(1, n)
    } else {
        freq <- freq + c(1:shift, rep(2^(i - 1), n - 2 * shift), shift:1)
    }
}
index <- rep(1:n, freq)
y_init <- f.con.rhs.core[1:n, 1]
x_init <- f.con.rhs.core[1:n, -1]
y <- y_init[index]
x <- x_init[index, ]
# max_shifts <- max(ads.array$shifts)
result <- lm(y ~ x - 1)
summary(result)
# for weighted ols
result_wt <- lm(y_init ~ x_init - 1, weights = freq)
summary(result_wt)

library(nlme)
result_gls <- gls(yd ~ xd - 1)
summary(result_gls)
# weight least square
freq <- rep(1,n)
for (i in 2:scales) {
    shift <- ads.array$shifts[i]
    freq <- freq + c(1:shift,rep(2^(i-1),n-2*shift),shift:1) 
}
# freq <- freq/sum(freq)
y_rep <- rep(y[1:22],freq)
x_rep1 <- rep(x[1:22,1],freq)
x_rep2 <- rep(x[1:22,2],freq)
x_rep <- cbind(x_rep1,x_rep2)
result_wt <- lm(y_rep ~ x_rep-1)
summary(result_wt)



