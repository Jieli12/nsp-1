est_var <- function(y, x, power = 1 / 2, min.size = 20, estVn2 = FALSE) {
    n <- length(y)
    w.size <- min(n, max(round(n^power), min.size))
    how.many <- n - w.size + 1
    res <- rep(0, how.many)
    for (i in 1:how.many) {
        ind <- i:(i + w.size - 1)
        resp <- y[ind]
        covs <- x[ind, ]
        res[i] <- summary(lm(resp ~ covs))$sigma
    }
    if (estVn2) {
        est <- n / (n - w.size + 1) * sum(res^2)
    } else {
        est <- median(res)
    }
    n
}
n <- 200
x1 <- runif(n, -1, 1)
x2 <- runif(n, -2, 2)
noise <- rnorm(n)
y <- 0.1 * x1 + 0.08 * x2 + noise
x <- cbind(x1, x2)
result <- est_var(y, x)
result_nsp <- nsp::est_var(y,x)
