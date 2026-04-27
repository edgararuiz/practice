# Parsnip keras3 vs RLN: Approach Comparison

## Architecture

| | parsnip `keras3.R` | RLN (`rln_callback.R`) |
|---|---|---|
| Layers | One hidden layer only | Geometric series of layers (depth is a hyperparameter) |
| Regularization type | Static L2 weight decay **or** dropout (your choice, not both) | Per-weight adaptive L1/L2 — each weight learns its own regularization coefficient |
| How regularization is set | Fixed scalar `penalty` baked into `regularizer_l2()` at build time | `lambdas` matrix updated every batch via gradient descent |

## Design Pattern

- **parsnip's version** is a self-contained training function (`keras3_mlp(x, y, ...)`). It builds, compiles, and fits the model in one call, returning a fitted model. It is a tidymodels engine — stateless from the caller's perspective.
- **The RLN version** is a Keras callback (`RLNCallback`). It attaches to any model and modifies weight updates during training. The model itself is built separately; RLN only intercepts `on_batch_end`.

## Optimizer

- parsnip: Adam (default), overridable via `...`
- RLN tutorial: RMSprop — the paper found this worked better with the RLN update, since RMSprop's adaptive learning rates interact differently with the manual weight edits than Adam does

## Scope

- parsnip's version is deliberately simple — single hidden layer, binary/multiclass/regression handled, designed to slot into tidymodels workflows with `tune()`-able hyperparameters.
- RLN is a research technique meant to replace (or augment) any regularization scheme on any architecture; it is not tied to a fixed structure.
