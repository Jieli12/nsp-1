# for branch dev_api
library(nsp)
library(tictoc)
set.seed(1)
eps <- 0.05
wt <- nsp::sim_max_holder_cpp(1000, 1000, eps)
alpha <- 0.1
thresh <- quantile(wt, 1 - alpha)

squarewave <- rep(c(0, 10, 0, 10), each = 200)
x.rt.hard <- squarewave + rt(800, 4) * seq(from = 2, to = 8, length = 800)
tic()
set.seed(1)
x.rt.hard.sn_init <- nsp_poly_selfnorm_cpp(x.rt.hard, thresh = thresh, alpha = alpha, eps = eps)
x.rt.hard.sn_init
toc()
