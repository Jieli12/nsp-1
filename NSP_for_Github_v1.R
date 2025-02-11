# Software to accompany P. Fryzlewicz (2020) "Narrowest Significance Pursuit: inference for multiple change-points in linear models".
# Please install R package "lpSolve" first, and then source the current file into R.
# Please read the descriptions of the nsp_* functions below.
# Please let me know (p.fryzlewicz@lse.ac.uk) of any omissions/errors/etc.


library(lpSolve)
load("wiener_holder_norms.txt")


nsp <- function(x, constraints, M, thresh, stage1 = "narrowest", overlap = FALSE, buffer = 0) {

    # Generic NSP function. Do not use unless you know what 'thresh' value to set. Use one of the nsp_* functions below (without _selfnorm) instead.
    # x - data (referred to in the paper as Y).
    # constraints - design matrix (referred to in the paper as X).
    # M - number of intervals to draw; this implementation uses a deterministic equispaced grid for drawing intervals.
    # thresh - threshold value (lambda_alpha in the paper).
    # stage1 - obsolete parameter, this will be removed for CRAN.
    # overlap - FALSE means no overlap, TRUE means an overlap as specified in Section 4 of the paper.
    # buffer - set to zero if no autoregression present in constraints; otherwise set to the order of the autoregression.
    #
    # Returns:
    # res - matrix whose first two rows are start- and end-points (respectively) of the detected intervals of significance

    d <- dim(constraints)

    x.c <- cbind(x, constraints)

    x.c.ads <- all.dyadic.scans.array(x.c)

    res <- iter_random_checks_scan_array(c(1, d[1]), x.c.ads, M, thresh, stage1, overlap, buffer)

    res
}


nsp_poly <- function(x, M = 1000, thresh = NULL, sigma = NULL, alpha = 0.1, deg = 0, stage1 = "narrowest", overlap = FALSE) {

    # NSP implementation when x is believed to be a piecewise polynomial plus iid Gaussian noise. This covers Scenarios 1 and 2 from the paper.
    # x - data (referred to in the paper as Y).
    # M - number of intervals to draw; this implementation uses a deterministic equispaced grid for drawing intervals.
    # thresh - threshold value (lambda_alpha in the paper). If NULL, a suitable threshold is derived as the 100(1-alpha)% quantile of the Gaussian scan statistics.
    # sigma - estimate of the standard deviation of the noise. If NULL, it is estimated via MAD.
    # alpha - desired maximum probability of obtaining an interval that does not cover a true change-point.
    # deg - degree of the underlying polynomial
    # stage1 - obsolete parameter, this will be removed for CRAN.
    # overlap - FALSE means no overlap, TRUE means an overlap as specified in Section 4 of the paper.
    #
    # Returns:
    # res - matrix whose first two rows are start- and end-points (respectively) of the detected intervals of significance

    n <- length(x)

    x.c <- matrix(x, n, deg + 1)

    for (i in 1:(deg + 1)) {
        x.c[, i] <- seq(from = 0, to = 1, length = n)^(i - 1)
    }

    if (is.null(thresh)) {
        if (is.null(sigma)) sigma <- mad(diff(x / sqrt(2)))
        if (is.null(alpha)) alpha <- 0.1

        thresh <- sigma * thresh.kab(n, alpha)
    }

    nsp(x, x.c, M, thresh, stage1, overlap)
}


