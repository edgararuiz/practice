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

.llm_session <- new.env()
.llm_session$

llm_session <- function() {
    
}

llm_sentiment <- function(x) {
  
  system_msg <- paste(
    "You are a helpful sentiment analysis engine.",
    "You will only return one of three responses: positive, negative, neutral.",
    "The prompt will include a list in JSON format that needs to be analyzed.",
    "Return a response for each of the items in that list.",
    "The response hast to be a list of the results, no explanations.",
    "No capitalization.",
    "The response needs to be comma separated, no spaces."
  )
  
  pred_str <- ollamar::chat(
    model = "llama3.1",
    messages = list(
      list(role = "system", content = system_msg),
      list(role = "user", content = jsonlite::toJSON(x))
    ),
    output = "text"
  )
  predictions <- strsplit(pred_str, ",")[[1]]
  predictions
}

library(dplyr)

reviews |> 
  select(review) |> 
  llm_sentiment()

res <- reviews$review

llm_sentiment(res)

library(glue)



llm_classify <- function(x, options = c()) {
  
  options <- paste0("'", options, "'", collapse = ",")
  
  system_msg <- paste(
    "You are a helpful classification engine.",
    "You will only return ONLY one these responses per entry in the list: {options}.",
    "The prompt will include a list in JSON format that needs to be analyzed.",
    "Return only ONE response for each of the items in that list.",
    "The response hast to be a list of the results, no explanations.",
    "No capitalization.",
    "The response needs to be comma separated, no spaces."
  ) |> 
    glue()
  
  messages <- list(
    list(role = "system", content = system_msg),
    list(role = "user", content = jsonlite::toJSON(x))
  )
  pred_str <- ollamar::chat(
    model = "llama3.1",
    messages = messages,
    output = "text"
  )
  predictions <- strsplit(pred_str, ",")[[1]]
  trimws(predictions)
}

reviews |> 
  mutate(classification = llm_classify(review, c("we need to follow up with customer", "no follow up needed")))

reviews |> 
  mutate(classification = llm_classify(review, c("really happy", "happy", "ok", "angry")))


data_bookReviews |>
  head() |> 
  mutate(classification = llm_classify(review, c("positive", "negative"))) |> 
  as_tibble()

llm_classify(reviews$review, c("we need to follow up with customer", "no follow up needed"))

data_bookReviews |>
  head(1) |> 
  mutate(classification = llm_sentiment(review)) |> 
  as_tibble()

llm_sentiment(data_bookReviews$review[1])

jsonlite::toJSON(data_bookReviews$review[1:6])

reviews |> 
  mutate(sentiment = llm_sentiment(review))

library(classmap)
data(data_bookReviews)
data_bookReviews |> 
  head()


library(purrr)

llm_sentiment <- function(x, options = c("positive", "negative", "neutral")) {
  
  options <- paste0("'", options, "'", collapse = ",")
  
  system_msg <- paste(
    "You are a helpful sentiment analysis engine.",
    "You will only return one of these responses: {options}.",
    "The response needs to be based on the sentiment of the prompt.",
    "Return only one response from the choices given ({options}).",
    "No capitalization."
  ) |> 
    glue()
  
  x |> 
    map_chr(
      ~ {
        tic()
        ollamar::generate(
          model = "llama3.1",
          system = system_msg,
          prompt = .x, 
          output = "text"
        )      
        capture.output(toc())
      },
      .progress = TRUE
    )
}

tic()
llm_sentiment(data_bookReviews$review[1:10])
toc()

book_reviewed <- data_bookReviews|>
  head(10) |> 
  mutate(llm = llm_sentiment(review, options = c("positive", "negative"))) |> 
  select(sentiment, llm, review) |> 
  as_tibble()

book_reviewed |> 
  count(sentiment, llm) 


library(tidyverse)

book_reviewed |> 
  mutate(x = str_detect(review, "1750")) |> 
  pull(x) |> 
  which()


llm_translate <- function(x, options = "spanish") {
  
  options <- paste0("'", options, "'", collapse = ",")
  
  system_msg <- paste(
    "You are a helpful language translationengine.",
    "You will translate the provided prompt to the {options} language.",
    "No comments, or explanation, just return the translation"
  ) |> 
    glue()
  
  x |> 
    map_chr(
      ~ {
        ollamar::generate(
          model = "llama3.1",
          prompt = .x,
          system = system_msg,
          output = "text"
        )      
      },
      .progress = TRUE
    )
}

data_bookReviews[4,] |> 
  mutate(translation = llm_translate(review))

library(tictoc)
tic()
data_bookReviews[1:10,] |> 
  mutate(sentiment = llm_sentiment_parallel(review))
toc()


