# `rln_mlp()` — Implementation Notes

## Overview

`rln_mlp()` is a self-contained training function that fits a single-hidden-layer
MLP using Regularization Learning (RLN). It mirrors the interface of parsnip's
`keras3_mlp()` so the two can be used interchangeably, with RLN replacing the
fixed `penalty` parameter.

## Parameters

| Parameter | Default | Description |
|---|---|---|
| `x` | — | Numeric predictor matrix |
| `y` | — | Outcome: numeric vector (regression), factor (classification) |
| `hidden_units` | `5` | Number of units in the single hidden layer |
| `norm` | `1` | Regularization norm: `1` = L1, `2` = L2 |
| `avg_reg` | `-7.5` | Target mean of log-scale lambda coefficients (Theta, Θ) |
| `learning_rate` | `6e5` | Step size for lambda updates (nu, ν) |
| `epochs` | `20` | Number of training epochs |
| `activation` | `"relu"` | Hidden layer activation function |
| `seed` | random | Random seed passed to `keras3::set_random_seed()` |
| `checkpoint_dir` | `NULL` | Directory for checkpointing — see section below |
| `...` | — | Extra args routed to `compile()` or `fit()` |

## Model Structure

```
Input (ncol(x))
  └── Dense(hidden_units, activation, glorot_normal) ← RLN applied here
        └── Dense(output_units, output_activation)
```

Output layer and loss are selected automatically based on `y`:

| Outcome type | Output activation | Loss |
|---|---|---|
| Regression | `linear` | `mse` |
| Binary factor | `sigmoid` | `binary_crossentropy` |
| Multiclass factor | `softmax` | `categorical_crossentropy` |

Default optimizer is **RMSprop**, as recommended by the RLN paper. This can be
overridden via `...` (e.g. `optimizer = "adam"`).

## How RLN Works Inside `rln_mlp()`

`rln_mlp()` builds and compiles the model normally, then attaches `RLNCallback`
to the hidden layer before calling `fit()`. The callback intercepts
`on_batch_end` each step and applies a second weight update on top of the
optimizer's own step:

1. **Read** the current kernel weights from the layer
2. **Compute** ΔW = W_current − W_prev (weight change from the optimizer step)
3. **Update** λ ← λ − ν · ΔW ⊙ R_prev (gradient step on log-scale coefficients)
4. **Project** λ so that mean(λ) = Θ (simplex constraint)
5. **Clip** λ ≤ log|W| (prevents regularization from flipping weight signs)
6. **Apply** W ← W − ∇norm(W) ⊙ exp(λ) (per-weight regularization)

The key difference from fixed regularization: `exp(λ)` is not a global scalar
— it is a matrix the same shape as the kernel, and every entry evolves
independently throughout training.

## Differences from `keras3_mlp()`

| | `keras3_mlp()` | `rln_mlp()` |
|---|---|---|
| Regularization | Fixed `penalty` scalar via `regularizer_l2()` | Per-weight adaptive λ via `RLNCallback` |
| Regularization timing | Baked into the forward pass / loss | Applied as a post-optimizer weight correction each batch |
| Default optimizer | Adam | RMSprop |
| Extra state | None | `lambdas` matrix lives in the callback |
| `checkpoint_dir` | Not supported | Saves both weights and lambda state |

## Return Value

Returns the fitted Keras model with two additional fields attached:

- `model$history` — the `fit()` history object (plot with `plot(model$history)`)
- `model$y_names` — column names of the outcome matrix (used for prediction)

## Checkpointing

When `checkpoint_dir` is supplied, two files are written after each epoch:

```
checkpoint_dir/
  model_epoch_001.keras      # Keras model weights
  rln_state_epoch_001.rds    # Lambda matrix + prev_regularization
  model_epoch_002.keras
  rln_state_epoch_002.rds
  ...
```

The epoch number in both filenames is always identical, ensuring model weights
and lambda state are never mismatched on restore.

On the next call to `rln_mlp()` with the same `checkpoint_dir`, `RLNCallback`
scans for `rln_state_epoch_*.rds` files on `on_train_begin` and restores from
the highest-numbered one automatically. To start fresh, clear or change the
directory.

### Caveats

- Stale files from a previous run will be picked up automatically. Clear the
  directory if you want a clean start.
- The lambda state file and model checkpoint must always be used as a pair.
  Do not mix files from different epoch numbers.