nsp_poly_ar <- function(x, ord = 1, M = 1000, thresh = NULL, sigma = NULL, alpha = 0.1, deg = 0, power = 1 / 2, min.size = 20, stage1 = "narrowest", overlap = FALSE, buffer = ord) {

    # NSP implementation when x is believed to be a piecewise polynomial plus autoregressive Gaussian noise. This covers Scenario 4 from the paper (with a piecewise polynomial regression part).
    # x - data (referred to in the paper as Y).
    # ord - the order of the autoregression.
    # M - number of intervals to draw; this implementation uses a deterministic equispaced grid for drawing intervals.
    # thresh - threshold value (lambda_alpha in the paper). If NULL, a suitable threshold is derived as the 100(1-alpha)% quantile of the Gaussian scan statistics.
    # sigma - estimate of the standard deviation of the noise. If NULL, it is estimated via the MOLS estimator described in the paper.
    # alpha - desired maximum probability of obtaining an interval that does not cover a true change-point.
    # deg - degree of the underlying polynomial
    # power - parameter of the MOLS estimator of sigma, best left at 1/2.
    # min.size - parameter of the MOLS estimator of sigma, best left at 20.
    # stage1 - obsolete parameter, this will be removed for CRAN.
    # overlap - FALSE means no overlap, TRUE means an overlap as specified in Section 4 of the paper.
    # buffer - how many time points to skip when recursively launching NSP to the left and right of each detected interval of significance.
    #
    # Returns:
    # res - matrix whose first two rows are start- and end-points (respectively) of the detected intervals of significance

    n <- length(x)

    x.c <- matrix(x, n, deg + 1 + ord)

    for (i in 1:(deg + 1)) {
        x.c[, i] <- seq(from = 0, to = 1, length = n)^(i - 1)
    }

    if (ord) for (i in 1:ord) x.c[(1 + i):n, deg + 1 + i] <- x[1:(n - i)]

    x.c <- x.c[(ord + 1):n, ]

    x <- x[(ord + 1):n]

    if (is.null(thresh)) {
        if (is.null(sigma)) sigma <- est_var(x, x.c, power, min.size)
        if (is.null(alpha)) alpha <- 0.1

        thresh <- sigma * thresh.kab(n - ord, alpha)
    }

    res <- nsp(x, x.c, M, thresh, stage1, overlap, buffer)

    res[1:2, ] <- res[1:2, ] + ord

    res
}


nsp_tvreg <- function(y, x, M = 1000, thresh = NULL, sigma = NULL, alpha = 0.1, power = 1 / 2, min.size = 20, stage1 = "narrowest", overlap = FALSE) {

    # NSP for general regression, but without autoregression. This covers Scenario 3 from the paper.
    # y - data (referred to in the paper as Y).
    # x - design matrix (referred to in the paper as X).
    # M - number of intervals to draw; this implementation uses a deterministic equispaced grid for drawing intervals.
    # thresh - threshold value (lambda_alpha in the paper). If NULL, a suitable threshold is derived as the 100(1-alpha)% quantile of the Gaussian scan statistics.
    # sigma - estimate of the standard deviation of the noise. If NULL, it is estimated via the MOLS estimator described in the paper.
    # alpha - desired maximum probability of obtaining an interval that does not cover a true change-point.
    # power - parameter of the MOLS estimator of sigma, best left at 1/2.
    # min.size - parameter of the MOLS estimator of sigma, best left at 20.
    # stage1 - obsolete parameter, this will be removed for CRAN.
    # overlap - FALSE means no overlap, TRUE means an overlap as specified in Section 4 of the paper.
    #
    # Returns:
    # res - matrix whose first two rows are start- and end-points (respectively) of the detected intervals of significance

    n <- length(y)

    if (is.null(thresh)) {
        if (is.null(sigma)) sigma <- est_var(y, x, power, min.size)
        if (is.null(alpha)) alpha <- 0.1

        thresh <- sigma * thresh.kab(n, alpha)
    }

    nsp(y, x, M, thresh, stage1, overlap)
}


nsp_selfnorm <- function(x, constraints, M, thresh, power = 1 / 2, minsize = 20, stage1 = "narrowest", eps = 0.03, c = exp(1 + 2 * eps), overlap = FALSE) {

    # Self-normalised NSP for general regression.
    # x - data (referred to in the paper as Y).
    # constraints - design matrix (referred to in the paper as X).
    # M - number of intervals to draw; this implementation uses a deterministic equispaced grid for drawing intervals.
    # thresh - threshold value (lambda_alpha in the paper).
    #     Example: suppose eps [see below] is 0.03 and you wish to choose the threshold so that alpha = 0.1. Do
    #     thresh <- quantile(wiener.holder_0.03, 0.9)
    #     where the suffix 0.03 is the value of eps, and 0.9 = 1 - alpha.
    #     The two pre-computed simulated distributions are in: wiener.holder_0.03 and wiener.holder_0.1.
    #     These two variables get loaded on executing load("wiener_holder_norms.txt") at the start of this script.
    #     If thresh for a different value of eps is required, for example 0.05, first do
    #     wiener.holder_0.05 <- sim.max.holder(1000, 1000, 0.05)
    # power - parameter for estimating the global RSS, best left at 1/2.
    # min.size - parameter for estimating the global RSS, best left at 20.
    # stage1 - obsolete parameter, this will be removed for CRAN.
    # eps - epsilon from the paper.
    # c - c (linked to epsilon) from the paper.
    # overlap - FALSE means no overlap, TRUE means an overlap as specified in Section 4 of the paper.
    #
    # Returns:
    # res - matrix whose first two rows are start- and end-points (respectively) of the detected intervals of significance

    d <- dim(constraints)

    x.c <- cbind(x, constraints)

    x.c.ads <- all.dyadic.scans.array(x.c)

    Vn2est <- est_var(x, constraints, power, minsize, TRUE)

    res <- ircs2sas(c(1, d[1]), x.c.ads, M, thresh, Vn2est, stage1, eps, c, overlap)

    res
}


