library(tidyverse)
library(magrittr)
library(calendR)
library(ggthemes)
library(mapview)
library(leaflet)
library(webshot)
library(png)
load("project_RData_files/sites.RData")

# Function to plot meteorological data ------------------------------------

plt_function <- function(selected_sites,
                         selected_var,
                         data_type = "Raw hourly data",
                         Mth = NULL,
                         Wk = NULL,
                         Day = NULL){
  # Match selected weather variable with with DF column name
  weather_vars <- c("Air temperature (\u00B0C)" = "air_temperature",
                    "Relative humidity (%)" = "rltv_hum",
                    "Wind speed (kn)" = "wind_speed",
                    "Visibility (m)" = "visibility")
  variable <- weather_vars[selected_var]
  # Create a of data frames for selected sites
  df_list <- list()
  for (x in seq(1,length(selected_sites))){
    df_list[[x]] <- get(
      load(paste0("project_RData_files/site_",
                  sites$Site_ID[sites$Site_Name == selected_sites[x]],
                  ".Rdata")
      )
    )
  }
  # Loop through the list of data frames cleaning things up
  for (y in seq(1,length(selected_sites))){
    df_list[[y]] <- df_list[[y]] %>%
      # Filter out 29th Feb
      filter(!(month == 2 & day == 29)) %>%
      # Fix year, create a date/time column
      mutate(year = 2021,
             date_time = make_datetime(year, month, day, hour),
             week = week(date_time)
      )
    # Create a data frame with complete list of days and hours
    complete_hours <- tibble(
      date_time = seq(dmy_hm("1/1/2021 00:00"),
                      dmy_hm("30/11/2021 23:00"), "hour")
    )
    # Fill in missing dates/hours in data sets
    df_list[[y]] <- full_join(complete_hours, df_list[[y]], by = "date_time")
    # Remove duplicate dates
    df_list[[y]] <- df_list[[y]][!duplicated(df_list[[y]]$date_time), ]
    # Filter by date/time output if required
    if (!is_null(Mth)) {
      df_list[[y]] <- df_list[[y]] %>% filter(month == Mth)
    }
    if (!is_null(Wk)) {
      df_list[[y]] <- df_list[[y]] %>% filter(week == Wk)
    }
    if (!is_null(Day)) {
      df_list[[y]] <- df_list[[y]] %>% filter(
        day == day(Day) & month == month(Day)
      )
    }
    # If raw data output selected
    if (data_type == "Raw hourly data") {
      # Select only date/time and variable to be plotted
      df_list[[y]] <- df_list[[y]] %>% select(date_time, variable)
      # Re-name variable column with sites name
      colnames(df_list[[y]]) <-  c("date_time", selected_sites[y])
    }
    
    # If aggregations selected, perform  aggregation and
    # then select only date/time  and variable of interest.
    
    # If daily average output selected
    if (data_type == "Daily average") {
      df_list[[y]] <- df_list[[y]] %>% group_by(year, month, day) %>%
        summarise(variable = mean(!!sym(variable), na.rm = TRUE)
        ) %>%
        mutate(date_time = make_date(year = year, month = month, day = day)) %>%
        ungroup() %>%
        select(date_time, variable)
    }
    # If daily max output selected
    if (data_type == "Daily maxima") {
      df_list[[y]] <- df_list[[y]] %>% group_by(year, month, day) %>%
        summarise(variable = max(!!sym(variable), na.rm = TRUE)
        ) %>%
        mutate(date_time = make_date(year = year, month = month, day = day)) %>%
        ungroup() %>%
        select(date_time, variable)
    }
    # If daily min output selected
    if (data_type == "Daily minima") {
      df_list[[y]] <- df_list[[y]] %>% group_by(year, month, day) %>%
        summarise(variable = min(!!sym(variable), na.rm = TRUE)
        ) %>%
        mutate(date_time = make_date(year = year, month = month, day = day)) %>%
        ungroup() %>%
        select(date_time, variable)
    }
    # If monthly average output selected
    if (data_type == "Monthly average") {
      df_list[[y]] <- df_list[[y]] %>% group_by(month) %>%
        summarise(variable = mean(!!sym(variable), na.rm = TRUE)
        )
    }
    # If monthly max output selected
    if (data_type == "Monthly maxima") {
      df_list[[y]] <- df_list[[y]] %>% group_by(month) %>%
        summarise(variable = max(!!sym(variable), na.rm = TRUE)
        )
    }
    # If monthly min output selected
    if (data_type == "Monthly minima") {
      df_list[[y]] <- df_list[[y]] %>% group_by(month) %>%
        summarise(variable = min(!!sym(variable), na.rm = TRUE)
        )
    }
    # Rename variable column with site name.
    colnames(df_list[[y]]) <-  c("date_time", selected_sites[y])
  }
  # bring all data sets into one data frame
  combined_dfs <- reduce(df_list, full_join, by = "date_time")
  # Filter out a random NA row that was occurring in monthly aggregations
  if (nrow(combined_dfs) == 12) {
    combined_dfs <- combined_dfs %>%
      filter(!is.na(date_time))
  } 
  # Change data to long format for plotting 
  plt_data <- combined_dfs %>%
    pivot_longer(cols = 1:length(selected_sites)+1,
                 names_to = "Selected sites",
                 values_to = selected_var
    )
  # Create plot with selected sites and variable of choice
  y_var <- sym(selected_var)
  if (data_type == "Raw hourly data"){
    plt <- ggplot(data = plt_data, aes(date_time, !! y_var)) +
      geom_line(aes(colour = `Selected sites`)) +
      xlab(NULL) +
      labs(title = paste0(selected_var," (",data_type,")")) +
      theme(aspect.ratio = 1/2)
  }
  if (data_type != "Raw hourly data"){
    if (nrow(combined_dfs) == 11) {
      plt <- ggplot(
        data = plt_data,
        aes(x = factor(month.name[date_time], levels = month.name),
            y = !! y_var)) +
        geom_point(aes(colour = `Selected sites`),size = 2) +
        xlab(NULL) +
        labs(title = paste0(selected_var," (",data_type,")")) +
        theme(aspect.ratio = 1/2)
    } else {
      plt <- ggplot(
        data = plt_data,
        aes(x = date_time, y = !! y_var)) +
        geom_line(aes(colour = `Selected sites`)) +
        xlab(NULL) +
        labs(title = paste0(selected_var," (",data_type,")")) +
        theme(aspect.ratio = 1/2)
    }
  }  
  plt
}


