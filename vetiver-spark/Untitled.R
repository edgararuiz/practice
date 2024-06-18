
library(sparklyr)
library(dplyr)

sc <- spark_connect(method = "databricks_connect")
lendingclub_dat <- tbl(sc, dbplyr::in_catalog("hive_metastore", "default", "lendingclub"))

lendingclub_local <- lendingclub_dat |> 
  head(10) |> 
  collect()

library(pins)
library(vetiver)
board <- board_connect(auth = "envvar")
model <- vetiver_pin_read(board, "garrett@posit.co/lending_club_model")


lendingclub_prep <- lendingclub_local |>  
  select(-c("acc_now_delinq", "chargeoff_within_12_mths",
            "debt_settlement_flag", "debt_settlement_flag_date",
            "deferral_term",
            "delinq_amnt","desc","disbursement_method","emp_title",
            "funded_amnt","funded_amnt_inv","grade","hardship_amount",
            "hardship_dpd", "hardship_end_date", "hardship_flag",
            "hardship_last_payment_amount", "hardship_length",
            "hardship_loan_status", "hardship_payoff_balance_amount",
            "hardship_reason", "hardship_start_date", "hardship_status",
            "last_credit_pull_d",
            "hardship_type","id","initial_list_status","installment","issue_d",
            "last_pymnt_d", "last_pymnt_amnt", "loan_status",
            "member_id", "next_pymnt_d", "num_tl_30dpd", "num_tl_120dpd_2m", 
            "orig_projected_additional_accrued_interest",
            "out_prncp", "out_prncp_inv","payment_plan_start_date",
            "policy_code","purpose", "pymnt_plan", "revol_bal_joint",
            "revol_util", "sec_app_earliest_cr_line",
            "sec_app_inq_last_6mths", "sec_app_mort_acc", "sec_app_open_acc",
            "sec_app_revol_util", "sec_app_open_act_il",
            "sec_app_num_rev_accts", "sec_app_chargeoff_within_12_mths",
            "sec_app_collections_12_mths_ex_med",
            "sec_app_mths_since_last_major_derog","settlement_amount",
            "settlement_date", "settlement_percentage", "settlement_status",
            "settlement_term","sub_grade","title", "total_pymnt", "total_pymnt_inv",
            "total_rec_int", "total_rec_late_fee", "total_rec_prncp", # "total_rev_hi_lim",
            "url","verification_status",
            "verification_status_joint")) |>
  mutate(
    # Convert these columns into numeric
    across(c(starts_with("annual"), starts_with("dti"), starts_with("inq"),  
             starts_with("mo"), starts_with("mths"), starts_with("num"), 
             starts_with("open"), starts_with("percent"), starts_with("pct"), 
             starts_with("revol"), starts_with("tot"),  "acc_open_past_24mths", 
             "all_util", "avg_cur_bal","bc_open_to_buy", "bc_util", 
             "collections_12_mths_ex_med", "collection_recovery_fee", "delinq_2yrs", 
             "il_util", "loan_amnt", "max_bal_bc", "pub_rec", 
             "pub_rec_bankruptcies", "recoveries", "tax_liens"), 
           ~ as.numeric(.)),
    # Calculate a loan to income statistic
    loan_to_income = case_when(
      application_type == "Individual" ~ loan_amnt / annual_inc,
      .default = loan_amnt / annual_inc_joint
    ),
    # Calculate the percentage of the borrower's total income that current debt 
    # obligations, including this loan, will represent
    adjusted_dti = case_when(
      application_type == "Individual" ~ (loan_amnt + tot_cur_bal) / (annual_inc),
      .default = (loan_amnt + tot_cur_bal) / (annual_inc_joint)
    ),
    #  Calculate utilization on installment accounts excluding mortgage balance
    il_util_ex_mort = case_when(
      total_il_high_credit_limit > 0 ~ total_bal_ex_mort / total_il_high_credit_limit,
      .default = 0
    ),
    # Fill debt to income joint with individual debt to income where missing
    dti_joint = coalesce(dti_joint, dti),
    # Fill annual income joint with individual annual income where missing
    annual_inc_joint = coalesce(annual_inc_joint, annual_inc),
    term = as.numeric(stringr::str_trim(stringr::str_remove(term, "months")))
    ) 

predict(model, lendingclub_prep)