nsp_poly_selfnorm <- function(x, M = 1000, thresh = NULL, power = 1 / 2, minsize = 20, alpha = 0.1, deg = 0, stage1 = "narrowest", eps = 0.03, c = exp(1 + 2 * eps), overlap = FALSE) {

    # Self-normalised NSP when x is believed to be a piecewise polynomial plus (possibly heterogeneous and/or heavy-tailed) noise.
    # x - data (referred to in the paper as Y).
    # M - number of intervals to draw; this implementation uses a deterministic equispaced grid for drawing intervals.
    # thresh - threshold value (lambda_alpha in the paper), best left at NULL but specified implicitly via alpha.
    # power - parameter for estimating the global RSS, best left at 1/2.
    # min.size - parameter for estimating the global RSS, best left at 20.
    # alpha - desired maximum probability of obtaining an interval that does not cover a true change-point.
    # deg - degree of the underlying polynomial
    # stage1 - obsolete parameter, this will be removed for CRAN.
    # eps - epsilon from the paper.
    # c - c (linked to epsilon) from the paper.
    # overlap - FALSE means no overlap, TRUE means an overlap as specified in Section 4 of the paper.
    #
    # Returns:
    # res - matrix whose first two rows are start- and end-points (respectively) of the detected intervals of significance

    n <- length(x)

    x.c <- matrix(x, n, deg + 1)

    for (i in 1:(deg + 1)) {
        x.c[, i] <- seq(from = 0, to = 1, length = n)^(i - 1)
    }

    if (is.null(thresh)) {
        if (is.null(alpha)) alpha <- 0.1
        wh <- get(paste("wiener.holder_", as.character(eps), sep = ""))
        thresh <- quantile(wh, 1 - alpha)
    }

    nsp_selfnorm(x, x.c, M, thresh, power, minsize, stage1, eps, c, overlap)
}


sim.max.holder <- function(n, N, eps, c = exp(1 + 2 * eps)) {

    # Simulate a sample of size N of values of the Holder-like norm of the Wiener process discretised with step 1/n.
    # See the "Example" in the description of the function "nsp_selfnorm".

    max.holder.sample <- rep(0, N)

    for (i in 1:N) {
        e <- rnorm(n)

        max.holder.sample[i] <- max.holder(e, eps, c)
    }

    max.holder.sample
}


draw_rects <- function(nsp.obj, yrange, density = NULL, col = NA) {

    # Draw intervals of significance, as shaded rectangular areas, on the current plot.
    # nsp.obj - quantity returned by one of the nsp_* functions.
    # yrange - vector of length two specifying the (lower, upper) vertical limit of the rectangles.
    # density - density of the shading; try using 10 or 20.
    # col - colour of the shading.

    d <- dim(nsp.obj)
    for (i in 1:d[2]) {
        rect(nsp.obj[1, i], yrange[1], nsp.obj[2, i], yrange[2], density = density, col = col)
    }
}


cpt.importance <- function(nsp.obj) {

    # Change-point prominence plot as described in Section 4 of the paper.
    # nsp.obj - quantity returned by one of the nsp_* functions.

    heights <- nsp.obj[2, ] - nsp.obj[1, ]
    h.ord <- order(heights)
    labels <- paste(as.character(round(nsp.obj[1, h.ord])), "-", as.character(round(nsp.obj[2, h.ord])), sep = "")
    barplot(heights[h.ord], names.arg = labels)
}



#######################################################################
### Internal functions -- not to be called directly by the user
#######################################################################