llm_sentiment_parallel <- function(x, options = c("positive", "negative", "neutral")) {
  
  options <- paste0("'", options, "'", collapse = ",")
  
  system_msg <- paste(
    "You are a helpful sentiment analysis engine.",
    "You will only return one of these responses: {options}.",
    "The response needs to be based on the sentiment of the prompt.",
    "Return only one response from the choices given ({options}).",
    "No capitalization."
  ) |> 
    glue::glue()
  
  x |> 
    furrr::future_map_chr(
      ~ {
        tic()
        ollamar::generate(
          model = "llama3.1",
          system = system_msg,
          prompt = .x, 
          output = "text"
        )      
        return(capture.output(toc()))
      },
      .progress = TRUE
    )
}

library(dplyr)
library(tictoc)
library(classmap)
library(furrr)
plan(multisession)
data("data_bookReviews")
tic()
regular_purrr <- data_bookReviews[1:50,] |> 
  mutate(sentiment = llm_sentiment(review)) |> 
  pull(sentiment)
toc()

tic()
with_furrr <- data_bookReviews[1:50,] |> 
  mutate(sentiment = llm_sentiment_parallel(review)) |> 
  pull(sentiment)
toc()

plan(multisession)
tic()
mixed <- list(1:25, 26:50) |> #list(1:10, 11:20, 21:30, 31:40, 41:50) |> 
  furrr::future_map({~
      llm_sentiment(data_bookReviews[.x,]$review)
  })
toc()



llm_sentiment <- function(x, options = c("positive", "negative", "neutral")) {
  
  options <- paste0("'", options, "'", collapse = ",")
  
  system_msg <- paste(
    "You are a helpful sentiment analysis engine.",
    "You will only return one of three responses: {prompt}.",
    "The prompt will include a list in JSON format that needs to be analyzed.",
    "Return a response for each of the items in that list.",
    "The response hast to be a list of the results, no explanations.",
    "No capitalization.",
    "The response needs to be comma separated, no spaces."
  ) |> 
    glue()
  
  x |> 
    map_chr(
      ~ {
        tic()
        ollamar::generate(
          model = "llama3.1",
          system = system_msg,
          prompt = .x), 
          output = "text"
        )      
        capture.output(toc())
      },
      .progress = TRUE
    )
}



llm_sentiment <- function(x) {
  
  system_msg <- paste(
    "You are a helpful sentiment analysis engine.",
    "You will only return one of three responses: positive, negative, neutral.",
    "The prompt will be a list in JSON format that needs to be analyzed.",
    "The response hast to be a list of the results, no explanations.",
    "No capitalization.",
    "The response needs to be comma separated, no spaces after the comma."
  )
  
  pred_str <- ollamar::chat(
    model = "llama3.1",
    messages = list(
      list(role = "system", content = system_msg),
      list(role = "user", content = jsonlite::toJSON(x))
    ),
    output = "text"
  )
  predictions <- strsplit(pred_str, ",")[[1]]
  predictions
}

tic()
llm_sentiment(data_bookReviews[1:10,]$review)
toc()

x <- data_bookReviews[1:3,]$review

options <- paste0(c("positive", "negative", "neutral"), collapse = ", ")

system_msg <- paste(
  "You are a helpful classification engine.",
  "You will only return ONLY one these responses per entry in the list: {options}.",
  "The prompt will include a list in JSON format that needs to be analyzed.",
  "The response hast to be a list of the results, no explanations.",
  "No capitalization.",
  "The response needs to be comma separated, no spaces."
) |> 
  glue()

reviews <- data_bookReviews$review

tic()
list(1:2, 3:4, 5:6, 7:8, 9:10) |> 
  map(~{
    recs <- reviews[.x]
    pred_str <- ollamar::chat(
      model = "llama3.1",
      messages = list(
        list(role = "system", content = system_msg),
        list(role = "user", content = as.character(toJSON(as.list(recs))))
      ),
      output = "text"
    )
    predictions <- strsplit(pred_str, ",")[[1]]
    predictions  
  })
toc()

library(classmap)
library(purrr)
library(glue)
data(data_bookReviews)

options <- paste0(c("positive", "negative", "neutral"), collapse = ", ")

system_msg <- paste(
  "You are a helpful classification engine.",
  "You will only return ONLY one these responses per entry in the list: {options}.",
  "The prompt will include a list in JSON format that needs to be analyzed.",
  "The response hast to be a list of the results, no explanations.",
  "No capitalization.",
  "The response needs to be comma separated, no spaces."
) |> 
  glue()


data_bookReviews$review |> 
  head(10) |> 
  map_chr(~{
    prompt <- glue("You are a helpful classification engine. Return only one of the following answers: {options}. No capitalization. No explanations. The answer is based on the following text: {.x}")
    ollamar::chat(
      model = "llama3.1",
      messages = list(
        list(role = "user", content = prompt)
      ),
      output = "text"
    )
  })
