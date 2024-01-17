
# Building a Shiny Web App in R  
***Note: To run the app on a local machine the app.R, project_functions.R, and report.RMD files as well as the folder containing the RData files must be copied into working directory*** 

## Overview

This was a project I completed as part of an R programming module from an MSc in Data Analytics  

This aim of this project was to build a Shiny app which visualises and summarises hourly metorological data collected at 20 locations across the United Kingdom between 1st January to 30th November 2021. The data was obtained from the Met Office Integrated Data Archive System and provided to us in csv format.
  
The app was required to have the following functionality:
- Allow the user to select up to five locations which should then be displayed on a map
- Allow the user to select one of four weather variables
- Allow the user to select the aggregation level of the weather variable data to be displayed
- Allow the user to select the time period to display
- Produce time series plots for selected variables, locations, and aggregation level.
- Display a table of the daily means for all weather variables for selected sites
- Produce a downloadable report of plots, table, and map for selected sites and weather variable
- Produce a downloadable csv file of the table
- Calculate and display the Hutton Criteria (a diagnostic which is used to alert farmers of the risk of potato blight forming on potato crops) for a selected location and month

## Approach  
With a lot of infomation to display I decided to go with a two page layout using the flatly theme. The first page is used for displaying the meteorological data.  

![Image of Shiny web app page 1](https://github.com/MarkMData/images/blob/main/Shiny_app_pg1.PNG?raw=true)  

The the second page is used for displaying the Hutton Criteria.  

![Image of Shiny web app page 2](https://github.com/MarkMData/images/blob/main/Shiny_app_pg2.PNG?raw=true)  

To create the app I used a single app.R file for the UI and server code, and a seperate R file for all the functions used for generating the plots, maps, and table. I also created a Rmarkdown file for the downloadable report.  

## Data cleaning and wrangling using Tidyverse packages

The data sets for each location were provided to us as csv files and loading these into the app was slow, so I converted them all to RData files. I created functions for generating the plots, table, and Hutton Criteria calender and these incorporated the following actions:
- Loading the Rdata files for the selected locations (up to 5) and store them in a list of dataframes
- Removing observations for the 29th Febuary which did not exist in 2021
- Creating a date_time variable from year, month, day and hour data
- Joining the location dataframes with a dataframe containing the complete number of hours for the entire period. This was required as some locations were missing rows.
- Removing duplicate observations
- Performing aggregations on the selected variable if required
- Creating new variables to indicate times when temperature and humidity were below a threshold, and to indicate when the Hutton Criteria had been met
- Generate plots/table based on user selections

## Visualisations  
- I chose to display the location map in a tab on the first page, and as the background of the second page. To create the maps I used the Leaflet package, and choose a base map with neutral colours and no text, to ensure the selected locations would be clearly visable. Locations on the maps are indicated with markers, postioned using longitude and latitude values.
- The plots were created using the GGplot2 package.
- I used the CalendR package to create a simple clean monthly calender to display the days the Hutton Criteria was met.