all.dyadic.scans.array <- function(x) {
    d <- dim(x)
    n <- d[1]

    if (n) {
        add.scales <- floor(logb(n, 2))
        shifts <- rep(0, add.scales + 1)
        res <- array(x, c(d[1], d[2], add.scales + 1))
        if (add.scales) {
            for (j in 1:add.scales) {
                res[1:(n - 2^j + 1), , (j + 1)] <- 2^(-1 / 2) * (res[1:(n - 2^j + 1), , j] + res[(2^(j - 1) + 1):(n - 2^j + 1 + 2^(j - 1)), , j])
                res[(n - 2^j + 2):(n), , (j + 1)] <- 0
                shifts[j + 1] <- 2^j - 1
            }
        }
    }
    else {
        res <- array(0, c(d[1], d[2], 0))
        shifts <- integer(0)
    }

    list(res = res, shifts = shifts)
}


iter_random_checks_scan_array <- function(ind, ads.array, M, thresh, stage1 = "narrowest", overlap = FALSE, buffer = 0) {
    s <- ind[1]
    e <- ind[2]
    n <- e - s + 1

    indices <- ((ads.array$shifts + 1) <= (n / 2))

    ads.array$res <- ads.array$res[s:e, , indices, drop = F]

    ads.array$shifts <- ads.array$shifts[indices]

    if (n > 1) {
        next.int <- random_checks_scan_2stage_array(c(1, n), ads.array, M, thresh, stage1)

        if (!is.na(next.int$selected.ind)) {
            if (!overlap) {
                if (next.int$selected.val[1, 1] - buffer >= 2) left <- iter_random_checks_scan_array(c(1, next.int$selected.val[1, 1] - buffer), ads.array, M, thresh, stage1, overlap, buffer) else left <- matrix(NA, 3, 0)
                if (n - next.int$selected.val[1, 2] - buffer >= 1) {
                    right <- iter_random_checks_scan_array(c(next.int$selected.val[1, 2] + buffer, n), ads.array, M, thresh, stage1, overlap, buffer)
                    if (dim(right)[2]) right <- right + c(rep(next.int$selected.val[1, 2] - 1 + buffer, 2), 0)
                }
                else {
                    right <- matrix(NA, 3, 0)
                }
            }

            else {
                if (floor(mean(next.int$selected.val[1, 1:2])) - buffer >= 2) left <- iter_random_checks_scan_array(c(1, floor(mean(next.int$selected.val[1, 1:2])) - buffer), ads.array, M, thresh, stage1, overlap, buffer) else left <- matrix(NA, 3, 0)
                if (n - floor(mean(next.int$selected.val[1, 1:2])) - buffer >= 2) {
                    right <- iter_random_checks_scan_array(c(floor(mean(next.int$selected.val[1, 1:2])) + 1 + buffer, n), ads.array, M, thresh, stage1, overlap, buffer)
                    if (dim(right)[2]) right <- right + c(rep(floor(mean(next.int$selected.val[1, 1:2])) + buffer, 2), 0)
                }
                else {
                    right <- matrix(NA, 3, 0)
                }
            }


            return(cbind(t(next.int$selected.val), left, right))
        }

        else {
            (return(matrix(NA, 3, 0)))
        }
    }

    else {
        (return(matrix(NA, 3, 0)))
    }
}


random_checks_scan_2stage_array <- function(ind, ads.array, M, thresh, stage1 = "narrowest") {
    s1 <- random_checks_scan_array(ind, ads.array, M, thresh, stage1)

    if (!is.na(s1$selected.ind)) {
        s <- s1$selected.val[1, 1] + ind[1] - 1
        e <- s1$selected.val[1, 2] + ind[1] - 1

        s2 <- random_checks_scan_array(c(s, e), ads.array, M, thresh)

        if (!is.na(s2$selected.ind)) {
            replacement <- s2$selected.val
            replacement[1, 1:2] <- replacement[1, 1:2] + s - ind[1]
            s1$res[s1$selected.ind, ] <- replacement
            s1$selected.val <- replacement
        }
    }

    s1
}


