
# Building a Shiny Web App in R  
***Note: To run the app on a local machine the app.R, project_functions.R, and report.RMD files as well as the folder containing the RData files must be copied into working directory*** 

### Overview

This was a project I completed as part of an R programming module from an MSc in Data Analytics  

This aim of this project was to build a Shiny app which visualises and summarises hourly metorological data collected at 20 locations across the United Kingdom between 1st January to 30th November 2021. The data was obtained from the Met Office Integrated Data Archive System and provided to us in csv format.
  
The app was required to have the following functionality:
- Allow the user to select up to five locations which should then be displayed on a map
- Allow the user to select one of four weather variables
- Allow the user to select the aggregation level of the weather variable data to be displayed
- Allow the user to select the time period to display
- Produce a variety of time series plots for the summary statistics of weather variable for selected sites
- Display a table of the daily means for all weather variables for selected sites
- Produce a downloadable report of plots, table, and map for selected sites and weather variable
- Produce a downloadable csv file of the table
- Calculate and display the Hutton Criteria (a diagnostic which is used to alert farmers of the risk of potato blight forming on potato crops) for a selected location and month
### Approach  
With quite a lot of infomation needing to be displayed I decided to go with a two page layout using the flatly theme. The first page is used for displaying the meteorological data.  

![Image of Shiny web app page 1](https://github.com/MarkMData/images/blob/main/Shiny_app_pg1.PNG?raw=true)  

The the second page is used for displaying the Hutton Criteria.  

![Image of Shiny web app page 2](https://github.com/MarkMData/images/blob/main/Shiny_app_pg2.PNG?raw=true)  

To create the app I used a single app.R file for the UI and server code, and a seperate R file for all the functions used for generating the plots, maps, and table. I also created a Rmarkdown file for the downloadable report.  

### Functions for generating plots and table  

The data sets for each location were provided to us as csv files and loading these into the app was slow, so I converted them all to RData files. I created functions for generating the plots and table which would take as inputs the user selected options and then do the following:
- Load the Rdata files for the selected locations (up to 5) and store them in a list of dataframes
- Clean and wrangle the data for each location using Tidyverse packages:
  - Remove observations for the 29th Febuary which did not exist for that year
  - Create a date_time variable from year, month, day and hour data
  - Join the location dataframes with a dataframe containing the complete number of hours for the entire period. This was required as some locations were missing rows.
  - Remove duplicate observations
  - Perform aggregations on the selected variable if required.
- Generate plots/table based on user selections

### Function for displaying Hutton Criteria  

The function for diplaying the Hutton criteria takes a location and month as inputs and then does the following:
- Loads the selected location file
- Cleans and wrangles the data as per the plot function but also:
  - Create new variables to indicate times when temperature and humidity were below a threshold
  - Create a new variable indicating if Hutton Criteria was met.
- Generate a calender view of the selected month displaying the days the Hutton Criteria was met using teh CalendR package

I used the Leaflet package to create the base maps with markers for the selected locations. To show the days the Hutton criteria was met I created a function that takes as input the selected location and month and then loads, cleans & wrangles the data before generating a calender displaying the days the criteria was met.
