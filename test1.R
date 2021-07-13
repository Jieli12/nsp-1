rm(list = ls())
source("NSP_for_Github_v5.R", chdir = TRUE)
# verify the cpp functions
n <- 1000
eps <- 0.05
set.seed(1)
e <- rnorm(n)
max.holder.sample.0 <- max_holder(e, eps)
max.holder.sample.1 <- nsp::max_holder(e, eps)
max.holder.sample.2 <- nsp::max_holder_cpp(e, eps)
abs(max.holder.sample.0 - max.holder.sample.1)
abs(max.holder.sample.0 - max.holder.sample.2)
N <- 10
library(tictoc)
set.seed(1)
tic()
thresh.0 <- sim_max_holder(n, N, eps)
toc()
set.seed(1)
tic()
thresh.1 <- nsp::sim_max_holder(n, N, eps)
toc()
set.seed(1)
tic()
thresh.2 <- nsp::sim_max_holder_cpp(n, N, eps)
toc()
sqrt(mean((thresh.0 - thresh.1)^2))
sqrt(mean((thresh.0 - thresh.2)^2))

rm(list = ls())
source("NSP_for_Github_v5.R", chdir = TRUE)
library(tictoc)
set.seed(1)
squarewave <- rep(c(0, 10, 0, 10), each = 200)
x.rt.hard <- squarewave + rt(800, 4) * seq(from = 2, to = 8, length = 800)
eps <- 0.05
alpha <- 0.1
library(microbenchmark)
microbenchmark(
    sim_max_holder(n = 1000, N = 1, eps = eps),
    nsp::sim_max_holder(n = 1000, N = 1, eps = eps),
    nsp::sim_max_holder_cpp(n = 1000, N = 1, eps = eps)
)
# tictoc for thresh computation
tic()
set.seed(1234)
wt0 <- sim_max_holder(n = 1000, N = 1000, eps = eps)
thresh0 <- quantile(wt0, 1 - alpha)
x.rt.hard.sn_init0 <- nsp_poly_selfnorm(x.rt.hard,thresh = thresh0, alpha = alpha, eps = eps)
x.rt.hard.sn_init0
toc()

# tictoc for thresh computation (c++)
tic()
set.seed(1234)
wt1 <- nsp::sim_max_holder_cpp(1000,1000, eps)
thresh1 <- quantile(wt1, 1 - alpha)
x.rt.hard.sn_init1 <- nsp_poly_selfnorm(x.rt.hard,thresh = thresh1, alpha = alpha, eps = eps)
x.rt.hard.sn_init1
toc()


### test nsp_poly_selfnorm_cpp()
rm(list = ls())
library(nsp)
set.seed(1)
squarewave <- rep(c(0, 10, 0, 10), each = 200)
x.rt.hard <- squarewave + rt(800, 4) * seq(from = 2, to = 8, length = 800)
eps <- 0.03
alpha <- 0.1
result1 <- nsp_poly_selfnorm_cpp(x.rt.hard, alpha = alpha, eps = eps)
eps <- 0.1
result2 <- nsp_poly_selfnorm_cpp(x.rt.hard, alpha = alpha, eps = eps)
set.seed(1234)
eps <- 0.05
result3 <- nsp_poly_selfnorm_cpp(x.rt.hard, alpha = alpha, eps = eps)
