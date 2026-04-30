library(shiny)
library(tidyverse)
library(lubridate)
library(plotly)

source("dashboard_functions.R")

TIMEZONE <- "EST"

# -------------------- UI --------------------
ui <- fluidPage(
  
  tags$head(
    tags$style(HTML("
      .title-banner {
        background-image: url('images/GCReW_Drone.jpg');
        background-size: cover;
        background-position: center;
        min-height: 150px;
        color: white;
        padding: 20px;
      }
      .title-banner h1 {
        text-shadow: 0 2px 3px rgba(0,0,0,0.8);
      }

      #loading-overlay {
        position: fixed;
        top: 0; left: 0;
        width: 100%; height: 100%;
        background: #ffffffcc;
        z-index: 9999;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
      }

      .spinner {
        border: 8px solid #c3c3c3;
        border-top: 8px solid #054163;
        border-radius: 50%;
        width: 60px;
        height: 60px;
        animation: spin 1s linear infinite;
      }

      @keyframes spin {
        0% { transform: rotate(0deg); }
        100% { transform: rotate(360deg); }
      }
    ")),
    
    tags$script(HTML("
      Shiny.addCustomMessageHandler('hideLoadingOverlay', function(message) {
        var el = document.getElementById('loading-overlay');
        if (el) el.style.display = 'none';
      });
    "))
  ),
  
  # Loading overlay
  div(id = "loading-overlay",
      div(class = "spinner"),
      p("Loading the latest data…")
  ),
  
  # Banner
  div(class = "title-banner",
      h1("SERC Lateral Transport")
  ),
  
  # Date inputs
  fluidRow(
    column(6, dateInput("start_date", "Start date", value = Sys.Date())),
    column(6, dateInput("end_date", "End date", value = Sys.Date()))
  ),
  
  navbarPage("",
             
             tabPanel("Overview",
                      fluidRow(
                        column(6,
                               htmlOutput("today"),
                               h3("Latest data"),
                               htmlOutput("data_latest")
                        ),
                        column(6,
                               img(src = "images/SERC-Docks4_CreditSamBenson_web.jpg",
                                   width = "100%"),
                               br(), br(),
                               img(src = "images/flume.png",
                                   width = "100%")
                        )
                      )
             ),
             
             tabPanel("Physiochemistry",
                      sidebarLayout(
                        sidebarPanel(
                          checkboxGroupInput("exo_vars", "Variables",
                                             choices = c(
                                               "DO_mgL","FDOM_RFU","Chlorophyll_ugL","Conductivity",
                                               "DO_saturation","Salinity_PPT","TDS_mgL","pH","Temp_C","Depth_m"
                                             ),
                                             selected = c("Depth_m","Salinity_PPT")
                          )
                        ),
                        mainPanel(
                          plotlyOutput("plot_exo_dock"),
                          plotlyOutput("plot_exo_flume")
                        )
                      )
             ),
             
             tabPanel("Hydrology",
                      sidebarLayout(
                        sidebarPanel(
                          checkboxGroupInput("hydrology_vars","Variables",
                                             choices = c(
                                               "Water_depth_m","Flowrate_ms","Index_velocity_ms","Mean_velocity_ms"
                                             ),
                                             selected = c("Water_depth_m","Index_velocity_ms")
                          )
                        ),
                        mainPanel(
                          plotlyOutput("plot_hydrology_dock"),
                          plotlyOutput("plot_hydrology_flume")
                        )
                      )
             ),
             
             tabPanel("GHG",
                      sidebarLayout(
                        sidebarPanel(
                          checkboxGroupInput("ghg_vars","Variables",
                                             choices = c(
                                               "H2O_ppm","CO2d_ppm","CH4d_ppm",
                                               "Cavity_pressure_kPa","Cavity_temperature_C"
                                             ),
                                             selected = c("CH4d_ppm","CO2d_ppm")
                          )
                        ),
                        mainPanel(
                          plotlyOutput("plot_ghg_dock"),
                          plotlyOutput("plot_ghg_flume")
                        )
                      )
             ),
             
             tabPanel("Radon",
                      sidebarLayout(
                        sidebarPanel(
                          checkboxGroupInput("rad_vars","Variables",
                                             choices = c("Relative_humidity_pct","Radon_Bqm3","Radon_error_Bqm3"),
                                             selected = c("Radon_Bqm3","Radon_error_Bqm3")
                          )
                        ),
                        mainPanel(
                          plotlyOutput("plot_radon_dock"),
                          plotlyOutput("plot_radon_flume")
                        )
                      )
             )
  )
)

# -------------------- SERVER --------------------
server <- function(input, output, session) {
  
  Sys.setenv(TZ = TIMEZONE)
  
  # Load data
  exo <- read_csv("https://raw.githubusercontent.com/wilsonsj100/serc-lateral-flux/refs/heads/dashboard/Processed_data/GCREW_MARSH_OUTLET_EXO.csv") %>%
    mutate(TIMESTAMP = ymd_hms(TIMESTAMP, tz = TIMEZONE))
  
  hydrology <- read_csv("https://raw.githubusercontent.com/wilsonsj100/serc-lateral-flux/refs/heads/dashboard/Processed_data/GCREW_MARSH_OUTLET_HYDROLOGY.csv") %>%
    mutate(TIMESTAMP = ymd_hms(TIMESTAMP, tz = TIMEZONE))
  
  ghg <- read_csv("https://raw.githubusercontent.com/wilsonsj100/serc-lateral-flux/refs/heads/dashboard/Processed_data/GCREW_MARSH_OUTLET_GHG.csv") %>%
    mutate(TIMESTAMP = ymd_hms(TIMESTAMP, tz = TIMEZONE))
  
  radon <- read_csv("https://raw.githubusercontent.com/wilsonsj100/serc-lateral-flux/refs/heads/dashboard/Processed_data/GCREW_MARSH_OUTLET_RADON.csv") %>%
    mutate(TIMESTAMP = ymd_hms(TIMESTAMP, tz = TIMEZONE))
  
  # Date limits
  min_date <- min(c(exo$TIMESTAMP, hydrology$TIMESTAMP, ghg$TIMESTAMP, radon$TIMESTAMP), na.rm = TRUE) %>% as_date()
  max_date <- max(c(exo$TIMESTAMP, hydrology$TIMESTAMP, ghg$TIMESTAMP, radon$TIMESTAMP), na.rm = TRUE) %>% as_date()
  
  updateDateInput(session, "start_date", value = max_date - days(7), min = min_date, max = Sys.Date())
  updateDateInput(session, "end_date", value = max_date, min = min_date, max = Sys.Date())
  
  # Colors
  exo_colors <- c( "Depth_m" = "darkblue", "DO_mgL" = "lightblue", "pH" = "pink", "Salinity_PPT" = "grey50", "Temp_C" = "red", "FDOM_RFU" = "brown", "Chlorophyll_ugL" = "darkgreen", "Conductivity" = "grey20", "DO_saturation" = "lightblue", "TDS_mgL" = "orange" ) 
  hydrology_colors <- c( "Water_depth_m" = "darkblue", "Flowrate_ms" = "lightblue1", "Index_velocity_ms" = "lightblue3", "Mean_velocity_ms" = "lightblue4" ) 
  ghg_colors <- c( "H2O_ppm" = "lightblue", "CO2d_ppm" = "goldenrod", "CH4d_ppm" = "red4", "Cavity_pressure_kPa" = "purple4", "Cavity_temperature_C" = "red" ) 
  rad_colors <- c( "Relative_humidity_pct" = "lightblue", "Radon_Bqm3" = "purple", "Radon_error_Bqm3" = "darkblue" )
  
  # Plots
  output$plot_exo_dock <- renderPlotly({
    make_plot(exo,"DOCK",input$exo_vars,input$start_date,input$end_date,exo_colors)
  })
  
  output$plot_exo_flume <- renderPlotly({
    make_plot(exo,"FLUME",input$exo_vars,input$start_date,input$end_date,exo_colors)
  })
  
  output$plot_hydrology_dock <- renderPlotly({
    make_plot(hydrology,"DOCK",input$hydrology_vars,input$start_date,input$end_date,hydrology_colors)
  })
  
  output$plot_hydrology_flume <- renderPlotly({
    make_plot(hydrology,"FLUME",input$hydrology_vars,input$start_date,input$end_date,hydrology_colors)
  })
  
  output$plot_ghg_dock <- renderPlotly({
    make_plot(ghg,"DOCK",input$ghg_vars,input$start_date,input$end_date,ghg_colors)
  })
  
  output$plot_ghg_flume <- renderPlotly({
    make_plot(ghg,"FLUME",input$ghg_vars,input$start_date,input$end_date,ghg_colors)
  })
  
  output$plot_radon_dock <- renderPlotly({
    make_plot(radon,"DOCK",input$rad_vars,input$start_date,input$end_date,rad_colors)
  })
  
  output$plot_radon_flume <- renderPlotly({
    make_plot(radon,"FLUME",input$rad_vars,input$start_date,input$end_date,rad_colors)
  })
  
  # Latest data
  output$data_latest <- renderUI({
    
    exo_times <- latest_times(exo)
    hydrology_times <- latest_times(hydrology)
    ghg_times <- latest_times(ghg)
    radon_times <- latest_times(radon)
    
    formatted_list <- paste(
      "DOCK:</br>
    <ul><li", exo_times$color[exo_times$Site == "DOCK"],
      "><b>EXO2 water quality sonde:</b> ",
      exo_times$formatted[exo_times$Site == "DOCK"], "</li>
    
    <li", hydrology_times$color[hydrology_times$Site == "DOCK"],
      "><b>Compact Bubbler Sensor:</b> ",
      hydrology_times$formatted[hydrology_times$Site == "DOCK"], "</li>
    
    <li", ghg_times$color[ghg_times$Site == "DOCK"],
      "><b>GHG analyzer:</b> ",
      ghg_times$formatted[ghg_times$Site == "DOCK"], "</li>
    
    <li", radon_times$color[radon_times$Site == "DOCK"],
      "><b>Radon detector:</b> ",
      radon_times$formatted[radon_times$Site == "DOCK"], "</li></ul>
    
    </br>FLUME:</br>
    <ul><li", exo_times$color[exo_times$Site == "FLUME"],
      "><b>EXO2 water quality sonde:</b> ",
      exo_times$formatted[exo_times$Site == "FLUME"], "</li>
    
    <li", hydrology_times$color[hydrology_times$Site == "FLUME"],
      "><b>SontekIQ ADCP:</b> ",
      hydrology_times$formatted[hydrology_times$Site == "FLUME"], "</li>
    
    <li", ghg_times$color[ghg_times$Site == "FLUME"],
      "><b>GHG analyzer:</b> ",
      ghg_times$formatted[ghg_times$Site == "FLUME"], "</li>
    
    <li", radon_times$color[radon_times$Site == "FLUME"],
      "><b>Radon detector:</b> ",
      radon_times$formatted[radon_times$Site == "FLUME"], "</li></ul>"
    )
    
    HTML(formatted_list)
  })
  
  # Hide loader
  observe({
    req(nrow(exo) > 0)
    session$sendCustomMessage("hideLoadingOverlay", TRUE)
  })
}

shinyApp(ui, server)