random_checks_scan_array <- function(ind, ads.array, M, thresh, criterion = "narrowest") {
    s <- ind[1]
    e <- ind[2]
    n <- e - s + 1

    if (n > 1) {
        indices <- ((ads.array$shifts + 1) <= (n / 2))

        ads.array$res <- ads.array$res[s:e, , indices, drop = F]

        ads.array$shifts <- ads.array$shifts[indices]

        M <- min(M, (n - 1) * n / 2)

        ind <- grid.intervals(n, M)

        M <- dim(ind)[2]

        res <- matrix(0, M, 3)

        res[, 1:2] <- t(ind)

        res[, 3] <- apply(ind, 2, check_interval_array, ads.array, thresh)

        filtered.res <- res[(res[, 3] > 0), , drop = F]

        d <- dim(filtered.res)

        if (d[1]) {
            if (criterion == "narrowest") {
                lnghts <- filtered.res[, 2] - filtered.res[, 1]
                min.indices <- which(lnghts == min(lnghts))
                selected.ind <- min.indices[which.max(filtered.res[min.indices, 3])]
            }

            else if (criterion == "largest") selected.ind <- which.max(filtered.res[, 3])

            selected.val <- filtered.res[selected.ind, , drop = F]
        }

        else {
            selected.ind <- NA
            selected.val <- matrix(0, 0, 3)
        }
    }

    else {
        filtered.res <- selected.val <- matrix(0, 0, 3)
        selected.ind <- NA
        M <- 0
    }


    list(res = filtered.res, selected.ind = selected.ind, selected.val = selected.val, M.eff = max(1, M))
}


all.intervals.flat <- function(n) {
    if (n == 2) {
        ind <- matrix(1:2, 2, 1)
    } else {
        M <- (n - 1) * n / 2
        ind <- matrix(0, 2, M)
        ind[1, ] <- rep(1:(n - 1), (n - 1):1)
        ind[2, ] <- 2:(M + 1) - rep(cumsum(c(0, (n - 2):1)), (n - 1):1)
    }
    ind
}


grid.intervals <- function(n, M) {
    if ((n == 2) || (M == 0)) {
        ind <- matrix(c(1, n), 2, 1)
    } else if (M >= (n - 1) * n / 2) {
        ind <- all.intervals.flat(n)
    } else {
        k <- 1
        while (k * (k - 1) / 2 < M) k <- k + 1
        ind2 <- all.intervals.flat(k)
        ind2.mx <- max(ind2)
        ind <- round((ind2 - 1) * ((n - 1) / (ind2.mx - 1)) + 1)
    }

    ind
}


check_interval_array <- function(ind, ads.array, thresh) {
    s <- ind[1]
    e <- ind[2]
    n <- e - s + 1

    indices <- ((ads.array$shifts + 1) <= (n / 2))

    ads.array$res <- ads.array$res[s:e, , indices, drop = F]

    ads.array$shifts <- ads.array$shifts[indices]

    dm <- dim(ads.array$res)

    f.con.rhs.core <- matrix(0, 0, 1 + 2 * (dm[2] - 1))

    scales <- length(ads.array$shifts)

    for (i in 1:scales) {
        f.con.rhs.current <- ads.array$res[1:(n - ads.const$shifts[i]), , i]
        f.con.rhs.current <- cbind(f.con.rhs.current, -f.con.rhs.current[, -1])

        f.con.rhs.core <- rbind(f.con.rhs.core, f.con.rhs.current)
    }

    f.con.rhs.core <- rbind(f.con.rhs.core, -f.con.rhs.core)

    f.obj <- c(1, rep(0, 2 * (dm[2] - 1)))
    f.rhs <- f.con.rhs.core[, 1]
    f.con <- f.con.rhs.core
    f.con[, 1] <- 1
    d <- dim(f.con.rhs.core)

    f.dir <- rep(">=", d[1])
    linf <- lp("min", f.obj, f.con, f.dir, f.rhs)$solution[1]
    linf.t <- linf * (linf > thresh)
    linf.t
}


lp_selfnorm <- function(ind, ads.array, selfnorm.array) {
    s <- ind[1]
    e <- ind[2]
    n <- e - s + 1

    indices <- ((ads.array$shifts + 1) <= (n / 2))

    ads.array$res <- ads.array$res[s:e, , indices, drop = F]

    ads.array$shifts <- ads.array$shifts[indices]

    dm <- dim(ads.array$res)

    f.con.rhs.core <- matrix(0, 0, 1 + 2 * (dm[2] - 1))

    scales <- length(ads.array$shifts)

    for (i in 1:scales) {
        f.con.rhs.current <- ads.array$res[1:(n - ads.const$shifts[i]), , i] / selfnorm.array[1:(n - ads.const$shifts[i]), i]
        f.con.rhs.current <- cbind(f.con.rhs.current, -f.con.rhs.current[, -1])

        f.con.rhs.core <- rbind(f.con.rhs.core, f.con.rhs.current)
    }

    f.con.rhs.core <- rbind(f.con.rhs.core, -f.con.rhs.core)

    f.obj <- c(1, rep(0, 2 * (dm[2] - 1)))
    f.rhs <- f.con.rhs.core[, 1]
    f.con <- f.con.rhs.core
    f.con[, 1] <- 1
    d <- dim(f.con.rhs.core)

    f.dir <- rep(">=", d[1])
    lp.sol <- lp("min", f.obj, f.con, f.dir, f.rhs)$solution
    lp.sol
}


