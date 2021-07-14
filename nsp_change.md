---
title: 'Changes in R package: nsp'
author: "Jie Li"
date: "2021-07-012"
# bookdown::pdf_document2: default
header-includes:
    - \usepackage{amsmath}
    - \numberwithin{equation}{section}
output:
  bookdown::html_document2:
    toc: yes
    toc_depth: 2
    number_sections: yes
    code_folding: show
    keep_md: yes
  # pdf_document:
  #   toc: yes
  #   toc_depth: '2'
  #   number_sections: yes
  # bookdown::pdf_document2:
bibliography: nsp.bib
link-citations: yes
linkcolor: blue
---

# Introduction
This ia an **R** package **nsp** for CRAN based on the open source software **nsp** in [GitHub ( https://github.com/pfryz/nsp)](https://github.com/pfryz/nsp).

# My contributions

* re-organize the structure of **nsp** package.
* format some functions following the suggestions of **R** package **lintr**.
* generate **R** Documents for all functions and datasets using **R** package **roxygen2**.
* insert references with Bib \( \TeX \)  style and show  \( \LaTeX \)  math symbols correctly.
* delete the argument *c = exp(1 + 2 \* eps)* and put it in the function body.
* rewrite the functions *max_holder()* and *sim_max_holder()* using package **Rcpp** which can boost the speed of computation significantly, see the example below.

# Highlight the changes

## grid_intervals_sorted()

Compute the \(k\) value directly, see the following code:

```r
k <- ceiling((1 + sqrt(1 + 8 * M)) / 2)
# k <- 1
# while (k * (k - 1) / 2 < M) {
#     k <- k + 1
# }
```

## linreg_resid()

```r
# The code in NSP_for_Github_v5.R
if (sum(res^2) == 0) res <- (lmmat[, 1] - mean(lmmat[, 1]))

if (sum(res^2) == 0) res <- lmmat[, 1]
# my version
if (sum(res^2) == 0) {
	res <- lmmat[, 1]
}
```
I commented the first *if* clause as I believes that *res* is only determined by the last *if* clause when *sum(res^2) == 0* holds.

## max_holder() and sim_max_holder()
I used C++ to rewrite these two functions. The motivation is to boost the computation of threshold value so that one can obtain it faster when user specifies the *eps* except the default 0.03 and 0.1. In **nsp** package, these two function are named with suffix "_cpp". See the comparison below.

```r
# need nsp installed in local computer
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
N <- n
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
```
The results:

```r
[1] 0
[1] 2.220446e-16
151.939 sec elapsed
149.806 sec elapsed
17.733 sec elapsed
[1] 0
[1] 7.070299e-16

```
The errors of two cpp functions are at the level of \( 10^{-16} \) and sim_max_holder_cpp() is almost 9x faster than the sim_max_holder(). Furthermore, I also compared the performance of max_holder_cpp() and max_holder().

```r
library(microbenchmark)
microbenchmark(
	max_holder(e, eps),
	nsp::max_holder_cpp(e, eps)
)
```

```r
	Unit: milliseconds
						expr       min        lq      mean    median        uq       max neval
		  max_holder(e, eps) 130.05202 133.39607 143.17820 135.35732 142.19367 204.54939   100
 nsp::max_holder_cpp(e, eps)  14.88209  15.41594  16.30718  15.62079  16.03212  21.05771   100
```
# Potential issues and suggestions

## thresh_kab()
I have understood that the method "asymp" is for the Equation (9) in @fryzlewiczNarrowestSignificancePursuit2021. For the method "bound", my understanding is "one-side" for the Theorem 2.2 in @fryzlewiczNarrowestSignificancePursuit2021 or Theorem 1.3 in @kabluchkoExtremeValueAnalysisStandardized2008. So I guess that the "beta" for "bound" should be


```r
if (method == "bound") {
	beta <- alpha # delete "/ 2"
}
```
## Rewrite nsp_poly_selfnorm()

Firstly, I compared the user specified \( \epsilon =0.05\), see the code below.


```r
# copying the code snippet from NSP_simulations_and_data_examples_v3.R
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
set.seed(1)
wt0 <- sim_max_holder(1000,1000, eps)
thresh0 <- quantile(wt0, 1 - alpha)
x.rt.hard.sn_init0 <- nsp_poly_selfnorm(x.rt.hard,thresh = thresh0, alpha = alpha, eps = eps)
x.rt.hard.sn_init0
toc()

# tictoc for thresh computation (c++)
tic()
set.seed(1)
wt1 <- nsp::sim_max_holder_cpp(1000,1000, eps)
thresh1 <- quantile(wt1, 1 - alpha)
x.rt.hard.sn_init1 <- nsp_poly_selfnorm(x.rt.hard,thresh = thresh1, alpha = alpha, eps = eps)
x.rt.hard.sn_init1
toc()
```
The results:

```r
> x.rt.hard.sn_init0
$intervals
  starts ends   values
1    134  261 2.301419
2    336  464 2.264435
3    509  681 2.334271

$threshold.used
     90%
2.219023

> toc()
162.523 sec elapsed
x.rt.hard.sn_init1
$intervals
  starts ends   values
1    134  261 2.301419
2    336  464 2.264435
3    509  681 2.334271

$threshold.used
     90%
2.219023

> toc()
30.76 sec elapsed
```
The results shows the threshold values computed by *sim_max_holder* and *nsp::sim_max_holder_cpp* are the same. So I plan to rewrite the *nsp_poly_selfnorm()* as

```r
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
```

## User specified design matrix
The design matrix in functions nsp_poly_selfnorm() and nsp_poly() is generated by default using the code snippet

```r
for (i in 1:(deg + 1)) {
    x.c[, i] <- seq(from = 0, to = 1, length = n)^(i - 1)
}
```
If \(x\) is rescaled in the interval \( [0,1] \), the above code is OK. My suggestion is to add argument *x.c = NULL* in function so that users can specify the design matrix. If users do not off the design matrix, then use the above code to generate it.

**Note:** all the issues and suggestions in this section are not shown in the new **nsp** package. I only add **# TODO** tag to indicate them. Therefore, the **nsp** package is currently under development.


# References
