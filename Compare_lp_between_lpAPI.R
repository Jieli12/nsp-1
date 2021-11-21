
library(lpSolve)
#
# Set up problem: maximize
#   x1 + 9 x2 +   x3 subject to
#   x1 + 2 x2 + 3 x3  <= 9
# 3 x1 + 2 x2 + 2 x3 <= 15
#
f.obj <- c(1, 9, 1)
f.con <- matrix(c(1, 2, 3, 3, 2, 2), nrow = 2, byrow = TRUE)
f.dir <- c("<=", "<=")
f.rhs <- c(9, 15)
#
# Now run.
#
lp("max", f.obj, f.con, f.dir, f.rhs)$s

library(lpSolveAPI)
my.lp <- make.lp(2, 3)
set.column(my.lp, 1, c(1, 3))
set.column(my.lp, 2, c(2, 2))
set.column(my.lp, 3, c(3, 2))
set.objfn(my.lp, c(-1, -9, -1))
set.constr.type(my.lp, rep("<=", 2))
set.rhs(my.lp, c(9, 15))
solve(my.lp)
get.variables(my.lp)

library(microbenchmark)
microbenchmark(
    lp("max", f.obj, f.con, f.dir, f.rhs),
    solve(my.lp)
)
