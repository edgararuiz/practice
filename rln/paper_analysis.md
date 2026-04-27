# RLN Paper vs Implementation Analysis

Reference: Shavitt & Segal, "Regularization Learning Networks: Deep Learning for
Tabular Datasets", NeurIPS 2018. https://arxiv.org/abs/1805.06440

## The Paper's Algorithm

The regularized loss assigns a separate coefficient to every weight:

```
L†(Z, W, Λ) = L(Z, W) + Σᵢ exp(λᵢ) · ‖wᵢ‖
```

The SGD weight update at batch t is:

```
w_{t+1,i} = w_{t,i} - η · (g_{t,i} + r_{t,i})          (1)

g_{t,i} = ∂L(Z_t, W_t) / ∂w_{t,i}                       (2)

r_{t,i} = exp(λ_{t,i}) · ∂‖w_{t,i}‖ / ∂w_{t,i}          (3)
```

From Theorem 1, the gradient of the Counterfactual Loss with respect to λ is
`∂L_CF/∂λ_{t,i} = -η · g_{t+1,i} · r_{t,i}`, giving the lambda update:

```
λ̃_{t+1,i} = λ_{t,i} + ν · η · g_{t+1,i} · r_{t,i}      (5)

λ_{t+1,i} = λ̃_{t+1,i} + (θ - Σⱼ λ̃_{t+1,j} / n)        (6)
```

where θ is the target mean of all lambdas and ν is the lambda learning rate.

---

## Checking Each Component Against `rln_callback.R`

### ✅ Lambda initialisation

**Paper:** implies starting every λ at θ.  
**Code:** `matrix(avg_reg, nrow = ..., ncol = ...)` — correct.

---

### ✅ Regularization term r_{t,i} (eq. 3)

**Paper:**
- L1: `r_{t,i} = exp(λ_{t,i}) · sign(w_{t,i})`
- L2: `r_{t,i} = exp(λ_{t,i}) · 2w_{t,i}`

**Code:**
```r
norms_derivative <- sign(private$weights)        # L1
norms_derivative <- private$weights * 2          # L2
regularization   <- norms_derivative * exp(private$lambdas)
```
Correct.

---

### ✅ Weight update

**Paper:** `w_{t+1,i} = w_{t,i} - η · (g_{t,i} + r_{t,i})`  
**Code:** `new_weights <- private$weights - regularization` (r applied post-optimizer — see approximation note below).  
Correct in effect.

---

### ✅ Projection (eq. 6)

**Paper:** add `(θ - mean(λ̃))` to every entry so that `mean(λ) = θ`.  
**Code:**
```r
translation     <- private$avg_reg - mean(private$lambdas)
private$lambdas <- private$lambdas + translation
```
Correct.

---

### ✅ Clipping

Not in the paper. Added in the Python reference implementation as a numerical
stability measure. Ensures `exp(λ)` never exceeds `|w|`, preventing the
regularization term from flipping a weight's sign:

```r
max_lambdas <- log(abs(private$weights / norms_derivative))
max_lambdas[!is.finite(max_lambdas)] <- Inf
private$lambdas <- pmin(private$lambdas, max_lambdas)
```
Faithfully replicated from Python.

---

### ⚠️ Lambda update (eq. 5) — intentional approximation

**Paper:** `λ_{t+1,i} = λ_{t,i} + ν · η · g_{t+1,i} · r_{t,i}`

This requires `g_{t+1,i}` — the loss gradient from the *next* batch — which is
not available at `on_batch_end` without an extra forward/backward pass.

The Python reference code (and our R code) approximates this using weight
deltas instead:

```r
gradients        <- private$weights - private$prev_weights  # ≈ -η · g_t
lambda_gradients <- gradients * private$prev_regularization # ≈ -η · g_t · R_{t-1}
private$lambdas  <- private$lambdas - private$lr * lambda_gradients
# result: λ + lr · η · g_t · R_{t-1}
```

**vs paper:** `λ + ν · η · g_{t+1} · r_t`

Two differences, both by design:

| | Paper | Implementation |
|---|---|---|
| Gradient | `g_{t+1}` (next batch) | `g_t` (current batch, via ΔW) |
| Regularization | `r_t` (current batch) | `R_{t-1}` (previous batch) |

Both are one batch behind. This is a deliberate efficiency trade-off in the
authors' own Python code — it avoids a redundant forward/backward pass. For
smooth optimisation the one-batch offset has negligible practical impact.

---

### ⚠️ Regularization applied outside the optimizer

**Paper:** derives the algorithm assuming regularization is part of the SGD
step: `w_{t+1} = w_t - η(g + r)`.

**Implementation:** the optimizer (RMSprop) handles only `g`; RLN subtracts `r`
separately in `on_batch_end`. For vanilla SGD these are equivalent. For
RMSprop the adaptive scaling applies only to `g`, not `r`.

The paper acknowledges this in footnote 3: *"We assume vanilla SGD is used in
this analysis for brevity, but the analysis holds for any derivative-based
optimization method."* This deviation is present in the authors' own Python
code and is an accepted practical simplification.

---

## Summary

| Component | Status | Notes |
|---|---|---|
| Lambda initialisation | ✅ Correct | Initialised at θ |
| `r_{t,i}` definition (L1 and L2) | ✅ Correct | sign(w) and 2w forms |
| Weight update | ✅ Correct | Post-optimizer subtraction |
| Projection (eq. 6) | ✅ Correct | mean(λ) = θ enforced |
| Clipping | ✅ Correct | Not in paper; faithfully replicated from Python |
| Lambda update (eq. 5) | ⚠️ Approximation | One-batch offset in gradient and regularization — intentional, matches Python reference |
| Optimizer separation | ⚠️ Approximation | RMSprop scales only loss gradient, not regularization — intentional, matches Python reference |

The R implementation is a faithful replication of the Python reference code.
The two approximations are both present in the authors' own implementation and
are intentional design choices for computational efficiency.