create_selfnorm_array_Vn2est <- function(resid, Vn2est, eps, c = exp(1 + 2 * eps)) {
    m <- length(resid)

    zz <- all.dyadic.scans.array(matrix(resid^2, m, 1))
    zz$res <- zz$res[, , ]

    zz.norm <- all.dyadic.scans.array(matrix(1, m, 1))
    zz.norm$res <- zz.norm$res[, , ]

    (1 + eps) * sqrt(zz$res / zz.norm$res) * log(c * pmax(1, Vn2est / (zz$res * zz.norm$res)))^(1 / 2 + eps)
}


linreg_resid <- function(ind, ads.array) {
    s <- ind[1]
    e <- ind[2]

    lmmat <- ads.array$res[s:e, , 1]

    res <- as.numeric(lm(lmmat[, 1] ~ lmmat[, -1] - 1)$resid)

    if (sum(res^2) == 0) res <- (lmmat[, 1] - mean(lmmat[, 1]))

    if (sum(res^2) == 0) res <- lmmat[, 1]

    res
}


check_interval_array_selfnorm <- function(ind, ads.array, thresh, Vn2est, eps = 0.03, c = exp(1 + 2 * eps)) {
    resid <- linreg_resid(ind, ads.array)
    resid.sna <- create_selfnorm_array_Vn2est(resid, Vn2est, eps, c)
    a <- lp_selfnorm(ind, ads.array, resid.sna)
    sol <- a[1] * (a[1] > thresh)
    sol
}


random_checks_scan_array_selfnorm <- function(ind, ads.array, M, thresh, Vn2est, criterion = "narrowest", eps = 0.03, c = exp(1 + 2 * eps)) {
    s <- ind[1]
    e <- ind[2]
    n <- e - s + 1

    if (n > 1) {
        indices <- ((ads.array$shifts + 1) <= (n / 2))

        ads.array$res <- ads.array$res[s:e, , indices, drop = F]

        ads.array$shifts <- ads.array$shifts[indices]

        M <- min(M, (n - 1) * n / 2)

        ind <- grid.intervals(n, M)

        M <- dim(ind)[2]

        res <- matrix(0, M, 3)

        res[, 1:2] <- t(ind)

        res[, 3] <- apply(ind, 2, check_interval_array_selfnorm, ads.array, thresh, Vn2est, eps, c)

        filtered.res <- res[(res[, 3] > 0), , drop = F]

        d <- dim(filtered.res)

        if (d[1]) {
            if (criterion == "narrowest") {
                lnghts <- filtered.res[, 2] - filtered.res[, 1]
                min.indices <- which(lnghts == min(lnghts))
                selected.ind <- min.indices[which.max(filtered.res[min.indices, 3])]
            }

            else if (criterion == "largest") selected.ind <- which.max(filtered.res[, 3])

            selected.val <- filtered.res[selected.ind, , drop = F]
        }

        else {
            selected.ind <- NA
            selected.val <- matrix(0, 0, 3)
        }
    }

    else {
        filtered.res <- selected.val <- matrix(0, 0, 3)
        selected.ind <- NA
        M <- 0
    }

    list(res = filtered.res, selected.ind = selected.ind, selected.val = selected.val, M.eff = max(1, M))
}


random_checks_scan_2stage_array_selfnorm <- rcs2sas <- function(ind, ads.array, M, thresh, Vn2est, stage1 = "narrowest", eps = 0.03, c = exp(1 + 2 * eps)) {
    s1 <- random_checks_scan_array_selfnorm(ind, ads.array, M, thresh, Vn2est, stage1, eps, c)

    if (!is.na(s1$selected.ind)) {
        s <- s1$selected.val[1, 1] + ind[1] - 1
        e <- s1$selected.val[1, 2] + ind[1] - 1

        s2 <- random_checks_scan_array_selfnorm(c(s, e), ads.array, M, thresh, Vn2est, "narrowest", eps, c)

        if (!is.na(s2$selected.ind)) {
            replacement <- s2$selected.val
            replacement[1, 1:2] <- replacement[1, 1:2] + s - ind[1]
            s1$res[s1$selected.ind, ] <- replacement
            s1$selected.val <- replacement
        }
    }

    s1
}


