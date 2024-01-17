library(tidyverse)
library(magrittr)
library(calendR)
library(shiny)
library(leaflet)
library(shinythemes)
library(DT)
library(sf)

source("project_functions.R")
load("project_RData_files/sites.RData")

weather_options <- c(
  "Air temperature (\u00B0C)", "Relative humidity (%)",
  "Wind speed (kn)", "Visibility (m)")
data_options <- list(
  "Raw hourly data",
  "Daily aggregates" = c("Daily average",
                         "Daily maxima", "Daily minima"),
  "Monthly aggregates" = c("Monthly average",
                           "Monthly maxima", "Monthly minima")
)
months = c(1:11)
names(months) <- month.name[months]
raw_options <- c("Annual", "Month", "Week", "Day")
daily_options <- c("Annual", "Month", "Week")
monthly_options <- c("Annual", "Month")
weeks_list <- as_date(seq(dmy_hm("1/1/2020 00:00"),
                          dmy_hm("30/11/2021 23:00"),
                          "week")
                      )

# UI ----------------------------------------------------------------------

ui <- navbarPage(
  "R-Project", theme = shinytheme("flatly"),

# UI Tab 1 with meteorological elements -----------------------------------

  tabPanel(
    "Meteorological variables",
    # Base map
    fluidPage(
      sidebarLayout(
        sidebarPanel(
          h4(p(paste(
            "Meteorological data collected from 20 sites across the",
            "United Kingdom from Jan to Nov 2021")),
            style = "line-height:1.75"
          ),
          selectizeInput(
            "sitesM", label = "Weather stations",
            choices = sites$Site_Name, multiple = TRUE,
            options = list(placeholder = "Select up to five sites",
                           maxItems = 5)
          ),
          # Select weather variable
          selectizeInput(
            "varM", label = "Weather variables", choices = weather_options,
            options = list(placeholder = "Select weather variable")
          ),
          # Select data output type
          selectizeInput(
            "data_output", label = "Data output", choices = data_options,
            options = list(placeholder = "Select data output")
          ),
          #  Conditional output selections when raw data is selected
          conditionalPanel(
            condition = "input.data_output == 'Raw hourly data'",
            selectizeInput(
              "raw", label = "Time/date options", choices = raw_options,
              options = list(placeholder = "Select time/date output")
            ),
            # Raw data with single day selected
            conditionalPanel(
              condition = "input.raw == 'Day'",
              dateInput(
                "day_raw", label = "Select date", value = "2021-01-01",
                min = "2021-01-01", max = "2021-11-30",
                format = "d-MM-yyyy"
              )
            ),
            # Raw data with week selected
            conditionalPanel(
              condition = "input.raw == 'Week'",
              selectizeInput(
                "week_raw", label = "Select week", choices = weeks_list,
                options = list(placeholder = "Week beginning")
              )
            ),
            # Raw data with month selected
            conditionalPanel(
              condition = "input.raw == 'Month'",
              selectizeInput(
                "month_raw", label = "Select month", choices = months,
                options = list(placeholder = "Month")
              )
            )
          ),
          # Conditional output selections when daily aggregates are selected
          conditionalPanel(
            condition = "input.data_output == 'Daily average' ||
                         input.data_output == 'Daily maxima' ||
                         input.data_output == 'Daily minima'",
            selectizeInput(
              "daily", label = "Time/date options", choices = daily_options,
              options = list(placeholder = "Select time/date output")
            ),
            # Daily aggregates with week selected
            conditionalPanel(
              condition = "input.daily == 'Week'",
              selectizeInput(
                "week_daily", label = "Select week", choices = weeks_list,
                options = list(placeholder = "Week beginning")
              )
            ),
            # # Daily aggregates with month selected
            conditionalPanel(
              condition = "input.daily == 'Month'",
              selectizeInput(
                "month_daily", label = "Select month", choices = months,
                options = list(placeholder = "Month")
              )
            )
          )
        ),
        mainPanel(
          tabsetPanel(
            tabPanel("Map",
              leafletOutput("mapM", height = 550)
            ),
            tabPanel("Plot",
                     br(),
                     plotOutput("meteo", height = 500)
            ),
            tabPanel(
              "Table",
              h4(paste("Daily averages for selected sites from",
              "24/11/2021 to 30/11/2021")
              ),
              br(),
              div(dataTableOutput("table"), style = "font-size:60%")
            ),
            tabPanel(
              "Downloads",
              br(),
              h4(paste("Ensure at least one site has been selected",
              "before attempting download")),
              br(),
              h5("Download report with map, plot, and table for selected sites"),
              downloadButton("report_download", label = "Download report"),
              br(),
              br(),
              h5("Download table for selected sites as csv file"),
              downloadButton("csv_download", label = "Download table")
            )
          )
        )
      )
    )
  ),

# UI Tab 2 with Hutton criteria bits --------------------------------------

  tabPanel(
    "Hutton criteria",
    # Base map
    fixedPanel(
      id = "mapH_panel",
      top = 60, bottom = 0, right = 0, left = 0,
      leafletOutput("mapH", height = "calc(100vh - 50px)")
    ),
    fixedPanel(
      id = "H_info_panel",
      top = 150, left = 100, right = "auto", bottom = "auto",
      width = 350, height = "auto",
      wellPanel(
        h4(p(paste(
          "The Hutton criteria is a diagnostic used to assess the risk of",
          "blight forming on potato crops.")),
          p(paste(
            "For the Hutton criteria to be met, both of the following",
            "conditions must occur on two consecutive days:")
          ),
          tags$ol(
            tags$li("Each day has a minimum temperature of 10°C"),
             tags$li("Each day has at least six hours with a relative humidity ≥ 90%")
          ),
          style = "line-height:1.75"
        )
      )
    ),
    # Panel with input controls
    fixedPanel(
      id = "H_options_panel",
      top = 80, left = "auto", right = 70, bottom = "auto",
      width = 450, height = "auto",
      wellPanel(
        selectizeInput(
          "siteH", "Select site", choices = sites$Site_Name,
          options = list(placeholder = "Select data output")),
        selectInput(
          "mthH", "Select month", choices = months),
        br(),
        plotOutput("calendar")
      )
    )
  )
)


