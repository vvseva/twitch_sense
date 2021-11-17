#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(ggwordcloud)
library(tidytext)
library(websocket)
library(tidyverse)
source("secret.R")

library(mongolite)

m <- mongo(collection = "test",
           db = "test",
           url ="mongodb://localhost")

m <- mongo(collection = "seva_test_logs")

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  
  # db_RTC <- reactiveVal(
  #   tibble(time = Sys.time(), message = "hi message 2")
  #   )
  
  something_RTC <- reactive({
      input$channel_btn
    
      ws <- WebSocket$new("wss://irc-ws.chat.twitch.tv:443", autoConnect = F)
      ws$connect()
      Sys.sleep(1)
      ws$onMessage(function(event) {
        if (str_detect(event$data, "PING :tmi.twitch.tv")) {
          ws$send("PONG :tmi.twitch.tv")
        }
        else if (str_detect(event$data, "PRIVMSG")) {
          single_message = event$data |> 
            str_extract("PRIVMSG.+") |> 
            str_extract(":.+") |> 
            str_remove(":")
          
          test_ins = tibble(time = Sys.time(), 
                            message = single_message, 
                            id = m$count()+1)
          
          # newValue <- db_RTC() |> 
          #   bind_rows(test_ins)
          # 
          # db_RTC(newValue)
          
          m$insert(test_ins)
        } else {  
          cat("Client got msg: ", event$data, "\n")
        }      
        
    })
      Sys.sleep(1)
      ws$send(pass_auth)
      Sys.sleep(1)
      ws$send(nick)
      Sys.sleep(1)
      ws$send("CAP REQ :twitch.tv/tags twitch.tv/commands twitch.tv/membership")
      Sys.sleep(1)
      ws$send(str_glue("JOIN #{channel_name}", channel_name = input$channel))
      
      
      ws$send("PRIVMSG #vvseva :проверяю IRC")
      
      ws$close()
  })
  

    output$wordcloud <- renderPlot({
      input$draw_btn

        # generate bins based on input$bins from ui.R
      test_out3 <-
        m$find(
          str_glue('{{"id":{{"$gt": {last_ten} }}}}', last_ten = m$count() - 10))
      set.seed(42)
      test_out3 |> 
            # head() |> 
          unnest_tokens(word, message, token = "words") |> 
          count(word) |> 
        # draw the histogram with the specified number of bins
        ggplot(aes(label = word, size = n)) +
          geom_text_wordcloud_area(area_corr_power = 1) +
          scale_size_area(max_size = 24) +
          theme_minimal()

    })

})