ircs2sas <- function(ind, ads.array, M, thresh, Vn2est, stage1 = "narrowest", eps = 0.03, c = exp(1 + 2 * eps), overlap = FALSE) {
    s <- ind[1]
    e <- ind[2]
    n <- e - s + 1

    indices <- ((ads.array$shifts + 1) <= (n / 2))

    ads.array$res <- ads.array$res[s:e, , indices, drop = F]

    ads.array$shifts <- ads.array$shifts[indices]

    if (n > 1) {
        next.int <- rcs2sas(c(1, n), ads.array, M, thresh, Vn2est, stage1, eps, c)

        if (!is.na(next.int$selected.ind)) {
            if (!overlap) {
                if (next.int$selected.val[1, 1] >= 2) left <- ircs2sas(c(1, next.int$selected.val[1, 1]), ads.array, M, thresh, Vn2est, stage1, eps, c, overlap) else left <- matrix(NA, 3, 0)
                if (n - next.int$selected.val[1, 2] >= 1) {
                    right <- ircs2sas(c(next.int$selected.val[1, 2], n), ads.array, M, thresh, Vn2est, stage1, eps, c, overlap)
                    if (dim(right)[2]) right <- right + c(rep(next.int$selected.val[1, 2] - 1, 2), 0)
                }
                else {
                    right <- matrix(NA, 3, 0)
                }
            }

            else {
                if (floor(mean(next.int$selected.val[1, 1:2])) >= 2) left <- ircs2sas(c(1, floor(mean(next.int$selected.val[1, 1:2]))), ads.array, M, thresh, Vn2est, stage1, eps, c, overlap) else left <- matrix(NA, 3, 0)
                if (n - floor(mean(next.int$selected.val[1, 1:2])) >= 2) {
                    right <- ircs2sas(c(floor(mean(next.int$selected.val[1, 1:2])) + 1, n), ads.array, M, thresh, Vn2est, stage1, eps, c, overlap)
                    if (dim(right)[2]) right <- right + c(rep(floor(mean(next.int$selected.val[1, 1:2])), 2), 0)
                }
                else {
                    right <- matrix(NA, 3, 0)
                }
            }


            return(cbind(t(next.int$selected.val), left, right))
        }

        else {
            (return(matrix(NA, 3, 0)))
        }
    }

    else {
        (return(matrix(NA, 3, 0)))
    }
}


max.holder <- function(e, eps, c = exp(1 + 2 * eps)) {
    n <- length(e)

    eps.cum <- c(0, cumsum(e))

    max.stat <- 0

    for (i in 0:(n - 1)) {
        for (j in (i + 1):n) {
            scan.stat <- abs(eps.cum[j + 1] - eps.cum[i + 1]) / sqrt(j - i) / log(c * n / (j - i))^(1 / 2 + eps)

            if (scan.stat > max.stat) max.stat <- scan.stat
        }
    }

    max.stat
}


est_var <- function(y, x, power = 1 / 2, min.size = 20, estVn2 = FALSE) {
    n <- length(y)
    w.size <- min(n, max(round(n^power), min.size))

    how.many <- n - w.size + 1

    res <- rep(0, how.many)

    for (i in 1:how.many) {
        resp <- y[i:(i + w.size - 1)]
        covs <- x[i:(i + w.size - 1), ]

        res[i] <- summary(lm(resp ~ covs))$sigma
    }

    if (estVn2) {
        est <- n / (n - w.size + 1) * sum(res^2)
    } else {
        est <- median(res)
    }

    est
}


thresh.kab <- function(n, alpha = 0.1, method = "asymp") {
    an <- sqrt(2 * log(n)) + (1 / 2 * log(log(n)) + log(0.8197466 / 2 / sqrt(pi))) / sqrt(2 * log(n))

    bn <- 1 / sqrt(2 * log(n))

    if (method == "bound") {
        beta <- alpha / 2
    } else if (method == "asymp") beta <- 1 - sqrt(1 - alpha)

    an + bn * log(1 / log(1 / (1 - beta)))
}