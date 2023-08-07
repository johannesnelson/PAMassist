options(shiny.maxRequestSize=600*1024^2)

library(shiny)
library(shinydashboard)
library(DT)
library(ggplot2)
library(tidyverse)
library(monitoR)
library(tuneR)
library(RColorBrewer)
library(leaflet)
location_data <- read.csv("location_data.csv")

ui <- dashboardPage(
  dashboardHeader(title = "Species Detections"),
  dashboardSidebar(
    fileInput('detection_data',
              'Upload Detection CSV',
              accept = c('text/csv',
                         'text/comma-separated-values,text/plain',
                         '.csv')),
    uiOutput("species_dropdown"),
    uiOutput("conf_val")

  ),
  dashboardBody(
    tabsetPanel(id = "tabs",
                tabPanel("Data",
                         fluidRow(
                           box(
                             conditionalPanel(
                               condition = "output.tabular_data == null",
                               h5("Please upload the data to see the figure")
                               ),
                             plotOutput("frequency_chart"),
                             width = 12,
                             height = 800
                             )
                           ),
                         fluidRow(
                           box(
                             conditionalPanel(
                               condition = "output.tabular_data == null",
                               h5("Please upload the data to see the table.")
                               ),
                             DTOutput("tabular_data"),
                             width = 8
                             )
                           )
                         ),
                tabPanel("Validation",
                         fluidRow(
                           box(
                             plotOutput("spectrogram")
                             )
                           ),
                         fluidRow(
                           box(
                             DTOutput("tabular_data_2")
                             )
                           )
                         ),
                tabPanel("Map",
                         fluidRow(
                           box(
                             leafletOutput("map", height = 800),width = 12, height = 800
                           )
                         )
                         )
                )
    )
  )


server <- function(input, output, session) {

  my_data <- reactive({
    req(input$detection_data)
    inFile <- input$detection_data
    read.csv(inFile$datapath)
  })


  output$species_dropdown <- renderUI({
    data_to_show <- my_data()
    data_to_show <- data_to_show[data_to_show$confidence >= input$conf_val,]
    unique_species <- c("All", unique(data_to_show$common_name))
    selectInput("species", "Species:", choices = unique_species, selected = "All", multiple = TRUE)
  })


  output$conf_val <- renderUI({
    sliderInput(inputId = "conf_val", label = "Confidence Cutoff:", min = 0, max = 1.0, value = 0.1)
  })

  output$tabular_data <- renderDT({
    data_to_show <- my_data()[,c('common_name', 'confidence')]
    if (!"All" %in% input$species) {
      data_to_show <- data_to_show[data_to_show$common_name %in% input$species,]
    }
    data_to_show <- data_to_show[data_to_show$confidence >= input$conf_val,]
    data_to_show
  })



  output$tabular_data_2 <- renderDT({
    data_to_show <- my_data()[,c('common_name', 'confidence')]
    if (!"All" %in% input$species) {
      data_to_show <- data_to_show[data_to_show$common_name %in% input$species,]
    }
    data_to_show <- data_to_show[data_to_show$confidence >= input$conf_val,]
    data_to_show
  })



  output$frequency_chart <- renderPlot({
    data_to_show <- my_data() %>%
      filter(confidence >= input$conf_val) %>%
      group_by(common_name) %>%
      summarise(count = n())

    if (!"All" %in% input$species) {
      data_to_show <- data_to_show[data_to_show$common_name %in% input$species,]
    }

    data_to_show <- data_to_show[order(-data_to_show$count),]

    # Creating a frequency chart using ggplot2
    num_colors <- length(unique(data_to_show$common_name))
    cbPalette <- colorRampPalette(brewer.pal(9, "Set1"))(num_colors)
    ggplot(data_to_show, aes(x = reorder(common_name, count), y = count, fill = common_name)) +
      geom_bar(stat = "identity") +
      scale_fill_manual(values = cbPalette) +
      scale_y_continuous(expand = c(0,0))+
      labs(title = "Frequency of Each Species",
           x = "Species",
           y = "Count") +
      coord_flip()+
      guides(fill="none")

  }, height = 800)



  output$spectrogram <- renderPlot({
    data_for_val <- my_data()

    if (!"All" %in% input$species) {
      data_for_val <- data_for_val[data_for_val$common_name %in% input$species,]
    }

    data_for_val <- data_for_val[data_for_val$confidence >= input$conf_val,]

    # Print the value of input$tabs
    print(paste0("Tab: ", input$tabs))

    # Add print statements to check values
    print(nrow(data_for_val))
    print(head(data_for_val$filepath, 10)) # print the first 10 file paths
    print(input$species) # print the selected species
    print(input$conf_val) # print the confidence cutoff value
    print(head(my_data(), 10))

    temp_wave <- readWave(data_for_val$filepath[1],
                          from = data_for_val$start[1],
                          to = data_for_val$end[1],
                          units = 'seconds')
    viewSpec(temp_wave)


  })


  output$map <- renderLeaflet({
    data_to_map <- my_data()

    if (!"All" %in% input$species) {
      data_to_map <- data_to_map[data_to_map$common_name %in% input$species,]
    }

    data_to_map <- data_to_map[data_to_map$confidence >= input$conf_val,]

    locations <- location_data

    map_table <- data_to_map %>% group_by(locationID) %>% summarise(diversity = length(unique(common_name)))
    map_table <- merge(x = map_table, y = locations, by = "locationID")


    all_spec_names <- data_to_map %>%
      group_by(locationID) %>%
      summarize(species = toString(unique(common_name)))


    map_table <- merge(x = map_table, y = all_spec_names, by = "locationID")


    map <- leaflet() %>%
      addProviderTiles(providers$Esri.WorldImagery) %>%
      setView(lng = mean(map_table$lon), lat = mean(map_table$lat), zoom = 15)

    # Add markers for each site
    for (i in 1:nrow(map_table)) {
      map <- map %>% addMarkers(lng = map_table$lon[i], lat = map_table$lat[i],
                                popup = paste("<b>Site Name:</b>", map_table$locationID[i],
                                              "<br><b>Species Diversity:</b>", map_table$diversity[i],
                                              "<br><b>Species Present:</b>", all_spec_names$species[i]))
    }

    map
  })



}

shinyApp(ui, server)
