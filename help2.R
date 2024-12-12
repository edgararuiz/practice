
source(here::here("help/help.R"))
llm_use("ollama", "llama3.2", seed = 100, .cache = "_temp_folder")
helpr("llm_classify", "mall", lang = "spanish")
helpr("aes", "ggplot2", "spanish")

library(ggplot2)
Sys.setenv(LANG = "fr")
helpr("aes")


source(here::here("help/help.R"))
llm_use("ollama", "llama3.2", seed = 100)
helpr("aes", "ggplot2", "spanish")



helpr("aes", "ggplot2", "portuguese")

helpr("aes", "ggplot2", "korean")


library(mall)


Sys.setenv(LANG = "spanish")
helpr("llm_classify")


Sys.setenv(LANG = "fr_UTF")
helpr("llm_classify")
