"""
RLN example using the original Python Keras implementation logic,
adapted to modern Keras 3 / TF 2.x APIs.
Uses the same Boston Housing data, architecture, and hyperparameters as example.R.
"""
# /// script
# dependencies = [
#   "tensorflow",
#   "numpy",
#   "pandas",
# ]
# ///

import os
os.environ["TF_CPP_MIN_LOG_LEVEL"] = "3"

import numpy as np
import pandas as pd
import tensorflow as tf
from tensorflow import keras

# ── Modernised RLNCallback (logic identical to Keras_implementation.py) ───────
# K.transpose / K.eval / K.set_value replaced with Keras 3 / TF 2 equivalents.

class RLNCallback(keras.callbacks.Callback):
    def __init__(self, layer, norm=1, avg_reg=-7.5, learning_rate=6e5):
        super().__init__()
        self._kernel = layer.kernel
        self._prev_weights = self._weights = self._prev_regularization = None
        self._avg_reg = avg_reg
        # kernel shape is [in, out]; transposed shape is [out, in]
        shape = list(self._kernel.shape[::-1])
        self._lambdas = pd.DataFrame(np.ones(shape) * self._avg_reg)
        self._lr = learning_rate
        assert norm in [1, 2]
        self.norm = norm

    def on_train_begin(self, logs=None):
        self._update_values()

    def on_batch_end(self, batch, logs=None):
        self._prev_weights = self._weights
        self._update_values()
        gradients = self._weights - self._prev_weights

        if self.norm == 1:
            norms_derivative = np.sign(self._weights)
        else:
            norms_derivative = self._weights * 2

        if self._prev_regularization is not None:
            lambda_gradients = gradients.multiply(self._prev_regularization)
            self._lambdas -= self._lr * lambda_gradients
            translation = self._avg_reg - self._lambdas.mean().mean()
            self._lambdas += translation

        max_lambda_values = np.log(
            np.abs(self._weights / norms_derivative)
        ).replace([np.inf, -np.inf], np.nan).fillna(np.inf)
        self._lambdas = self._lambdas.clip(upper=max_lambda_values)

        regularization = norms_derivative.multiply(np.exp(self._lambdas))
        self._weights -= regularization
        self._kernel.assign(self._weights.values.T)   # assign back [in, out]
        self._prev_regularization = regularization

    def _update_values(self):
        self._weights = pd.DataFrame(self._kernel.numpy().T)  # store as [out, in]


# ── Reproducibility ───────────────────────────────────────────────────────────
tf.random.set_seed(42)
np.random.seed(42)

# ── Data ──────────────────────────────────────────────────────────────────────
(x_train, y_train), (x_test, y_test) = keras.datasets.boston_housing.load_data(
    seed=42
)

col_means = x_train.mean(axis=0)
col_sds   = x_train.std(axis=0, ddof=1)   # ddof=1 matches R's sd()
x_train   = (x_train - col_means) / col_sds
x_test    = (x_test  - col_means) / col_sds

# ── Model ─────────────────────────────────────────────────────────────────────
inputs = keras.Input(shape=(x_train.shape[1],))
x = keras.layers.Dense(64, activation="relu",
                        kernel_initializer="glorot_normal")(inputs)
outputs = keras.layers.Dense(1, activation="linear")(x)
model = keras.Model(inputs, outputs)

model.compile(
    optimizer=keras.optimizers.RMSprop(learning_rate=1e-3, rho=0.9, epsilon=1e-7),
    loss="mse",
)

# ── RLN callback on first Dense layer ────────────────────────────────────────
rln = RLNCallback(layer=model.layers[1], norm=1, avg_reg=-7.5, learning_rate=6e5)

# ── Train ─────────────────────────────────────────────────────────────────────
model.fit(
    x_train, y_train,
    epochs=100, batch_size=10, validation_split=0.2,
    callbacks=[rln], verbose=0,
)

# ── Evaluate ──────────────────────────────────────────────────────────────────
preds = model.predict(x_test, verbose=0).flatten()

rmse = np.sqrt(np.mean((y_test - preds) ** 2))
rsq  = 1 - np.sum((y_test - preds) ** 2) / np.sum((y_test - y_test.mean()) ** 2)
mae  = np.mean(np.abs(y_test - preds))

print(f"\n=== Python (original Keras implementation, modernised API) ===")
print(f"RMSE : {rmse:.3f}")
print(f"R²   : {rsq:.3f}")
print(f"MAE  : {mae:.3f}")
print(f"Pred range: [{preds.min():.1f}, {preds.max():.1f}]")
