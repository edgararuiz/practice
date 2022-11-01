library(caret)
library(tidymodels)
library(discrim)
library(doMC)

# ------------------------------------------------------------------------------

tidymodels_prefer()
theme_set(theme_bw())
options(pillar.advice = FALSE, pillar.min_title_chars = Inf)
registerDoMC(cores = parallel::detectCores())
bins <- seq(0, 1, length.out = 39)
# ------------------------------------------------------------------------------

set.seed(661)
tr <- sim_classification(1000)
te <- sim_classification(1000)
rs <- vfold_cv(tr)

show_hists <- function(x) {
  x %>%
    ggplot(aes(x = .pred_class_1, fill = class)) +
    geom_histogram(
      breaks = bins,
      position = "identity",
      col = "white",
      alpha = 1 / 2
    )
}

# ------------------------------------------------------------------------------
# Random forest

rf_spec <- rand_forest() %>% set_mode("classification")

set.seed(3352)
rf_fit <- rf_spec %>% fit(class ~ ., data = tr)
set.seed(4234)
rf_rs <-
  rf_spec %>%
  fit_resamples(class ~ ., rs, control = control_resamples(save_pred = TRUE))
rf_tr_pred <- augment(rf_fit, tr) %>%
  select(class, .pred_class_1, .pred_class_2) %>%
  mutate(data = "re-prediction", model = "random forest")
rf_tr_holdout <- collect_predictions(rf_rs) %>%
  mutate(data = "holdout", model = "random forest")
rf_te_pred <- augment(rf_fit, te) %>%
  select(class, .pred_class_1, .pred_class_2)





# ------------------------------------------------------------------------------
# Quadratic discriminant analysis

qda_spec <- discrim_quad()

set.seed(3352)
qda_fit <- qda_spec %>% fit(class ~ ., data = tr)
set.seed(4234)
qda_rs <-
  qda_spec %>%
  fit_resamples(class ~ ., rs, control = control_resamples(save_pred = TRUE))
qda_tr_pred <- augment(qda_fit, tr) %>%
  select(class, .pred_class_1, .pred_class_2) %>%
  mutate(data = "re-prediction", model = "QDA")
qda_tr_holdout <- collect_predictions(qda_rs) %>%
  mutate(data = "holdout", model = "QDA")
qda_te_pred <- augment(qda_fit, te) %>%
  select(class, .pred_class_1, .pred_class_2)


# ------------------------------------------------------------------------------
# K-nearest neighbors

knn_spec <-
  nearest_neighbor(neighbors = 10, weight_func = "triangular") %>%
  set_mode("classification")

knn_wflow <-
  norm_rec %>%
  workflow(knn_spec)

set.seed(9878)
knn_fit <- knn_wflow %>% fit(data = tr)
set.seed(534)
knn_rs <-
  knn_wflow %>%
  fit_resamples(rs, control = control_resamples(save_pred = TRUE))
knn_tr_pred <- augment(knn_fit, tr) %>%
  select(class, .pred_class_1, .pred_class_2) %>%
  mutate(data = "re-prediction", model = "10-NN")
knn_tr_holdout <- collect_predictions(knn_rs) %>%
  mutate(data = "holdout", model = "10-NN")
knn_te_pred <- augment(knn_fit, te) %>%
  select(class, .pred_class_1, .pred_class_2)

# ------------------------------------------------------------------------------

caret::calibration(class ~ .pred_class_1, data = knn_tr_pred) %>% plot()
caret::calibration(class ~ .pred_class_1, data = knn_tr_holdout) %>% plot()

caret::calibration(class ~ .pred_class_1, data = qda_tr_pred) %>% plot()
caret::calibration(class ~ .pred_class_1, data = qda_tr_holdout) %>% plot()

caret::calibration(class ~ .pred_class_1, data = rf_tr_pred) %>% plot()
caret::calibration(class ~ .pred_class_1, data = rf_tr_holdout) %>% plot()


all_training_pred <-
  bind_rows(
  knn_tr_pred %>% select(data, model, class, .pred_class_1),
  knn_tr_holdout %>% select(data, model, class, .pred_class_1),
  rf_tr_pred %>% select(data, model, class, .pred_class_1),
  rf_tr_holdout %>% select(data, model, class, .pred_class_1),
  qda_tr_pred %>% select(data, model, class, .pred_class_1),
  qda_tr_holdout %>% select(data, model, class, .pred_class_1)
)

all_training_pred %>%
  ggplot(aes(x = .pred_class_1, fill = class)) +
  geom_histogram(
    breaks = bins,
    position = "identity",
    col = "white",
    alpha = 1 / 2
  ) +
  facet_grid(model ~ data) +
  theme(legend.position = "top")

# ------------------------------------------------------------------------------

lp_ish <- function(x, eps = 0.0005) {
  x <- ifelse(x < eps, eps, x)
  x <- ifelse(x > 1 - eps, 1 - eps, x)
  binomial()$linkfun(x)
}