# Server ------------------------------------------------------------------

server <- function(input, output, session){

#  Outputs for meteorological tab -----------------------------------------

   # plotting base map
  output$mapM <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$CartoDB.PositronNoLabels,
                       options = providerTileOptions(opacity = 1)) %>%
      setView(lng = -6, lat = 54.7, zoom = 5) %>%
      setMaxBounds(-30, 45, 40, 64)
  })
  
  # Markers
  observe({
    leafletProxy("mapM") %>%
      clearMarkers()
    if (!is.null(input$sitesM)){
      markers <- sites %>%
        filter(Site_Name %in% input$sitesM)
      leafletProxy("mapM") %>%
      clearMarkers() %>%
      addMarkers(lat = markers$Latitude,
                 lng = markers$Longitude,
                 label = markers$Site_Name)
    }
  })
  
  # Meteorological plot
  month_sel <- reactiveVal(NULL)
  week_sel <- reactiveVal(NULL)
  day_sel <- reactiveVal(NULL)
  sites_sel <- reactiveVal()
  var_sel <- reactiveVal()
  data_sel <- reactiveVal()
  
  observe({
    # Setting month value
    if (input$data_output == "Raw hourly data" & input$raw == "Month") {
      month_sel(input$month_raw)
    } else if (
      (input$data_output == 'Daily average' |
       input$data_output == 'Daily maxima' |
       input$data_output == 'Daily minima') &
      input$daily == "Month") {
      month_sel(input$month_daily)
    } else {
      month_sel(NULL)
    }
    # Setting week value
    if (input$data_output == "Raw hourly data" & input$raw == "Week") {
      week_sel(week(as_date(input$week_raw)))
    } else if (
      (input$data_output == 'Daily average' |
       input$data_output == 'Daily maxima' |
       input$data_output == 'Daily minima') &
      input$daily == "Week") {
      week_sel(week(as_date(input$week_daily)))
    } else {
      week_sel(NULL)
    }
    # Setting day value
    if (input$data_output == "Raw hourly data" & input$raw == "Day") {
      day_sel(input$day_raw)
    } else {
      day_sel(NULL)
    }
    sites_sel(input$sitesM)
    var_sel(input$varM)
    data_sel(input$data_output)
  })
  # Plotting chart with selected parameters using plot function
  output$meteo <- renderPlot(
    if (!is.null(sites_sel())){
      plt_function(selected_sites = sites_sel(),
                   selected_var = var_sel(),
                   data_type = data_sel(),
                   Mth = month_sel(),
                   Wk = week_sel(),
                   Day = day_sel()
      )
  })
  
  


# Table of selected sites -----------------------------------------------
  table <- reactive({table_function(input$sitesM)})
  output$table <- renderDataTable(
    if (!is.null(input$sitesM)) {
      table()
    }
    )
 

# # Downloads -------------------------------------------------------------
  # Table csv download
  output$csv_download <- downloadHandler(
    filename = function() {
      "table.csv"
    },
    content = function(file) {
      write.csv(table(), file)
    }
  )
  output$report_download <- downloadHandler(
    filename = "report.docx",
    content = function(file) {
      params <- list(month_sel = month_sel(),
                     week_sel = week_sel(),
                     day_sel = day_sel(),
                     sites_sel = sites_sel(),
                     var_sel = var_sel(),
                     data_sel = data_sel()
                     )
      rmarkdown::render("report.Rmd",
             output_file = file,
             output_format = "word_document",
             params = params,
             envir = new.env(parent = globalenv())
      )
    }
  )
  
# Outputs for Hutton tab --------------------------------------------------

  selected_siteH <- reactive({
    get(load(paste0("project_RData_files/site_",
                    sites$Site_ID[sites$Site_Name == input$siteH],
                    ".Rdata"))
    )
  })
  selected_mthH <- reactive({input$mthH})
  output$calendar <- renderPlot({
    f_hutton(selected_siteH(), as.numeric(selected_mthH()))
  })
  output$mapH <- renderLeaflet({
    leaflet() %>%
      addProviderTiles(providers$CartoDB.PositronNoLabels,
                       options = providerTileOptions(opacity = 1)) %>%
      setView(lng = sites$Longitude[sites$Site_Name == input$siteH],
              lat = sites$Latitude[sites$Site_Name == input$siteH],
              zoom = 6) %>%
      setMaxBounds(-30, 45, 40, 64) %>%
      addMarkers(lng = sites$Longitude[sites$Site_Name == input$siteH],
                 lat = sites$Latitude[sites$Site_Name == input$siteH],
                 label = sites$Site_Name[sites$Site_Name == input$siteH]
                 )
  })
}

shinyApp(ui, server)