# Table function ----------------------------------------------------------

table_function <- function(selected_sites){
  # Create a of data frames for selected sites
  df_list <- list()
  for (x in seq(1,length(selected_sites))){
    df_list[[x]] <- get(
      load(paste0("project_RData_files/site_",
                  sites$Site_ID[sites$Site_Name == selected_sites[x]],
                  ".Rdata")
      )
    )
  }
  # loop through list of DFs organising data
  for (y in seq(1,length(selected_sites))){
    df_list[[y]] <- df_list[[y]] %>%
      # Fix year and add date_time column
      mutate(year = 2021, date_time = make_datetime(year, month, day, hour))
    # Create a data frame with complete days and hours for last week in Nov
    complete_hours <- tibble(
      date_time = seq(dmy_hm("24/11/2021 00:00"),
                      dmy_hm("30/11/2021 23:00"), "hour")
    )
    # Fill in missing dates/hours in data sets
    df_list[[y]] <- left_join(complete_hours, df_list[[y]], by = "date_time")
    # Remove duplicate dates
    df_list[[y]] <- df_list[[y]][!duplicated(df_list[[y]]$date_time), ] %>%
      # Create daily averages for weather variables
      group_by(year, month, day) %>%
      summarise(Air_temperature = round(mean(air_temperature), digits = 2),
                Relative_humidity = round(mean(rltv_hum), digits = 2),
                Wind_speed = round(mean(wind_speed), digits = 2),
                Visibility = round(mean(visibility), digits = 2)
      ) %>%
      # Add date and site name columns
      mutate(Date = make_date(year = year, month = month, day = day),
             Site_name = selected_sites[y]) %>%
      ungroup() %>%
      # select desired columns
      select(Site_name,
             Date,
             Air_temperature,
             Relative_humidity,
             Wind_speed,
             Visibility
      )
  }
  # bring all data sets into one data frame
  table <- reduce(df_list, full_join,by = c("Site_name",
                                            "Date",
                                            "Air_temperature",
                                            "Relative_humidity",
                                            "Wind_speed",
                                            "Visibility"
  )
  )
  table
}

# Hutton function to plot calendar ----------------------------------------

f_hutton <- function(site, mth){
  # Remove 29th of Feb
  site_h <- site %>%
    filter(!(month == 2 & day == 29)) %>% 
    # Group by month and day and add cols with daily summaries for 
    # number of hours above 90% humidity, and min temp at least 10 degrees
    group_by(month, day) %>%
    summarise(temp_10 = min(air_temperature) >= 10,
              humid_90 = sum(rltv_hum >= 90)
    ) %>%
    # Add in cols for date (existing date col was giving me problems) and year
    mutate(Year = 2021,
           Date = make_date(Year, month, day)
    ) %>%
    ungroup()
  # Create a DF with complete dates for 1/1/21 to 30/11/21
  complete_dates <- tibble(Date = c(seq(as_date("2021/1/1"),
                                        as_date("2021/11/30"), 1))
                           )
  # Join dates DF and site DF to create rows for missing dates
  site_h <- full_join(complete_dates, site_h)
  # Add row indicating if Hutton criteria met
  site_h <- site_h %>%
    mutate(H_crit_met = (lag(temp_10)) == TRUE &
                   lag(temp_10,n=2) == TRUE &
                   lag(humid_90) >= 6 &
                   lag(humid_90, n = 2) >= 6,
                   )
  # Replace NA values in Hutton col with false, and select month
  site_h$H_crit_met <- replace_na(site_h$H_crit_met, FALSE)         
  hutton_mth <- site_h %>%
    filter(month == mth)
  # plot calendar of selected month, Hutton true = pink
  calendR(year = 2021,
          start = "M",
          month = mth,
          special.days = hutton_mth$H_crit_met,
          special.col = c("white", "pink"),
          weeknames = c("Mon", "Tue",  "Wed", "Thu", "Fri", "Sat", "Sun"),
          subtitle = "Days when Hutton criteria met indicated in red",
          subtitle.size = 12,
          )
}


# Function to create map image for report ---------------------------------

map_image_func <- function(sites_sel, time){
  markers <- sites %>%
    filter(Site_Name %in% sites_sel)
  map <- leaflet() %>%
            addProviderTiles(providers$CartoDB.PositronNoLabels,
                          options = providerTileOptions(opacity = 0.7)) %>%
            setView(lng = -3.43, lat = 55.37, zoom = 5) %>%
            addMarkers(lat = markers$Latitude,
                       lng = markers$Longitude,
                       label = markers$Site_Name,
                       labelOptions = labelOptions(noHide = T,
                                                   direction = "bottom"
                                                   )
            )
  mapshot(map, file = paste0(getwd(),"/map.png"))
}