all_training_pred %>%
  mutate(lp = lp_ish(.pred_class_1)) %>%
  ggplot(aes(x = lp, fill = class)) +
  geom_histogram(
    position = "identity",
    col = "white",
    alpha = 1 / 2
  ) +
  facet_grid(model ~ data) +
  theme(legend.position = "top")

all_training_pred %>%
  mutate(lp = lp_ish(.pred_class_1)) %>%
  ggplot(aes(x = .pred_class_1, col = class)) +
  geom_line(stat = "density") +
  facet_grid(model ~ data) +
  theme(legend.position = "top")


# ------------------------------------------------------------------------------

y_table <- table(tr$class)
platt_correction <- y_table
platt_correction[1] <- 1 - (1 / (y_table[1] + 2))
platt_correction[2] <-     (1 / (y_table[1] + 2))

rf_tr_platt <-
  rf_tr_holdout %>%
  mutate(class_p = ifelse(class == "class_1", platt_correction[2], platt_correction[1]))

# produces a warning
glm(class_p ~ .pred_class_1, data = rf_tr_platt, family = "binomial")


rf_tr_holdout %>% 
  arrange(.pred_class_1) %>% 
  mutate(
    pc1 = cummean(.pred_class_1),
    pc1_pred = ifelse(class == "class_1", 1, 0),
    pc1_tot = cummean(pc1_pred)
    ) %>% 
  select(pc1, pc1_tot) %>% 
  arrange(-pc1) %>% 
  ggplot() +
  geom_line(aes(pc1_tot, pc1)) +
  geom_line(aes(pc1_tot, pc1_tot), color = "red", linetype = 2)



rf_tr_holdout %>% 
  arrange(.pred_class_1) %>% 
  mutate(
    pc1 = cummean(.pred_class_1),
    pc1_pred = ifelse(class == "class_1", 1, 0),
    pc1_tot = cummean(pc1_pred)
  ) %>% 
  select(pc1, pc1_tot, pc1_pred) %>% 
  arrange(pc1) %>% 
  View()

rf_tr_holdout %>% 
  arrange(.pred_class_1, desc(class)) %>% 
  mutate(
    pc1 = cumsum(.pred_class_1),
    pc1_pred = ifelse(class == "class_1", 1, 0),
    pc1_tot = cumsum(pc1_pred)
  ) %>% 
  select(contains("pc1"), .pred_class_1) %>% 
  arrange(-pc1) %>% 
  ggplot() +
  geom_line(aes(pc1, pc1_tot)) +
  geom_line(aes(pc1_tot, pc1_tot), color = "red", linetype = 2)


rf_tr_holdout %>% 
  arrange(.pred_class_2, (class)) %>% 
  mutate(
    pc1 = cumsum(.pred_class_2),
    pc1_pred = ifelse(class == "class_2", 1, 0),
    pc1_tot = cumsum(pc1_pred)
  ) %>% 
  select(contains("pc1"), .pred_class_2) %>% 
  #View()
  arrange(-pc1)  %>% 
  ggplot() +
  geom_line(aes(pc1, pc1_tot)) +
  geom_line(aes(pc1_tot, pc1_tot), color = "red", linetype = 2)



library(rlang)
add_cols <- function(.data, x) {
  x <- enquo(x)
  str_x <- substr(as_name(x), 7, nchar(as_name(x)))
  is_nm <- parse_expr(paste0("is_", str_x))
  bin_nm <- parse_expr(paste0(str_x, "_bin"))
  bin_avg <- parse_expr(paste0(str_x, "_bin_avg"))
  .data %>% 
    mutate(
      !! is_nm  := ifelse(class == str_x, 1, 0),
      !! bin_nm := case_when(
        !!x <= 0.1 ~ 0.1,
        !!x <= 0.2 ~ 0.2,
        !!x <= 0.3 ~ 0.3,
        !!x <= 0.4 ~ 0.4,
        !!x <= 0.5 ~ 0.5,
        !!x <= 0.6 ~ 0.6,
        !!x <= 0.7 ~ 0.7,
        !!x <= 0.8 ~ 0.8,
        !!x <= 0.9 ~ 0.9,       
        TRUE ~ 1
      )
    ) 
} 

rf_tr_holdout %>% 
  filter(.pred_class_1 >= 0.3, .pred_class_1 < 0.4) %>% 
  count(class)

rf_tr_holdout %>% 
  add_cols(.pred_class_1) %>% 
  filter(class_1_bin  == 0.4) %>% 
  count(is_class_1)

rf_tr_holdout %>% 
  add_cols(.pred_class_1) %>% 
  group_by(class_1_bin) %>% 
  summarise(
    total = sum(is_class_1) / n(),
    bin = median(.pred_class_1),
    number = n(),
    postivies = sum(is_class_1)
  ) %>% 
  ggplot() +
  geom_line(aes(bin, total))

  
caret::calibration(class ~ .pred_class_1, data = rf_tr_holdout) %>% plot()
