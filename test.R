source("NSP_for_Github_v5.R", chdir = TRUE)

library(tictoc)
set.seed(1)
eps <- 0.04
wt <- nsp::sim_max_holder_cpp(1000, 1000, eps)
alpha <- 0.1
thresh <- quantile(wt, 1 - alpha)

squarewave <- rep(c(0, 10, 0, 10), each = 200)
x.rt.hard <- squarewave + rt(800, 4) * seq(from = 2, to = 8, length = 800)
tic()
set.seed(1)
x.rt.hard.sn_init <- nsp_poly_selfnorm(x.rt.hard, thresh = thresh, alpha = alpha, eps = eps)
toc()
tic()
set.seed(1)
x.rt.hard.sn_cpp <- nsp_poly_selfnorm_cpp(x.rt.hard, eps = 0.03)
toc()


rm(list = ls())
source("NSP_for_Github_v5.R", chdir = TRUE)
library(tictoc)
set.seed(1)
squarewave <- rep(c(0, 10, 0, 10), each = 200)
x.rt.hard <- squarewave + rt(800, 4) * seq(from = 2, to = 8, length = 800)
eps <- 0.05
alpha <- 0.1
# tictoc for thresh computation
tic()
set.seed(1234)
wt0 <- sim_max_holder(n = 1000, N = 100, eps = eps)
thresh0 <- quantile(wt0, 1 - alpha)
x.rt.hard.sn_init0 <- nsp_poly_selfnorm(x.rt.hard, thresh = thresh0, alpha = alpha, eps = eps)
x.rt.hard.sn_init0
toc()

# tictoc for thresh computation (c++)
tic()
set.seed(1234)
wt1 <- nsp::sim_max_holder_cpp(1000, 1000, eps)
thresh1 <- quantile(wt1, 1 - alpha)
x.rt.hard.sn_init1 <- nsp_poly_selfnorm(x.rt.hard, thresh = thresh1, alpha = alpha, eps = eps)
x.rt.hard.sn_init1
toc()

library(microbenchmark)
microbenchmark(
    sim_max_holder(n = 1000, N = 1, eps = eps),
    nsp::sim_max_holder(n = 1000, N = 1, eps = eps)
)
nsp_poly_selfnorm_cpp <- function(x, M = 1000, thresh = NULL, power = 1 / 2, minsize = 20, alpha = 0.1, deg = 0, eps = 0.03, overlap = FALSE) {
    n <- length(x)
    x.c <- matrix(x, n, deg + 1)
    for (i in 1:(deg + 1)) {
        x.c[, i] <- seq(from = 0, to = 1, length = n)^(i - 1)
    }
    if (is.null(alpha)) {
        alpha <- 0.1
    }
    if (is.null(thresh)) {
        if (eps == 0.03 | eps == 0.1) {
            wh <- get(paste("wiener.holder_", as.character(eps), sep = ""))
        } else {
            wh <- sim_max_holder_cpp(n = 1000, N = 1000, eps)
        }
        thresh <- as.numeric(quantile(wh, 1 - alpha))
    }
    nsp_selfnorm(x, x.c, M, thresh, power, minsize, eps, overlap)
}