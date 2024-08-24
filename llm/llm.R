library(ollamar)

system_msg <- paste0("You are a helpful sentiment analysis engine. You will",
                     " only return one of three responses: positive, negative,",
                     " neutral. The response needs to be based on the ",
                     "sentiment of the prompt. The response should not be capitalized."
)

messages <- list(
  list(role = "system", content = system_msg),
  list(role = "user", content = "I really like this toaster")
)

chat("llama3.1", messages, output = "text")

messages <- list(
  list(role = "system", content = system_msg),
  list(role = "user", content = "I really like this toaster\nThis is the worst apple\nNot sure how to feel about this bed")
)

chat("llama3.1", messages, output = "text")


system_msg <- paste(
  "You are a helpful sentiment analysis engine.",
  "You will only return one of three responses: positive, negative, neutral.",
  "The prompt will include a list of text to analyze.",
  "Return a response for each of the items in that list.",
  "The response hast to be a list of the results, no explanations.",
  "No capitalization.",
  "The response needs to be comma separated, no spaces."
)

reviews <- tibble::tribble(
  ~name,     ~review,
  "adam",    "This is the best toaster\n I have ever bought",
  "berry",   "Toaster arrived broken, waiting for replancement",
  "charles", "The washing machine is as\n advertised, can't wait to use it",
  "dan",     "Not sure how to feel about this tevelision, nice brightness but bad definition"
)

library(jsonlite)

all_items <- paste0("{", reviews$review, "}", collapse = "")

pred_str <- chat(
  model = "llama3.1",
  messages = list(
    list(role = "system", content = system_msg),
    list(role = "user", content = toJSON(reviews$review))
  ),
  output = "text"
)

predictions <- strsplit(pred_str, ",")[[1]]

predictions
